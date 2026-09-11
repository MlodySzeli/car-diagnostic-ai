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

    final databasesPath = await databaseFactory.getDatabasesPath();

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

  Future<int> addBrand(CarBrand brand) async {
    final db = await database;

    return db.insert(
      'brands',
      brand.toMap(),
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

    if (result.isEmpty) return null;

    return result.first['id'] as int;
  }

  Future<int> addModel(CarModel model) async {
    final db = await database;

    return db.insert(
      'models',
      model.toMap(),
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

  Future<int> addGeneration(Generation generation) async {
    final db = await database;

    return db.insert(
      'generations',
      generation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Generation>> getGenerations(int modelId) async {
    final db = await database;

    final result = await db.query(
      'generations',
      where: 'model_id = ?',
      whereArgs: [modelId],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return result.map(Generation.fromMap).toList();
  }

  Future<int> addEngine(Engine engine) async {
    final db = await database;

    return db.insert(
      'engines',
      engine.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Engine>> getEngines(int generationId) async {
    final db = await database;

    final result = await db.query(
      'engines',
      where: 'generation_id = ?',
      whereArgs: [generationId],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return result.map(Engine.fromMap).toList();
  }

  Future<int> addDtc(DtcCode dtc) async {
    final db = await database;

    return db.insert(
      'dtc_codes',
      dtc.toMap(),
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

  Future<void> seedDatabase() async {
    final db = await database;

    final vehiclesRaw =
        await rootBundle.loadString('assets/data/vehicles.json');

    final diagnosticRaw =
        await rootBundle.loadString('assets/data/diagnostic_data.json');

    final vehiclesJson = jsonDecode(vehiclesRaw);
    final diagnosticJson = jsonDecode(diagnosticRaw);

    await db.transaction((txn) async {
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
          {'name': brandName},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      for (final vehicle in vehiclesJson['vehicles']) {
        final make = vehicle['make'];
        final model = vehicle['model'];
        final generation = vehicle['generation'];
        final years = vehicle['years'];

        final brandResult = await txn.query(
          'brands',
          columns: ['id'],
          where: 'name = ?',
          whereArgs: [make],
          limit: 1,
        );

        if (brandResult.isEmpty) continue;

        final brandId = brandResult.first['id'] as int;

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
          whereArgs: [brandId, model],
          limit: 1,
        );

        if (modelResult.isEmpty) continue;

        final modelId = modelResult.first['id'] as int;

        int? yearFrom;
        int? yearTo;

        final match = RegExp(r'(\d{4})-(\d{4})').firstMatch(years);

        if (match != null) {
          yearFrom = int.tryParse(match.group(1)!);
          yearTo = int.tryParse(match.group(2)!);
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
          whereArgs: [modelId, generation],
          limit: 1,
        );

        if (generationResult.isEmpty) continue;

        final generationId =
            generationResult.first['id'] as int;

        for (final engine in vehicle['engines']) {
          await txn.insert(
            'engines',
            {
              'generation_id': generationId,
              'name': engine['name'],
              'code': engine['code'],
              'fuel': engine['fuel'],
              'displacement': engine['displacement'],
              'power': engine['power_hp'],
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }

      for (final dtc in diagnosticJson['dtc']) {
        await txn.insert(
          'dtc_codes',
          {
            'code': dtc['code'],
            'description': dtc['name'],
            'causes': (dtc['causes'] as List).join('\n'),
            'checks': (dtc['checks'] as List).join('\n'),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }
}
