import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'models.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    sqfliteFfiInit();

    final databasePath =
        await databaseFactoryFfi.getDatabasesPath();

    final path = join(
      databasePath,
      'car_diagnostic_ai_v5.db',
    );

    return databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
CREATE TABLE brands(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
)
''');

          await db.execute('''
CREATE TABLE models(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  brand_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  UNIQUE(brand_id, name)
)
''');

          await db.execute('''
CREATE TABLE generations(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  model_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  year_from INTEGER,
  year_to INTEGER
)
''');

          await db.execute('''
CREATE TABLE engines(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  generation_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  code TEXT,
  fuel TEXT,
  displacement INTEGER,
  power INTEGER
)
''');

          await db.execute('''
CREATE TABLE categories(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
)
''');

          await db.execute('''
CREATE TABLE subcategories(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  UNIQUE(category_id, name)
)
''');

          await db.execute('''
CREATE TABLE dtc_codes(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  causes TEXT,
  checks TEXT,
  description_pl TEXT,
  description_en TEXT,
  source TEXT
)
''');
        },
      ),
    );
  }

  Future<DtcCode?> getDtcByCode(String code) async {
    final db = await database;

    final rows = await db.query(
      'dtc_codes',
      where: 'UPPER(code) = ?',
      whereArgs: [code.trim().toUpperCase()],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return DtcCode.fromMap(
      Map<String, dynamic>.from(rows.first),
    );
  }

  Future<List<VehicleSearchResult>> searchVehicles(
    String query,
  ) async {
    final text = query.trim();

    if (text.isEmpty) {
      return [];
    }

    final db = await database;

    final like = '%$text%';

    final rows = await db.rawQuery(
      '''
SELECT
  engines.id AS engine_id,
  brands.name AS brand,
  models.name AS model,
  generations.name AS generation,
  engines.name AS engine,
  engines.code AS engine_code,
  engines.fuel AS fuel,
  engines.power AS power
FROM engines
JOIN generations
  ON generations.id = engines.generation_id
JOIN models
  ON models.id = generations.model_id
JOIN brands
  ON brands.id = models.brand_id
WHERE
  brands.name LIKE ?
  OR models.name LIKE ?
  OR generations.name LIKE ?
  OR engines.name LIKE ?
  OR engines.code LIKE ?
  OR engines.fuel LIKE ?
ORDER BY
  brands.name,
  models.name,
  generations.name,
  engines.name
LIMIT 100
''',
      [
        like,
        like,
        like,
        like,
        like,
        like,
      ],
    );

    return rows
        .map(
          (row) => VehicleSearchResult.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  Future<void> upsertDtc(
    DtcCode dtc,
    String source,
  ) async {
    final db = await database;

    await db.insert(
      'dtc_codes',
      {
        'code': dtc.code.toUpperCase(),
        'description': dtc.description,
        'causes': dtc.causes,
        'checks': dtc.checks,
        'description_pl': dtc.descriptionPl,
        'description_en': dtc.descriptionEn,
        'source': source,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> seedDatabase() async {
    final db = await database;

    final brandCountResult = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM brands',
    );

    final brandCount =
        brandCountResult.first['count'] as int? ?? 0;

    if (brandCount == 0) {
      await _seedVehicles(db);
    }

    final dtcCountResult = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM dtc_codes',
    );

    final dtcCount =
        dtcCountResult.first['count'] as int? ?? 0;

    if (dtcCount == 0) {
      await _seedDtc(db);
    }
  }

  Future<void> _seedVehicles(Database db) async {
    try {
      final jsonText = await rootBundle.loadString(
        'assets/data/vehicles.json',
      );

      final decoded = jsonDecode(jsonText);

      if (decoded is! Map) {
        return;
      }

      final vehicles = decoded['vehicles'];

      if (vehicles is! List) {
        return;
      }

      for (final vehicle in vehicles) {
        if (vehicle is! Map) {
          continue;
        }

        final make = vehicle['make']?.toString();
        final modelName = vehicle['model']?.toString();
        final generationName =
            vehicle['generation']?.toString();

        if (make == null ||
            modelName == null ||
            generationName == null) {
          continue;
        }

        await db.insert(
          'brands',
          {'name': make},
          conflictAlgorithm:
              ConflictAlgorithm.ignore,
        );

        final brandRows = await db.query(
          'brands',
          columns: ['id'],
          where: 'name = ?',
          whereArgs: [make],
        );

        if (brandRows.isEmpty) {
          continue;
        }

        final brandId =
            brandRows.first['id'] as int;

        await db.insert(
          'models',
          {
            'brand_id': brandId,
            'name': modelName,
          },
          conflictAlgorithm:
              ConflictAlgorithm.ignore,
        );

        final modelRows = await db.query(
          'models',
          columns: ['id'],
          where:
              'brand_id = ? AND name = ?',
          whereArgs: [
            brandId,
            modelName,
          ],
        );

        if (modelRows.isEmpty) {
          continue;
        }

        final modelId =
            modelRows.first['id'] as int;

        await db.insert(
          'generations',
          {
            'model_id': modelId,
            'name': generationName,
          },
          conflictAlgorithm:
              ConflictAlgorithm.ignore,
        );

        final generationRows = await db.query(
          'generations',
          columns: ['id'],
          where:
              'model_id = ? AND name = ?',
          whereArgs: [
            modelId,
            generationName,
          ],
        );

        if (generationRows.isEmpty) {
          continue;
        }

        final generationId =
            generationRows.first['id'] as int;

        final engines = vehicle['engines'];

        if (engines is! List) {
          continue;
        }

        for (final engine in engines) {
          if (engine is! Map) {
            continue;
          }

          final engineName =
              engine['name']?.toString() ?? '';

          if (engineName.isEmpty) {
            continue;
          }

          await db.insert(
            'engines',
            {
              'generation_id': generationId,
              'name': engineName,
              'code':
                  engine['code']?.toString(),
              'fuel':
                  engine['fuel']?.toString(),
              'power':
                  engine['power_hp'],
            },
            conflictAlgorithm:
                ConflictAlgorithm.ignore,
          );
        }
      }
    } catch (_) {
      // Brak danych startowych nie zatrzymuje aplikacji.
    }
  }

  Future<void> _seedDtc(Database db) async {
    try {
      final jsonText = await rootBundle.loadString(
        'assets/data/diagnostic_data.json',
      );

      final decoded = jsonDecode(jsonText);

      if (decoded is! Map) {
        return;
      }

      final dtcItems = decoded['dtc'];

      if (dtcItems is! List) {
        return;
      }

      for (final item in dtcItems) {
        if (item is! Map) {
          continue;
        }

        final code =
            item['code']?.toString();

        if (code == null || code.isEmpty) {
          continue;
        }

        final causes = item['causes'];
        final checks = item['checks'];

        await db.insert(
          'dtc_codes',
          {
            'code': code.toUpperCase(),
            'description':
                item['name']?.toString() ?? '',
            'causes': causes is List
                ? causes.join('\n')
                : causes?.toString(),
            'checks': checks is List
                ? checks.join('\n')
                : checks?.toString(),
            'source': 'local',
          },
          conflictAlgorithm:
              ConflictAlgorithm.ignore,
        );
      }
    } catch (_) {
      // Brak danych startowych nie zatrzymuje aplikacji.
    }
  }
}
