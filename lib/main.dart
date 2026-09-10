import 'package:flutter/material.dart';

void main() {
  runApp(const CarDiagnosticApp());
}

class CarDiagnosticApp extends StatelessWidget {
  const CarDiagnosticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Car Diagnostic AI',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0F14),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedMake;
  String? selectedModel;
  String? selectedGeneration;
  String? selectedEngine;
  String? selectedYear;

  final TextEditingController problemController = TextEditingController();

  final Map<String, List<String>> models = {
    'BMW': [
      '1 Series',
      '2 Series',
      '3 Series',
      '4 Series',
      '5 Series',
      '7 Series',
      'X1',
      'X3',
      'X5',
    ],
    'Audi': [
      'A1',
      'A3',
      'A4',
      'A5',
      'A6',
      'A7',
      'A8',
      'Q3',
      'Q5',
      'Q7',
    ],
    'Volkswagen': [
      'Golf',
      'Passat',
      'Polo',
      'Tiguan',
      'Touran',
      'Touareg',
    ],
    'Mercedes-Benz': [
      'A-Class',
      'B-Class',
      'C-Class',
      'E-Class',
      'S-Class',
      'GLA',
      'GLC',
      'GLE',
    ],
    'Ford': [
      'Focus',
      'Fiesta',
      'Mondeo',
      'Kuga',
      'Mustang',
      'Transit',
    ],
    'Opel': [
      'Astra',
      'Corsa',
      'Insignia',
      'Zafira',
      'Mokka',
      'Vectra',
    ],
    'Toyota': [
      'Corolla',
      'Yaris',
      'Avensis',
      'Auris',
      'RAV4',
      'Camry',
    ],
    'Škoda': [
      'Fabia',
      'Octavia',
      'Superb',
      'Kodiaq',
      'Karoq',
      'Scala',
    ],
    'SEAT': [
      'Ibiza',
      'Leon',
      'Toledo',
      'Ateca',
      'Alhambra',
    ],
    'Volvo': [
      'S40',
      'S60',
      'S80',
      'V40',
      'V60',
      'XC60',
      'XC90',
    ],
    'Renault': [
      'Clio',
      'Megane',
      'Laguna',
      'Scenic',
      'Captur',
      'Kadjar',
    ],
    'Peugeot': [
      '206',
      '207',
      '208',
      '307',
      '308',
      '407',
      '508',
      '3008',
    ],
    'Citroën': [
      'C3',
      'C4',
      'C5',
      'Berlingo',
      'DS3',
      'DS4',
    ],
    'Fiat': [
      'Panda',
      'Punto',
      '500',
      'Bravo',
      'Tipo',
      'Ducato',
    ],
    'Alfa Romeo': [
      '147',
      '156',
      '159',
      'Giulietta',
      'Giulia',
      'Stelvio',
    ],
    'Honda': [
      'Civic',
      'Accord',
      'Jazz',
      'CR-V',
      'HR-V',
    ],
    'Mazda': [
      'Mazda 2',
      'Mazda 3',
      'Mazda 6',
      'CX-3',
      'CX-5',
    ],
    'Nissan': [
      'Micra',
      'Almera',
      'Qashqai',
      'X-Trail',
      'Juke',
    ],
    'Hyundai': [
      'i10',
      'i20',
      'i30',
      'Tucson',
      'Santa Fe',
    ],
    'Kia': [
      'Rio',
      'Ceed',
      'Sportage',
      'Sorento',
      'Picanto',
    ],
  };

  final Map<String, List<String>> generations = {
    '3 Series': ['E36', 'E46', 'E90/E91/E92/E93', 'F30/F31/F34', 'G20/G21'],
    '5 Series': ['E39', 'E60/E61', 'F10/F11', 'G30/G31'],
    'Golf': ['Golf IV', 'Golf V', 'Golf VI', 'Golf VII', 'Golf VIII'],
    'A4': ['B5', 'B6', 'B7', 'B8', 'B9'],
    'A3': ['8L', '8P', '8V', '8Y'],
    'Passat': ['B5', 'B6', 'B7', 'B8'],
    'C-Class': ['W202', 'W203', 'W204', 'W205', 'W206'],
    'E-Class': ['W210', 'W211', 'W212', 'W213'],
    'Focus': ['Mk1', 'Mk2', 'Mk3', 'Mk4'],
    'Astra': ['G', 'H', 'J', 'K', 'L'],
    'Octavia': ['I', 'II', 'III', 'IV'],
  };

  List<String> get currentModels {
    if (selectedMake == null) return [];
    return models[selectedMake] ?? [];
  }

  List<String> get currentGenerations {
    if (selectedModel == null) return [];
    return generations[selectedModel] ??
        ['Generacja 1', 'Generacja 2', 'Generacja 3'];
  }

