import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'models.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();

  AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  Future<Database> _initDatabase() async {
    sqfliteFfiInit();

    final databaseFactory = databaseFactoryFfi;

    final databasesPath =
        await databaseFactory.getDatabasesPath();

    final dbPath = join(
      databasesPath,
      'car_diagnostic_ai.db',
    );

    return databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE brands (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE
            )
          ''');

          await db.execute('''
            CREATE TABLE models (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              brand_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              UNIQUE(brand_id, name)
            )
          ''');

          await db.execute('''
            CREATE TABLE generations (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              model_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              year_from INTEGER,
              year_to INTEGER,
              UNIQUE(model_id, name)
            )
          ''');

          await db.execute('''
            CREATE TABLE engines (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              generation_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              code TEXT NOT NULL,
              fuel TEXT NOT NULL,
              displacement INTEGER,
              power INTEGER,
              UNIQUE(generation_id, name, code)
            )
          ''');

          await db.execute('''
            CREATE TABLE dtc_codes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              code TEXT NOT NULL UNIQUE,
              description TEXT NOT NULL,
              causes TEXT NOT NULL,
              checks TEXT NOT NULL
            )
          ''');
        },
      ),
    );
  }

  // =========================
  // BRANDS
  // =========================

  Future<int> addBrand(CarBrand brand) async {
    final db = await database;

    return db.insert(
      'brands',
      {
        'name': brand.name,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<CarBrand>> getBrands() async {
    final db = await database;

    final result = await db.query(
      'brands',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return result.map(CarBrand.fromMap).toList();
  }

  Future<int?> findBrandId(String name) async {
    final db = await database;

    final result = await db.query(
      'brands',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first['id'] as int;
  }

  // =========================
  // MODELS
  // =========================

  Future<int> addModel(CarModel model) async {
    final db = await database;

    return db.insert(
      'models',
      {
        'brand_id': model.brandId,
        'name': model.name,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<CarModel>> getModels(int brandId) async {
    final db = await database;

    final result = await db.query(
      'models',
      where: 'brand_id = ?',
      whereArgs: [brandId],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return result.map(CarModel.fromMap).toList();
  }

  // =========================
  // GENERATIONS
  // =========================

  Future<int> addGeneration(
    Generation generation,
  ) async {
    final db = await database;

    return db.insert(
      'generations',
      {
        'model_id': generation.modelId,
        'name': generation.name,
        'year_from': generation.yearFrom,
        'year_to': generation.yearTo,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Generation>> getGenerations(
    int modelId,
  ) async {
    final db = await database;

    final result = await db.query(
      'generations',
      where: 'model_id = ?',
      whereArgs: [modelId],
      orderBy: 'year_from ASC, name ASC',
    );

    return result.map(Generation.fromMap).toList();
  }

  // =========================
  // ENGINES
  // =========================

  Future<int> addEngine(Engine engine) async {
    final db = await database;

    return db.insert(
      'engines',
      {
        'generation_id': engine.generationId,
        'name': engine.name,
        'code': engine.code,
        'fuel': engine.fuel,
        'displacement': engine.displacement,
        'power': engine.power,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Engine>> getEngines(
    int generationId,
  ) async {
    final db = await database;

    final result = await db.query(
      'engines',
      where: 'generation_id = ?',
      whereArgs: [generationId],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return result.map(Engine.fromMap).toList();
  }

  // =========================
  // DTC
  // =========================

  Future<int> addDtc(DtcCode dtc) async {
    final db = await database;

    return db.insert(
      'dtc_codes',
      {
        'code': dtc.code,
        'description': dtc.description,
        'causes': dtc.causes,
        'checks': dtc.checks,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DtcCode>> getDtcCodes() async {
    final db = await database;

    final result = await db.query(
      'dtc_codes',
      orderBy: 'code COLLATE NOCASE ASC',
    );

    return result.map(DtcCode.fromMap).toList();
  }

  // =========================
  // DATABASE SEED
  // =========================

  Future<void> seedDatabase() async {
    final db = await database;

    final vehiclesRaw =
        await rootBundle.loadString(
      'assets/data/vehicles.json',
    );

    final diagnosticRaw =
        await rootBundle.loadString(
      'assets/data/diagnostic_data.json',
    );

    final vehiclesJson =
        jsonDecode(vehiclesRaw) as Map<String, dynamic>;

    final diagnosticJson =
        jsonDecode(diagnosticRaw) as Map<String, dynamic>;

    final vehicles = vehiclesJson['vehicles'];

    final dtcs = diagnosticJson['dtc'];

    if (vehicles is! List || dtcs is! List) {
      throw const FormatException(
        'Nieprawidłowa struktura plików JSON.',
      );
    }

    await db.transaction((txn) async {
      // =========================
      // BRANDS
      // =========================

      final brands = <String>[
        'Abarth',
        'Alfa Romeo',
        'Alpine',
        'Aston Martin',
        'Audi',
        'Bentley',
        'BMW',
        'Bugatti',
        'Citroën',
        'Cupra',
        'Dacia',
        'DS Automobiles',
        'Ferrari',
        'Fiat',
        'Ford',
        'Honda',
        'Hyundai',
        'Infiniti',
        'Isuzu',
        'Iveco',
        'Jaguar',
        'Jeep',
        'Kia',
        'Lamborghini',
        'Land Rover',
        'Lexus',
        'Lotus',
        'Maserati',
        'Mazda',
        'McLaren',
        'Mercedes-Benz',
        'MINI',
        'Mitsubishi',
        'Nissan',
        'Opel',
        'Peugeot',
        'Porsche',
        'Renault',
        'Rolls-Royce',
        'Saab',
        'Seat',
        'Škoda',
        'Smart',
        'Subaru',
        'Suzuki',
        'Tesla',
        'Toyota',
        'Volkswagen',
        'Volvo',
      ];

      for (final brandName in brands) {
        await txn.insert(
          'brands',
          {
            'name': brandName,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      // =========================
      // VEHICLES
      // =========================

      for (final vehicle in vehicles) {
        if (vehicle is! Map<String, dynamic>) {
          continue;
        }

        final make = vehicle['make']?.toString();
        final model = vehicle['model']?.toString();
        final generation =
            vehicle['generation']?.toString();
        final years = vehicle['years']?.toString();

        if (make == null ||
            model == null ||
            generation == null) {
          continue;
        }

        await txn.insert(
          'brands',
          {
            'name': make,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        final brandResult = await txn.query(
          'brands',
          columns: ['id'],
          where: 'name = ?',
          whereArgs: [make],
          limit: 1,
        );

        if (brandResult.isEmpty) {
          continue;
        }

        final brandId =
            brandResult.first['id'] as int;

        await txn.insert(
          'models',
          {
            'brand_id': brandId,
            'name': model,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        final modelResult = await txn.query(
          'models',
          columns: ['id'],
          where: 'brand_id = ? AND name = ?',
          whereArgs: [
            brandId,
            model,
          ],
          limit: 1,
        );

        if (modelResult.isEmpty) {
          continue;
        }

        final modelId =
            modelResult.first['id'] as int;

        int? yearFrom;
        int? yearTo;

        if (years != null) {
          final match = RegExp(
            r'(\d{4})\s*-\s*(\d{4})',
          ).firstMatch(years);

          if (match != null) {
            yearFrom =
                int.tryParse(match.group(1)!);

            yearTo =
                int.tryParse(match.group(2)!);
          }
        }

        await txn.insert(
          'generations',
          {
            'model_id': modelId,
            'name': generation,
            'year_from': yearFrom,
            'year_to': yearTo,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        final generationResult = await txn.query(
          'generations',
          columns: ['id'],
          where: 'model_id = ? AND name = ?',
          whereArgs: [
            modelId,
            generation,
          ],
          limit: 1,
        );

        if (generationResult.isEmpty) {
          continue;
        }

        final generationId =
            generationResult.first['id'] as int;

        final engines = vehicle['engines'];

        if (engines is! List) {
          continue;
        }

        for (final engine in engines) {
          if (engine is! Map<String, dynamic>) {
            continue;
          }

          final name = engine['name']?.toString();
          final code = engine['code']?.toString();
          final fuel = engine['fuel']?.toString();

          if (name == null ||
              code == null ||
              fuel == null) {
            continue;
          }

          await txn.insert(
            'engines',
            {
              'generation_id': generationId,
              'name': name,
              'code': code,
              'fuel': fuel,
              'displacement':
                  engine['displacement'],
              'power':
                  engine['power_hp'],
            },
            conflictAlgorithm:
                ConflictAlgorithm.ignore,
          );
        }
      }

      // =========================
      // DTC
      // =========================

      for (final dtc in dtcs) {
        if (dtc is! Map<String, dynamic>) {
          continue;
        }

        final code = dtc['code']?.toString();
        final description =
            dtc['name']?.toString();

        if (code == null ||
            description == null) {
          continue;
        }

        final causes = dtc['causes'];

        final checks = dtc['checks'];

        final causesText = causes is List
            ? causes
                .map((e) => e.toString())
                .join('\n')
            : causes?.toString() ?? 'Brak danych';

        final checksText = checks is List
            ? checks
                .map((e) => e.toString())
                .join('\n')
            : checks?.toString() ?? 'Brak danych';

        await txn.insert(
          'dtc_codes',
          {
            'code': code,
            'description': description,
            'causes': causesText,
            'checks': checksText,
          },
          conflictAlgorithm:
              ConflictAlgorithm.ignore,
        );
      }
    });
  }
}
