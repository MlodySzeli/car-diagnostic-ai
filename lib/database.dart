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

    final path = join(
      databasesPath,
      'car_diagnostic_ai.db',
    );

    return databaseFactory.openDatabase(
      path,
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
              name TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE generations (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              model_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              year_from INTEGER,
              year_to INTEGER
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
              power INTEGER
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
      orderBy: 'name ASC',
    );

    return result.map(CarBrand.fromMap).toList();
  }

  Future<int> addModel(CarModel model) async {
    final db = await database;

    return db.insert(
      'models',
      model.toMap(),
    );
  }

  Future<List<CarModel>> getModels(int brandId) async {
    final db = await database;

    final result = await db.query(
      'models',
      where: 'brand_id = ?',
      whereArgs: [brandId],
      orderBy: 'name ASC',
    );

    return result.map(CarModel.fromMap).toList();
  }

  Future<int> addGeneration(Generation generation) async {
    final db = await database;

    return db.insert(
      'generations',
      generation.toMap(),
    );
  }

  Future<List<Generation>> getGenerations(int modelId) async {
    final db = await database;

    final result = await db.query(
      'generations',
      where: 'model_id = ?',
      whereArgs: [modelId],
      orderBy: 'name ASC',
    );

    return result.map(Generation.fromMap).toList();
  }

  Future<int> addEngine(Engine engine) async {
    final db = await database;

    return db.insert(
      'engines',
      engine.toMap(),
    );
  }

  Future<List<Engine>> getEngines(int generationId) async {
    final db = await database;

    final result = await db.query(
      'engines',
      where: 'generation_id = ?',
      whereArgs: [generationId],
      orderBy: 'name ASC',
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
      orderBy: 'code ASC',
    );

    return result.map(DtcCode.fromMap).toList();
  }
}