  List<String> get engines {
    if (selectedModel == null) return [];

    if (selectedModel == '3 Series') {
      return ['316d', '318d', '320d', '325d', '330d', '335d', '320i', '325i'];
    }

    if (selectedModel == 'Golf') {
      return ['1.4 TSI', '1.5 TSI', '1.6 TDI', '2.0 TDI', '2.0 TSI'];
    }

    if (selectedModel == 'A4') {
      return ['1.8 TFSI', '2.0 TFSI', '2.0 TDI', '3.0 TDI'];
    }

    return ['1.0', '1.2', '1.4', '1.6', '2.0 Diesel', '2.0 Petrol'];
  }

  Future<void> diagnose() async {
    final problem = problemController.text.trim();

    if (selectedMake == null ||
        selectedModel == null ||
        selectedGeneration == null ||
        problem.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Brak danych'),
          content: const Text(
            'Wybierz samochód i wpisz opis problemu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiagnosisPage(
          make: selectedMake!,
          model: selectedModel!,
          generation: selectedGeneration!,
          engine: selectedEngine,
          year: selectedYear,
          problem: problem,
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
        backgroundColor: const Color(0xFF111820),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
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
                  'Wybierz samochód i opisz problem.',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 32),

                _sectionTitle('🚗 SAMOCHÓD'),

                _dropdown(
                  label: 'Marka',
                  value: selectedMake,
                  items: models.keys.toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMake = value;
                      selectedModel = null;
                      selectedGeneration = null;
                      selectedEngine = null;
                    });
                  },
                ),

                const SizedBox(height: 14),

                _dropdown(
                  label: 'Model',
                  value: selectedModel,
                  items: currentModels,
                  onChanged: selectedMake == null
                      ? null
                      : (value) {
                          setState(() {
                            selectedModel = value;
                            selectedGeneration = null;
                            selectedEngine = null;
                          });
                        },
                ),

                const SizedBox(height: 14),

                _dropdown(
                  label: 'Generacja',
                  value: selectedGeneration,
                  items: currentGenerations,
                  onChanged: selectedModel == null
                      ? null
                      : (value) {
                          setState(() {
                            selectedGeneration = value;
                          });
                        },
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _dropdown(
                        label: 'Silnik',
                        value: selectedEngine,
                        items: engines,
                        onChanged: selectedModel == null
                            ? null
                            : (value) {
                                setState(() {
                                  selectedEngine = value;
                                });
                              },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _dropdown(
                        label: 'Rok',
                        value: selectedYear,
                        items: List.generate(
                          35,
                          (index) => '${2026 - index}',
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedYear = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                _sectionTitle('🔧 OPIS PROBLEMU'),

                TextField(
                  controller: problemController,
                  minLines: 6,
                  maxLines: 10,
                  decoration: InputDecoration(
                    hintText:
                        'Np. Auto szarpie przy przyspieszaniu między 1500 a 2500 obr./min...',
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
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: diagnose,
                    icon: const Icon(Icons.search),
                    label: const Text(
                      'DIAGNOZUJ',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111820),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          'Wersja V1 korzysta z lokalnej bazy demonstracyjnej. '
                          'W kolejnych wersjach dodamy rzeczywistą bazę pojazdów, '
                          'wyszukiwanie internetowe, AI oraz OBD-II.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
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
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
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
  final String? engine;
  final String? year;
  final String problem;

  const DiagnosisPage({
    super.key,
    required this.make,
    required this.model,
    required this.generation,
    required this.engine,
    required this.year,
    required this.problem,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wynik diagnostyki'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔎 DIAGNOZA',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),

                _card(
                  'SAMOCHÓD',
                  '$make $model\n$generation'
                  '${engine != null ? '\nSilnik: $engine' : ''}'
                  '${year != null ? '\nRok: $year' : ''}',
                ),

                _card(
                  'ZGŁOSZONY PROBLEM',
                  problem,
                ),

                const SizedBox(height: 10),

                const Text(
                  'POTENCJALNE PRZYCZYNY',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                _cause('Układ dolotowy / EGR', 0.78, Colors.red),
                _cause('Przepływomierz MAF', 0.64, Colors.orange),
                _cause('Podciśnienie / sterowanie turbo', 0.53, Colors.amber),
                _cause('Układ paliwowy', 0.41, Colors.green),

                const SizedBox(height: 25),

                _card(
                  'CO SPRAWDZIĆ',
                  '1. Odczytaj kody błędów OBD.\n'
                      '2. Sprawdź wartości MAF.\n'
                      '3. Sprawdź działanie EGR.\n'
                      '4. Sprawdź przewody podciśnienia.\n'
                      '5. Wykonaj jazdę testową i zapisz objawy.',
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.4),
                    ),
                  ),
                  child: const Text(
                    'UWAGA: To demonstracyjna analiza V1, a nie '
                    'potwierdzona diagnoza mechaniczna. Przed naprawą '
                    'należy zweryfikować przyczynę odpowiednimi testami.',
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.public),
                    label: const Text(
                      'WYSZUKAJ INFORMACJE W INTERNECIE',
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

  Widget _card(String title, String text) {
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
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _cause(String name, double probability, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                '${(probability * 100).round()}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: probability,
            minHeight: 7,
            color: color,
            backgroundColor: Colors.grey.shade800,
          ),
        ],
      ),
    );
  }
}
