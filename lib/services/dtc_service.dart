import 'dart:convert';

import 'package:http/http.dart' as http;

import '../database.dart';
import '../models.dart';

class DtcSearchService {
  DtcSearchService(this.database);

  final AppDatabase database;

  final RegExp _dtcPattern = RegExp(
    r'^[PCBU][0-9A-F]{4}$',
    caseSensitive: false,
  );

  Future<DtcCode?> findOrSearch(
    String input, {
    String? vehicleContext,
  }) async {
    final code = input
        .trim()
        .toUpperCase();

    if (!_dtcPattern.hasMatch(code)) {
      return null;
    }

    // 1. Najpierw lokalna baza.
    final local =
        await database.getDtcByCode(code);

    if (local != null) {
      return local;
    }

    // 2. Brak lokalnie -> automatyczne
    // wyszukiwanie internetowe.
    final context =
        vehicleContext?.trim() ?? '';

    final query = context.isEmpty
        ? '$code DTC diagnostic trouble code'
        : '$code DTC $context diagnostic trouble code';

    final uri = Uri.https(
      'api.duckduckgo.com',
      '/',
      {
        'q': query,
        'format': 'json',
        'no_html': '1',
        'skip_disambig': '1',
      },
    );

    try {
      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        return null;
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      String description =
          (decoded['AbstractText'] ?? '')
              .toString()
              .trim();

      String source =
          (decoded['AbstractURL'] ?? '')
              .toString()
              .trim();

      // Jeżeli główny wynik jest pusty,
      // sprawdzamy wyniki powiązane.
      if (description.isEmpty) {
        final related =
            decoded['RelatedTopics'];

        if (related is List) {
          for (final item in related) {
            if (item is! Map) {
              continue;
            }

            final text =
                item['Text']?.toString() ?? '';

            if (text
                .toUpperCase()
                .contains(code)) {
              description = text.trim();

              source =
                  item['FirstURL']
                          ?.toString() ??
                      '';

              break;
            }
          }
        }
      }

      if (description.isEmpty) {
        return null;
      }

      final result = DtcCode(
        code: code,
        description: description,
        descriptionPl: description,
        descriptionEn: description,
        causes:
            'Informacje zostały znalezione automatycznie. '
            'Zweryfikuj przyczynę przed rozpoczęciem naprawy.',
        checks:
            'Sprawdź dokumentację producenta, dane bieżące, '
            'instalację elektryczną oraz elementy związane z kodem.',
      );

      // 3. Automatycznie zapisujemy
      // znaleziony kod lokalnie.
      await database.upsertDtc(
        result,
        source.isEmpty
            ? 'internet'
            : source,
      );

      return result;
    } catch (_) {
      return null;
    }
  }
}
