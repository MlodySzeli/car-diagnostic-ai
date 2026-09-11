import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'models.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    sqfliteFfiInit();
    final path = join(
      await databaseFactoryFfi.getDatabasesPath(),
      'car_diagnostic_ai_v4.db',
    );

    return databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE brands(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)',
          );
          await db.execute(
            'CREATE TABLE models(id INTEGER PRIMARY KEY AUTOINCREMENT, brand_id INTEGER NOT NULL, name TEXT NOT NULL, UNIQUE(brand_id, name))',
          );
          await db.execute(
            'CREATE TABLE generations(id INTEGER PRIMARY KEY AUTOINCREMENT, model_id INTEGER NOT NULL, name TEXT NOT NULL, year_from INTEGER, year_to INTEGER, UNIQUE(model_id, name))',
          );
          await db.execute(
            'CREATE TABLE engines(id INTEGER PRIMARY KEY AUTOINCREMENT, generation_id INTEGER NOT NULL, name TEXT NOT NULL, code TEXT, fuel TEXT, displacement INTEGER, power INTEGER)',
          );
          await db.execute(
            'CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)',
          );
          await db.execute(
            'CREATE TABLE subcategories(id INTEGER PRIMARY KEY AUTOINCREMENT, category_id INTEGER NOT NULL, name TEXT NOT NULL, UNIQUE(category_id, name))',
          );
          await db.execute(
            'CREATE TABLE dtc_codes(id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL UNIQUE, description TEXT NOT NULL, causes TEXT, checks TEXT, description_pl TEXT, description_en TEXT, category_id INTEGER, subcategory_id INTEGER)',
          );
        },
      ),
    );
  }

  Future<List<T>> _list<T>(
    String table,
    T Function(Map<String, dynamic>) fromMap, {
    String? where,
    List<Object?>? args,
    String? order,
  }) async {
    final db = await database;
    final rows = await db.query(
      table,
      where: where,
      whereArgs: args,
      orderBy: order,
    );
    return rows
        .map((row) => fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<CarBrand>> getBrands() =>
      _list('brands', CarBrand.fromMap, order: 'name COLLATE NOCASE');

  Future<List<CarModel>> getModels(int brandId) => _list(
        'models',
        CarModel.fromMap,
        where: 'brand_id = ?',
        args: [brandId],
        order: 'name COLLATE NOCASE',
      );

  Future<List<Generation>> getGenerations(int modelId) => _list(
        'generations',
        Generation.fromMap,
        where: 'model_id = ?',
        args: [modelId],
        order: 'year_from, name',
      );

  Future<List<Engine>> getEngines(int generationId) => _list(
        'engines',
        Engine.fromMap,
        where: 'generation_id = ?',
        args: [generationId],
        order: 'name COLLATE NOCASE',
      );

  Future<List<Category>> getCategories() =>
      _list('categories', Category.fromMap, order: 'name COLLATE NOCASE');

  Future<List<Subcategory>> getSubcategories(int categoryId) => _list(
        'subcategories',
        Subcategory.fromMap,
        where: 'category_id = ?',
        args: [categoryId],
        order: 'name COLLATE NOCASE',
      );

  Future<List<DtcCode>> getDtcCodes({String query = ''}) {
    final q = query.trim();
    return _list(
      'dtc_codes',
      DtcCode.fromMap,
      where: q.isEmpty
          ? null
          : 'code LIKE ? OR description LIKE ? OR description_pl LIKE ? OR description_en LIKE ?',
      args: q.isEmpty ? null : ['%$q%', '%$q%', '%$q%', '%$q%'],
      order: 'code COLLATE NOCASE',
    );
  }

  Future<void> insert(String table, Map<String, Object?> values) async {
    final db = await database;
    await db.insert(
      table,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(
    String table,
    int id,
    Map<String, Object?> values,
  ) async {
    final db = await database;
    await db.update(table, values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> remove(String table, int id) async {
    final db = await database;

    await db.transaction((tx) async {
      if (table == 'brands') {
        final models = await tx.query(
          'models',
          columns: ['id'],
          where: 'brand_id = ?',
          whereArgs: [id],
        );
        for (final model in models) {
          await _deleteModel(tx, model['id'] as int);
        }
      } else if (table == 'models') {
        await _deleteModel(tx, id);
        return;
      } else if (table == 'generations') {
        await _deleteGeneration(tx, id);
        return;
      } else if (table == 'categories') {
        await tx.delete(
          'subcategories',
          where: 'category_id = ?',
          whereArgs: [id],
        );
        await tx.update(
          'dtc_codes',
          {'category_id': null, 'subcategory_id': null},
          where: 'category_id = ?',
          whereArgs: [id],
        );
      } else if (table == 'subcategories') {
        await tx.update(
          'dtc_codes',
          {'subcategory_id': null},
          where: 'subcategory_id = ?',
          whereArgs: [id],
        );
      }

      await tx.delete(table, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> _deleteModel(Transaction tx, int id) async {
    final generations = await tx.query(
      'generations',
      columns: ['id'],
      where: 'model_id = ?',
      whereArgs: [id],
    );

    for (final generation in generations) {
      await _deleteGeneration(tx, generation['id'] as int);
    }

    await tx.delete('models', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _deleteGeneration(Transaction tx, int id) async {
    await tx.delete(
      'engines',
      where: 'generation_id = ?',
      whereArgs: [id],
    );
    await tx.delete('generations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> seedDatabase() async {
    final db = await database;
    final countRows = await db.rawQuery('SELECT COUNT(*) AS count FROM brands');
    final count = (countRows.first['count'] as int?) ?? 0;
    if (count > 0) return;

    try {
      final vehiclesJson = jsonDecode(
        await rootBundle.loadString('assets/data/vehicles.json'),
      );
      final vehicles = vehiclesJson is Map ? vehiclesJson['vehicles'] : null;

      if (vehicles is List) {
        for (final raw in vehicles) {
          if (raw is! Map) continue;

          final make = raw['make']?.toString();
          final modelName = raw['model']?.toString();
          final generationName = raw['generation']?.toString();

          if (make == null || modelName == null || generationName == null) {
            continue;
          }

          await db.insert(
            'brands',
            {'name': make},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          final brandRow = (await db.query(
            'brands',
            columns: ['id'],
            where: 'name = ?',
            whereArgs: [make],
          )).first;

          final brandId = brandRow['id'] as int;

          await db.insert(
            'models',
            {'brand_id': brandId, 'name': modelName},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          final modelRow = (await db.query(
            'models',
            columns: ['id'],
            where: 'brand_id = ? AND name = ?',
            whereArgs: [brandId, modelName],
          )).first;

          final modelId = modelRow['id'] as int;

          await db.insert(
            'generations',
            {'model_id': modelId, 'name': generationName},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          final generationRow = (await db.query(
            'generations',
            columns: ['id'],
            where: 'model_id = ? AND name = ?',
            whereArgs: [modelId, generationName],
          )).first;

          final generationId = generationRow['id'] as int;
          final engines = raw['engines'];

          if (engines is List) {
            for (final engine in engines) {
              if (engine is! Map) continue;
              final name = engine['name']?.toString() ?? '';
              if (name.isEmpty) continue;

              await db.insert(
                'engines',
                {
                  'generation_id': generationId,
                  'name': name,
                  'code': engine['code']?.toString(),
                  'fuel': engine['fuel']?.toString(),
                  'power': engine['power_hp'],
                },
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }
          }
        }
      }
    } catch (_) {}

    try {
      final diagnosticJson = jsonDecode(
        await rootBundle.loadString('assets/data/diagnostic_data.json'),
      );
      final dtcs = diagnosticJson is Map ? diagnosticJson['dtc'] : null;

      if (dtcs is List) {
        for (final raw in dtcs) {
          if (raw is! Map) continue;

          final code = raw['code']?.toString();
          if (code == null || code.isEmpty) continue;

          final causes = raw['causes'];
          final checks = raw['checks'];

          await db.insert(
            'dtc_codes',
            {
              'code': code,
              'description': raw['name']?.toString() ?? '',
              'causes': causes is List
                  ? causes.map((e) => e.toString()).join('\n')
                  : causes?.toString(),
              'checks': checks is List
                  ? checks.map((e) => e.toString()).join('\n')
                  : checks?.toString(),
            },
          );
        }
      }
    } catch (_) {}
  }
}
