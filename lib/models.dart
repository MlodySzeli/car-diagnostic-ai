class CarBrand {
  final int? id;
  final String name;

  const CarBrand({
    this.id,
    required this.name,
  });

  factory CarBrand.fromMap(Map<String, dynamic> map) {
    return CarBrand(
      id: map['id'] as int?,
      name: (map['name'] ?? '').toString(),
    );
  }
}

class CarModel {
  final int? id;
  final int brandId;
  final String name;

  const CarModel({
    this.id,
    required this.brandId,
    required this.name,
  });

  factory CarModel.fromMap(Map<String, dynamic> map) {
    return CarModel(
      id: map['id'] as int?,
      brandId: map['brand_id'] as int,
      name: (map['name'] ?? '').toString(),
    );
  }
}

class Generation {
  final int? id;
  final int modelId;
  final String name;
  final int? yearFrom;
  final int? yearTo;

  const Generation({
    this.id,
    required this.modelId,
    required this.name,
    this.yearFrom,
    this.yearTo,
  });

  factory Generation.fromMap(Map<String, dynamic> map) {
    return Generation(
      id: map['id'] as int?,
      modelId: map['model_id'] as int,
      name: (map['name'] ?? '').toString(),
      yearFrom: map['year_from'] as int?,
      yearTo: map['year_to'] as int?,
    );
  }
}

class Engine {
  final int? id;
  final int generationId;
  final String name;
  final String? code;
  final String? fuel;
  final int? displacement;
  final int? power;

  const Engine({
    this.id,
    required this.generationId,
    required this.name,
    this.code,
    this.fuel,
    this.displacement,
    this.power,
  });

  factory Engine.fromMap(Map<String, dynamic> map) {
    return Engine(
      id: map['id'] as int?,
      generationId: map['generation_id'] as int,
      name: (map['name'] ?? '').toString(),
      code: map['code']?.toString(),
      fuel: map['fuel']?.toString(),
      displacement: map['displacement'] as int?,
      power: map['power'] as int?,
    );
  }
}

class Category {
  final int? id;
  final String name;

  const Category({
    this.id,
    required this.name,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: (map['name'] ?? '').toString(),
    );
  }
}

class Subcategory {
  final int? id;
  final int categoryId;
  final String name;

  const Subcategory({
    this.id,
    required this.categoryId,
    required this.name,
  });

  factory Subcategory.fromMap(Map<String, dynamic> map) {
    return Subcategory(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      name: (map['name'] ?? '').toString(),
    );
  }
}

class DtcCode {
  final int? id;
  final String code;
  final String description;
  final String? causes;
  final String? checks;
  final String? descriptionPl;
  final String? descriptionEn;

  const DtcCode({
    this.id,
    required this.code,
    required this.description,
    this.causes,
    this.checks,
    this.descriptionPl,
    this.descriptionEn,
  });

  factory DtcCode.fromMap(Map<String, dynamic> map) {
    return DtcCode(
      id: map['id'] as int?,
      code: (map['code'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      causes: map['causes']?.toString(),
      checks: map['checks']?.toString(),
      descriptionPl: map['description_pl']?.toString(),
      descriptionEn: map['description_en']?.toString(),
    );
  }
}

class VehicleSearchResult {
  final int engineId;
  final String brand;
  final String model;
  final String generation;
  final String engine;
  final String? engineCode;
  final String? fuel;
  final int? power;

  const VehicleSearchResult({
    required this.engineId,
    required this.brand,
    required this.model,
    required this.generation,
    required this.engine,
    this.engineCode,
    this.fuel,
    this.power,
  });

  factory VehicleSearchResult.fromMap(Map<String, dynamic> map) {
    return VehicleSearchResult(
      engineId: map['engine_id'] as int,
      brand: map['brand'].toString(),
      model: map['model'].toString(),
      generation: map['generation'].toString(),
      engine: map['engine'].toString(),
      engineCode: map['engine_code']?.toString(),
      fuel: map['fuel']?.toString(),
      power: map['power'] as int?,
    );
  }
}
