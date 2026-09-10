import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const CarDiagnosticApp());
}

class CarDiagnosticApp extends StatelessWidget {
  const CarDiagnosticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Diagnostic AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF080C11),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class Vehicle {
  final String make;
  final String model;
  final String generation;
  final String years;
  final List<Engine> engines;

  Vehicle({
    required this.make,
    required this.model,
    required this.generation,
    required this.years,
    required this.engines,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      make: json['make'],
      model: json['model'],
      generation: json['generation'],
      years: json['years'],
      engines: (json['engines'] as List)
          .map((e) => Engine.fromJson(e))
          .toList(),
    );
  }
}

class Engine {
  final String name;
  final String code;
  final String fuel;
  final int power;

  Engine({
    required this.name,
    required this.code,
    required this.fuel,
    required this.power,
  });

  factory Engine.fromJson(Map<String, dynamic> json) {
    return Engine(
      name: json['name'],
      code: json['code'],
      fuel: json['fuel'],
      power: json['power_hp'],
    );
  }
}

class DtcCode {
  final String code;
  final String name;
  final List<String> causes;
  final List<String> checks;

  DtcCode({
    required this.code,
    required this.name,
    required this.causes,
    required this.checks,
  });

  factory DtcCode.fromJson(Map<String, dynamic> json) {
    return DtcCode(
      code: json['code'],
      name: json['name'],
      causes: List<String>.from(json['causes']),
      checks: List<String>.from(json['checks']),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Vehicle> vehicles = [];
  List<DtcCode> dtcCodes = [];

  String? make;
  String? model;
  String? generation;
  Engine? engine;
  String? year;
  String? selectedDtc;

  final problemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadDatabase();
  }

  Future<void> loadDatabase() async {
    final vehicleData =
        await rootBundle.loadString('assets/data/vehicles.json');

    final diagnosticData =
        await rootBundle.loadString('assets/data/diagnostic_data.json');

    final vehicleJson = jsonDecode(vehicleData);
    final diagnosticJson = jsonDecode(diagnosticData);

    setState(() {
      vehicles = (vehicleJson['vehicles'] as List)
          .map((v) => Vehicle.fromJson(v))
          .toList();

      dtcCodes = (diagnosticJson['dtc'] as List)
          .map((d) => DtcCode.fromJson(d))
          .toList();
    });
  }

  List<String> get makes {
    return vehicles.map((v) => v.make).toSet().toList()..sort();
  }

  List<String> get models {
    if (make == null) return [];

    return vehicles
        .where((v) => v.make == make)
        .map((v) => v.model)
        .toSet()
        .toList()
      ..sort();
  }

  List<Vehicle> get matchingVehicles {
    return vehicles.where((v) {
      return v.make == make && v.model == model;
    }).toList();
  }

  List<String> get generations {
    return matchingVehicles.map((v) => v.generation).toSet().toList();
  }

  Vehicle? get selectedVehicle {
    try {
      return matchingVehicles.firstWhere(
        (v) => v.generation == generation,
      );
    } catch (_) {
      return null;
    }
  }

  List<Engine> get engines {
    return selectedVehicle?.engines ?? [];
  }

  List<String> get years {
    final vehicle = selectedVehicle;

    if (vehicle == null) return [];

    final match = RegExp(r'(\d{4})-(\d{4})').firstMatch(vehicle.years);

    if (match == null) return [vehicle.years];

    final start = int.parse(match.group(1)!);
    final end = int.parse(match.group(2)!);

    return List.generate(
      end - start + 1,
      (index) => '${start + index}',
    ).reversed.toList();
  }

  void resetModel() {
    model = null;
    generation = null;
    engine = null;
    year = null;
  }

  void resetGeneration() {
    generation = null;
    engine = null;
    year = null;
  }

  void resetEngine() {
    engine = null;
    year = null;
  }

  void diagnose() {
    if (make == null ||
        model == null ||
        generation == null ||
        problemController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Wybierz samochód i wpisz opis problemu.',
          ),
        ),
      );
      return;
    }

    DtcCode? dtc;

    if (selectedDtc != null) {
      try {
        dtc = dtcCodes.firstWhere(
          (d) => d.code == selectedDtc,
        );
      } catch (_) {}
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiagnosisPage(
          make: make!,
          model: model!,
          generation: generation!,
          engine: engine,
          year: year,
          problem: problemController.text.trim(),
          dtc: dtc,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CAR DIAGNOSTIC AI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: vehicles.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1100,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Diagnostyka samochodowa',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Wybierz dokładną konfigurację samochodu.',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 30),

                      sectionTitle('🚗 SAMOCHÓD'),

                      dropdown(
                        label: 'Marka',
                        value: make,
                        items: makes,
                        onChanged: (value) {
                          setState(() {
                            make = value;
                            resetModel();
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      dropdown(
                        label: 'Model',
                        value: model,
                        items: models,
                        enabled: make != null,
                        onChanged: (value) {
                          setState(() {
                            model = value;
                            resetGeneration();
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      dropdown(
                        label: 'Generacja',
                        value: generation,
                        items: generations,
                        enabled: model != null,
                        onChanged: (value) {
                          setState(() {
                            generation = value;
                            resetEngine();
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: dropdown(
                              label: 'Silnik',
                              value: engine?.name,
                              items: engines
                                  .map(
                                    (e) => '${e.name} — ${e.code}',
                                  )
                                  .toList(),
                              enabled: generation != null,
                              onChanged: (value) {
                                if (value == null) return;

                                setState(() {
                                  engine = engines.firstWhere(
                                    (e) =>
                                        '${e.name} — ${e.code}' ==
                                        value,
                                  );
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: dropdown(
                              label: 'Rok',
                              value: year,
                              items: years,
                              enabled: generation != null,
                              onChanged: (value) {
                                setState(() {
                                  year = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      if (engine != null) ...[
                        const SizedBox(height: 15),
                        infoCard(
                          title: 'SILNIK',
                          text:
                              '${engine!.name} | ${engine!.code}\n'
                              '${engine!.fuel} | ${engine!.power} KM',
                        ),
                      ],

                      const SizedBox(height: 30),

                      sectionTitle('⚠️ KOD OBD / DTC'),

                      dropdown(
                        label: 'Kod błędu — opcjonalnie',
                        value: selectedDtc,
                        items: dtcCodes.map((d) => d.code).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDtc = value;
                          });
                        },
                      ),

                      const SizedBox(height: 30),

                      sectionTitle('🔧 OPIS PROBLEMU'),

                      TextField(
                        controller: problemController,
                        minLines: 6,
                        maxLines: 10,
                        decoration: InputDecoration(
                          hintText:
                              'Np. samochód szarpie podczas przyspieszania, '
                              'traci moc przy 2000 obr./min...',
                          filled: true,
                          fillColor: const Color(0xFF111820),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(20),
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: FilledButton.icon(
                          onPressed: diagnose,
                          icon: const Icon(Icons.search),
                          label: const Text(
                            'DIAGNOZUJ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      infoCard(
                        title: 'V2',
                        text:
                            'Baza pojazdów i kodów diagnostycznych jest '
                            'oddzielona od programu. Dzięki temu będziemy '
                            'mogli ją później rozbudować bez przebudowy '
                            'całej aplikacji.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    final safeValue = items.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF111820),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget infoCard({
    required String title,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111820),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(text),
        ],
      ),
    );
  }

  @override
  void dispose() {
    problemController.dispose();
    super.dispose();
  }
}

class DiagnosisPage extends StatelessWidget {
  final String make;
  final String model;
  final String generation;
  final Engine? engine;
  final String? year;
  final String problem;
  final DtcCode? dtc;

  const DiagnosisPage({
    super.key,
    required this.make,
    required this.model,
    required this.generation,
    required this.engine,
    required this.year,
    required this.problem,
    required this.dtc,
  });

  @override
  Widget build(BuildContext context) {
    final causes = <String>[
      if (dtc != null) ...dtc!.causes,
      'Układ dolotowy',
      'Układ paliwowy',
      'Układ sterowania silnikiem',
    ].toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wynik diagnostyki'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1000,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔎 WYNIK ANALIZY',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 25),

                card(
                  'SAMOCHÓD',
                  '$make $model\n'
                  '$generation\n'
                  '${engine != null ? 'Silnik: ${engine!.name} (${engine!.code})\n' : ''}'
                  '${year != null ? 'Rok: $year' : ''}',
                ),

                card(
                  'PROBLEM',
                  problem,
                ),

                if (dtc != null)
                  card(
                    'KOD DTC',
                    '${dtc!.code}\n${dtc!.name}',
                  ),

                const SizedBox(height: 10),

                const Text(
                  'MOŻLIWE PRZYCZYNY',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                ...causes.asMap().entries.map(
                      (entry) => cause(
                        entry.value,
                        [
                          82,
                          70,
                          61,
                          52,
                          43,
                          35,
                        ][entry.key.clamp(0, 5)],
                      ),
                    ),

                if (dtc != null) ...[
                  const SizedBox(height: 20),

                  const Text(
                    'CO SPRAWDZIĆ',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  card(
                    'PROCEDURA',
                    dtc!.checks
                        .asMap()
                        .entries
                        .map(
                          (e) => '${e.key + 1}. ${e.value}',
                        )
                        .join('\n'),
                  ),
                ],

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'To jest analiza pomocnicza. Wynik nie jest '
                    'potwierdzoną diagnozą mechaniczną. Przyczynę '
                    'należy potwierdzić odpowiednimi pomiarami i testami.',
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Wyszukiwanie internetowe dodamy w kolejnej wersji.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.public),
                    label: const Text(
                      'WYSZUKAJ W INTERNECIE',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget card(String title, String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111820),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget cause(String name, int probability) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111820),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$probability%',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: probability / 100,
            minHeight: 7,
          ),
        ],
      ),
    );
  }
}
