import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class InternetResult {
  final String title;
  final String text;
  final String url;

  const InternetResult({
    required this.title,
    required this.text,
    required this.url,
  });
}

class InternetService {
  Future<List<InternetResult>> search(
    String query,
  ) async {
    final text = query.trim();

    if (text.isEmpty) {
      return [];
    }

    final uri = Uri.https(
      'api.duckduckgo.com',
      '/',
      {
        'q': text,
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
        return [];
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return [];
      }

      final results = <InternetResult>[];

      final abstractText =
          (decoded['AbstractText'] ?? '')
              .toString();

      if (abstractText.isNotEmpty) {
        results.add(
          InternetResult(
            title:
                (decoded['Heading'] ?? text)
                    .toString(),
            text: abstractText,
            url:
                (decoded['AbstractURL'] ?? '')
                    .toString(),
          ),
        );
      }

      final related =
          decoded['RelatedTopics'];

      if (related is List) {
        for (final item in related) {
          if (item is! Map) {
            continue;
          }

          final itemText =
              item['Text']?.toString();

          if (itemText == null ||
              itemText.isEmpty) {
            continue;
          }

          results.add(
            InternetResult(
              title: itemText,
              text: itemText,
              url:
                  item['FirstURL']
                          ?.toString() ??
                      '',
            ),
          );

          if (results.length >= 8) {
            break;
          }
        }
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  Future<void> openWebSearch(
    String query,
  ) async {
    final uri = Uri.https(
      'www.google.com',
      '/search',
      {'q': query},
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }
}
