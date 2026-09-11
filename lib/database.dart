import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'models.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();
  Database? _db;
  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    sqfliteFfiInit();
    final path = join(await databaseFactoryFfi.getDatabasesPath(), 'car_diagnostic_ai_v4.db');
    return databaseFactoryFfi.openDatabase(path, options: OpenDatabaseOptions(version: 4, onCreate: (db, _) async {
      await db.execute('CREATE TABLE brands(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL UNIQUE)');
      await db.execute('CREATE TABLE models(id INTEGER PRIMARY KEY AUTOINCREMENT,brand_id INTEGER NOT NULL,name TEXT NOT NULL,UNIQUE(brand_id,name))');
      await db.execute('CREATE TABLE generations(id INTEGER PRIMARY KEY AUTOINCREMENT,model_id INTEGER NOT NULL,name TEXT NOT NULL,year_from INTEGER,year_to INTEGER,UNIQUE(model_id,name))');
      await db.execute('CREATE TABLE engines(id INTEGER PRIMARY KEY AUTOINCREMENT,generation_id INTEGER NOT NULL,name TEXT NOT NULL,code TEXT,fuel TEXT,displacement INTEGER,power INTEGER)');
      await db.execute('CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL UNIQUE)');
      await db.execute('CREATE TABLE subcategories(id INTEGER PRIMARY KEY AUTOINCREMENT,category_id INTEGER NOT NULL,name TEXT NOT NULL,UNIQUE(category_id,name))');
      await db.execute('CREATE TABLE dtc_codes(id INTEGER PRIMARY KEY AUTOINCREMENT,code TEXT NOT NULL UNIQUE,description TEXT NOT NULL,causes TEXT,checks TEXT,description_pl TEXT,description_en TEXT,category_id INTEGER,subcategory_id INTEGER)');
    }));
  }
  Future<List<T>> _list<T>(String table, T Function(Map<String,dynamic>) f,{String? where,List<Object?>? args,String? order}) async { final r=await (await database).query(table,where:where,whereArgs:args,orderBy:order); return r.map((e)=>f(Map<String,dynamic>.from(e))).toList(); }
  Future<List<CarBrand>> getBrands()=>_list('brands',CarBrand.fromMap,order:'name COLLATE NOCASE');
  Future<List<CarModel>> getModels(int id)=>_list('models',CarModel.fromMap,where:'brand_id=?',args:[id],order:'name COLLATE NOCASE');
  Future<List<Generation>> getGenerations(int id)=>_list('generations',Generation.fromMap,where:'model_id=?',args:[id],order:'year_from,name');
  Future<List<Engine>> getEngines(int id)=>_list('engines',Engine.fromMap,where:'generation_id=?',args:[id],order:'name COLLATE NOCASE');
  Future<List<Category>> getCategories()=>_list('categories',Category.fromMap,order:'name COLLATE NOCASE');
  Future<List<Subcategory>> getSubcategories(int id)=>_list('subcategories',Subcategory.fromMap,where:'category_id=?',args:[id],order:'name COLLATE NOCASE');
  Future<List<DtcCode>> getDtcCodes({String query=''}) async { final q=query.trim(); return _list('dtc_codes',DtcCode.fromMap,where:q.isEmpty?null:'code LIKE ? OR description LIKE ? OR description_pl LIKE ? OR description_en LIKE ?',args:q.isEmpty?null:['%$q%','%$q%','%$q%','%$q%'],order:'code COLLATE NOCASE'); }
  Future<void> insert(String t,Map<String,Object?> v)=> (await database).insert(t,v,conflictAlgorithm:ConflictAlgorithm.replace).then((_){});
  Future<void> update(String t,int id,Map<String,Object?> v)=> (await database).update(t,v,where:'id=?',whereArgs:[id]).then((_){});
  Future<void> remove(String t,int id) async { final db=await database; await db.transaction((tx) async {
    if(t=='brands'){ final ms=await tx.query('models',columns:['id'],where:'brand_id=?',whereArgs:[id]); for(final m in ms){ await _deleteModel(tx,m['id'] as int); } }
    else if(t=='models') await _deleteModel(tx,id);
    else if(t=='generations') await _deleteGeneration(tx,id);
    else if(t=='categories'){ await tx.delete('subcategories',where:'category_id=?',whereArgs:[id]); await tx.update('dtc_codes',{'category_id':null,'subcategory_id':null},where:'category_id=?',whereArgs:[id]); }
    else if(t=='subcategories') await tx.update('dtc_codes',{'subcategory_id':null},where:'subcategory_id=?',whereArgs:[id]);
    await tx.delete(t,where:'id=?',whereArgs:[id]);
  }); }
  Future<void> _deleteModel(Transaction tx,int id) async { final gs=await tx.query('generations',columns:['id'],where:'model_id=?',whereArgs:[id]); for(final g in gs){await _deleteGeneration(tx,g['id'] as int);} await tx.delete('models',where:'id=?',whereArgs:[id]); }
  Future<void> _deleteGeneration(Transaction tx,int id) async { await tx.delete('engines',where:'generation_id=?',whereArgs:[id]); await tx.delete('generations',where:'id=?',whereArgs:[id]); }
  Future<void> seedDatabase() async { final db=await database; final count=Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM brands'))??0; if(count>0)return; try { final v=jsonDecode(await rootBundle.loadString('assets/data/vehicles.json'))['vehicles']; if(v is List){ for(final x in v.whereType<Map>()){ final make=x['make']?.toString(); final model=x['model']?.toString(); final gen=x['generation']?.toString(); if(make==null||model==null||gen==null)continue; await db.insert('brands',{'name':make},conflictAlgorithm:ConflictAlgorithm.ignore); final b=(await db.query('brands',columns:['id'],where:'name=?',whereArgs:[make])).first['id'] as int; await db.insert('models',{'brand_id':b,'name':model},conflictAlgorithm:ConflictAlgorithm.ignore); final m=(await db.query('models',columns:['id'],where:'brand_id=? AND name=?',whereArgs:[b,model])).first['id'] as int; await db.insert('generations',{'model_id':m,'name':gen},conflictAlgorithm:ConflictAlgorithm.ignore); final g=(await db.query('generations',columns:['id'],where:'model_id=? AND name=?',whereArgs:[m,gen])).first['id'] as int; for(final e in (x['engines'] as List? ?? const [])){ if(e is Map){ final n=e['name']?.toString()??''; if(n.isNotEmpty)await db.insert('engines',{'generation_id':g,'name':n,'code':e['code']?.toString(),'fuel':e['fuel']?.toString(),'power':e['power_hp']},conflictAlgorithm:ConflictAlgorithm.ignore); } } } } } catch(_){} try { final d=jsonDecode(await rootBundle.loadString('assets/data/diagnostic_data.json'))['dtc']; if(d is List){ for(final x in d.whereType<Map>()){ final c=x['code']?.toString(); if(c==null)continue; await db.insert('dtc_codes',{'code':c,'description':x['name']?.toString()??'','causes':x['causes'] is List?(x['causes'] as List).join('\n'):x['causes']?.toString(),'checks':x['checks'] is List?(x['checks'] as List).join('\n'):x['checks']?.toString()},conflictAlgorithm:ConflictAlgorithm.ignore); } } } catch(_){} }
}
