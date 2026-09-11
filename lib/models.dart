class CarBrand {
  final int? id;
  final String name;

  const CarBrand({
    this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory CarBrand.fromMap(Map<String, dynamic> map) {
    return CarBrand(
      id: map['id'] as int?,
      name: map['name'] as String,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand_id': brandId,
      'name': name,
    };
  }

  factory CarModel.fromMap(Map<String, dynamic> map) {
    return CarModel(
      id: map['id'] as int?,
      brandId: map['brand_id'] as int,
      name: map['name'] as String,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'model_id': modelId,
      'name': name,
      'year_from': yearFrom,
      'year_to': yearTo,
    };
  }

  factory Generation.fromMap(Map<String, dynamic> map) {
    return Generation(
      id: map['id'] as int?,
      modelId: map['model_id'] as int,
      name: map['name'] as String,
      yearFrom: map['year_from'] as int?,
      yearTo: map['year_to'] as int?,
    );
  }
}

class Engine {
  final int? id;
  final int generationId;
  final String name;
  final String code;
  final String fuel;
  final int? displacement;
  final int? power;

  const Engine({
    this.id,
    required this.generationId,
    required this.name,
    required this.code,
    required this.fuel,
    this.displacement,
    this.power,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'generation_id': generationId,
      'name': name,
      'code': code,
      'fuel': fuel,
      'displacement': displacement,
      'power': power,
    };
  }

  factory Engine.fromMap(Map<String, dynamic> map) {
    return Engine(
      id: map['id'] as int?,
      generationId: map['generation_id'] as int,
      name: map['name'] as String,
      code: map['code'] as String,
      fuel: map['fuel'] as String,
      displacement: map['displacement'] as int?,
      power: map['power'] as int?,
    );
  }
}

class DtcCode {
  final int? id;
  final String code;
  final String description;
  final String causes;
  final String checks;

  const DtcCode({
    this.id,
    required this.code,
    required this.description,
    required this.causes,
    required this.checks,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'causes': causes,
      'checks': checks,
    };
  }

  factory DtcCode.fromMap(Map<String, dynamic> map) {
    return DtcCode(
      id: map['id'] as int?,
      code: map['code'] as String,
      description: map['description'] as String,
      causes: map['causes'] as String,
      checks: map['checks'] as String,
    );
  }
}
