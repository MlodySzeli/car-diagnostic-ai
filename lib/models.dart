class CarBrand {
  int? id;
  String name;

  CarBrand({
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
      id: map['id'],
      name: map['name'],
    );
  }
}

class CarModel {
  int? id;
  int brandId;
  String name;

  CarModel({
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
      id: map['id'],
      brandId: map['brand_id'],
      name: map['name'],
    );
  }
}

class Generation {
  int? id;
  int modelId;
  String name;
  int? yearFrom;
  int? yearTo;

  Generation({
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
      id: map['id'],
      modelId: map['model_id'],
      name: map['name'],
      yearFrom: map['year_from'],
      yearTo: map['year_to'],
    );
  }
}

class Engine {
  int? id;
  int generationId;
  String name;
  String code;
  String fuel;
  int? displacement;
  int? power;

  Engine({
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
      id: map['id'],
      generationId: map['generation_id'],
      name: map['name'],
      code: map['code'],
      fuel: map['fuel'],
      displacement: map['displacement'],
      power: map['power'],
    );
  }
}

class DtcCode {
  int? id;
  String code;
  String description;
  String causes;
  String checks;

  DtcCode({
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
      id: map['id'],
      code: map['code'],
      description: map['description'],
      causes: map['causes'],
      checks: map['checks'],
    );
  }
}
