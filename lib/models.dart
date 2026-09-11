class CarBrand {
  final int? id;
  final String name;
  const CarBrand({this.id, required this.name});
  factory CarBrand.fromMap(Map<String, dynamic> m) => CarBrand(id: m['id'] as int?, name: (m['name'] ?? '').toString());
}
class CarModel {
  final int? id; final int brandId; final String name;
  const CarModel({this.id, required this.brandId, required this.name});
  factory CarModel.fromMap(Map<String,dynamic> m)=>CarModel(id:m['id'] as int?,brandId:m['brand_id'] as int,name:(m['name']??'').toString());
}
class Generation {
  final int? id; final int modelId; final String name; final int? yearFrom; final int? yearTo;
  const Generation({this.id,required this.modelId,required this.name,this.yearFrom,this.yearTo});
  factory Generation.fromMap(Map<String,dynamic> m)=>Generation(id:m['id'] as int?,modelId:m['model_id'] as int,name:(m['name']??'').toString(),yearFrom:m['year_from'] as int?,yearTo:m['year_to'] as int?);
}
class Engine {
  final int? id; final int generationId; final String name; final String? code; final String? fuel; final int? displacement; final int? power;
  const Engine({this.id,required this.generationId,required this.name,this.code,this.fuel,this.displacement,this.power});
  factory Engine.fromMap(Map<String,dynamic> m)=>Engine(id:m['id'] as int?,generationId:m['generation_id'] as int,name:(m['name']??'').toString(),code:m['code']?.toString(),fuel:m['fuel']?.toString(),displacement:m['displacement'] as int?,power:m['power'] as int?);
}
class DtcCode {
  final int? id; final String code; final String description; final String? causes; final String? checks; final String? descriptionPl; final String? descriptionEn; final int? categoryId; final int? subcategoryId;
  const DtcCode({this.id,required this.code,required this.description,this.causes,this.checks,this.descriptionPl,this.descriptionEn,this.categoryId,this.subcategoryId});
  factory DtcCode.fromMap(Map<String,dynamic> m)=>DtcCode(id:m['id'] as int?,code:(m['code']??'').toString(),description:(m['description']??'').toString(),causes:m['causes']?.toString(),checks:m['checks']?.toString(),descriptionPl:m['description_pl']?.toString(),descriptionEn:m['description_en']?.toString(),categoryId:m['category_id'] as int?,subcategoryId:m['subcategory_id'] as int?);
}
class Category { final int? id; final String name; const Category({this.id,required this.name}); factory Category.fromMap(Map<String,dynamic> m)=>Category(id:m['id'] as int?,name:(m['name']??'').toString()); }
class Subcategory { final int? id; final int categoryId; final String name; const Subcategory({this.id,required this.categoryId,required this.name}); factory Subcategory.fromMap(Map<String,dynamic> m)=>Subcategory(id:m['id'] as int?,categoryId:m['category_id'] as int,name:(m['name']??'').toString()); }
