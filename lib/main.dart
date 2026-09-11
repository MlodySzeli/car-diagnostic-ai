import 'package:flutter/material.dart';

import 'database.dart';
import 'models.dart';

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
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final db = AppDatabase.instance;

  int currentPage = 0;

  List<CarBrand> brands = [];
  List<CarModel> models = [];
  List<Generation> generations = [];
  List<Engine> engines = [];
  List<DtcCode> dtcs = [];

  CarBrand? selectedBrand;
  CarModel? selectedModel;
  Generation? selectedGeneration;
  Engine? selectedEngine;
  DtcCode? selectedDtc;

  final problemController = TextEditingController();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    try {
      await db.seedDatabase();
      await loadBrands();
      await loadDtcs();
    } catch (e) {
      debugPrint('Database error: $e');
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> loadBrands() async {
    final result = await db.getBrands();

    if (!mounted) return;

    setState(() {
      brands = result;
    });
  }

  Future<void> loadDtcs() async {
    final result = await db.getDtcCodes();

    if (!mounted) return;

    setState(() {
      dtcs = result;
    });
  }

  Future<void> selectBrand(CarBrand? value) async {
    if (value == null) return;

    final result = await db.getModels(value.id!);

    setState(() {
      selectedBrand = value;
      selectedModel = null;
      selectedGeneration = null;
      selectedEngine = null;

      models = result;
      generations = [];
      engines = [];
    });
  }

  Future<void> selectModel(CarModel? value) async {
    if (value == null) return;

    final result = await db.getGenerations(value.id!);

    setState(() {
      selectedModel = value;
      selectedGeneration = null;
      selectedEngine = null;

      generations = result;
      engines = [];
    });
  }

  Future<void> selectGeneration(Generation? value) async {
    if (value == null) return;

    final result = await db.getEngines(value.id!);

    setState(() {
      selectedGeneration = value;
      selectedEngine = null;
      engines = result;
    });
  }

  Future<void> addBrandDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dodaj markę'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nazwa marki',
            hintText: 'Np. BMW',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANULUJ'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();

              if (name.isEmpty) return;

              await db.addBrand(
                CarBrand(name: name),
              );

              if (mounted) {
                Navigator.pop(context);
                await loadBrands();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dodano markę: $name'),
                  ),
                );
              }
            },
            child: const Text('ZAPISZ'),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  Future<void> addModelDialog() async {
    if (selectedBrand == null) {
      showMessage('Najpierw wybierz markę.');
      return;
    }

    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Dodaj model — ${selectedBrand!.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Model',
            hintText: 'Np. 320d',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANULUJ'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();

              if (name.isEmpty) return;

              await db.addModel(
                CarModel(
                  brandId: selectedBrand!.id!,
                  name: name,
                ),
              );

              if (mounted) {
                Navigator.pop(context);

                final result =
                    await db.getModels(selectedBrand!.id!);

                setState(() {
                  models = result;
                });

                showMessage('Dodano model: $name');
              }
            },
            child: const Text('ZAPISZ'),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  Future<void> addGenerationDialog() async {
    if (selectedModel == null) {
      showMessage('Najpierw wybierz model.');
      return;
    }

    final nameController = TextEditingController();
    final fromController = TextEditingController();
    final toController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Dodaj generację — ${selectedModel!.name}',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Generacja',
                  hintText: 'Np. E90',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fromController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rok od',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: toController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rok do',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANULUJ'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();

              if (name.isEmpty) return;

              await db.addGeneration(
                Generation(
                  modelId: selectedModel!.id!,
                  name: name,
                  yearFrom:
                      int.tryParse(fromController.text.trim()),
                  yearTo:
                      int.tryParse(toController.text.trim()),
                ),
              );

              if (mounted) {
                Navigator.pop(context);

                final result =
                    await db.getGenerations(selectedModel!.id!);

                setState(() {
                  generations = result;
                });

                showMessage('Dodano generację: $name');
              }
            },
            child: const Text('ZAPISZ'),
          ),
        ],
      ),
    );

    nameController.dispose();
    fromController.dispose();
    toController.dispose();
  }

  Future<void> addEngineDialog() async {
    if (selectedGeneration == null) {
      showMessage('Najpierw wybierz generację.');
      return;
    }

    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final fuelController = TextEditingController();
    final displacementController = TextEditingController();
    final powerController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dodaj silnik'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nazwa silnika',
                  hintText: 'Np. 320d',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Kod silnika',
                  hintText: 'Np. N47',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: fuelController,
                decoration: const InputDecoration(
                  labelText: 'Paliwo',
                  hintText: 'Diesel / Benzyna / Hybrid',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: displacementController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pojemność cm³',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: powerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Moc KM',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANULUJ'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final code = codeController.text.trim();
              final fuel = fuelController.text.trim();

              if (name.isEmpty ||
                  code.isEmpty ||
                  fuel.isEmpty) {
                return;
              }

              await db.addEngine(
                Engine(
                  generationId: selectedGeneration!.id!,
                  name: name,
                  code: code,
                  fuel: fuel,
                  displacement:
                      int.tryParse(displacementController.text),
                  power:
                      int.tryParse(powerController.text),
                ),
              );

              if (mounted) {
                Navigator.pop(context);

                final result =
                    await db.getEngines(selectedGeneration!.id!);

                setState(() {
                  engines = result;
                });

                showMessage('Dodano silnik: $name');
              }
            },
            child: const Text('ZAPISZ'),
          ),
        ],
      ),
    );

    nameController.dispose();
    codeController.dispose();
    fuelController.dispose();
    displacementController.dispose();
    powerController.dispose();
  }

  Future<void> addDtcDialog() async {
    final codeController = TextEditingController();
    final descriptionController = TextEditingController();
    final causesController = TextEditingController();
    final checksController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dodaj kod DTC'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Kod DTC',
                  hintText: 'Np. P0299',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Opis błędu',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: causesController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Możliwe przyczyny',
                  hintText:
                      'Każdą przyczynę wpisz w osobnej linii',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: checksController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Co sprawdzić',
                  hintText:
                      'Każdy punkt wpisz w osobnej linii',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANULUJ'),
          ),
          FilledButton(
            onPressed: () async {
              final code =
                  codeController.text.trim().toUpperCase();

              if (code.isEmpty) return;

              await db.addDtc(
                DtcCode(
                  code: code,
                  description:
                      descriptionController.text.trim(),
                  causes: causesController.text.trim(),
                  checks: checksController.text.trim(),
                ),
              );

              if (mounted) {
                Navigator.pop(context);

                await loadDtcs();

                showMessage('Dodano kod DTC: $code');
              }
            },
            child: const Text('ZAPISZ'),
          ),
        ],
      ),
    );

    codeController.dispose();
    descriptionController.dispose();
    causesController.dispose();
    checksController.dispose();
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  void diagnose() {
    if (selectedBrand == null ||
        selectedModel == null ||
        selectedGeneration == null ||
        problemController.text.trim().isEmpty) {
      showMessage(
        'Wybierz samochód i wpisz opis problemu.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiagnosisPage(
          brand: selectedBrand!,
          model: selectedModel!,
          generation: selectedGeneration!,
          engine: selectedEngine,
          dtc: selectedDtc,
          problem: problemController.text.trim(),
        ),
      ),
    );
  }

  Widget dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) text,
    required ValueChanged<T?> onChanged,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<T>(
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
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                text(item),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Ładowanie bazy samochodów...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CAR DIAGNOSTIC AI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentPage,
            onDestinationSelected: (index) {
              setState(() {
                currentPage = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.car_repair),
                selectedIcon: Icon(Icons.car_repair),
                label: Text('Diagnoza'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.directions_car),
                label: Text('Baza aut'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.error_outline),
                label: Text('DTC'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: currentPage == 0
                ? buildDiagnosis()
                : currentPage == 1
                    ? buildDatabasePage()
                    : buildDtcPage(),
          ),
        ],
      ),
    );
  }

  Widget buildDiagnosis() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1050,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Diagnostyka samochodu',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Wybierz pojazd, kod DTC i opisz problem.',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              sectionTitle('🚗 POJAZD'),
              dropdown<CarBrand>(
                label: 'Marka',
                value: selectedBrand,
                items: brands,
                text: (b) => b.name,
                onChanged: selectBrand,
              ),
              const SizedBox(height: 14),
              dropdown<CarModel>(
                label: 'Model',
                value: selectedModel,
                items: models,
                text: (m) => m.name,
                enabled: selectedBrand != null,
                onChanged: selectModel,
              ),
              const SizedBox(height: 14),
              dropdown<Generation>(
                label: 'Generacja',
                value: selectedGeneration,
                items: generations,
                text: (g) {
                  if (g.yearFrom != null &&
                      g.yearTo != null) {
                    return '${g.name} (${g.yearFrom}-${g.yearTo})';
                  }

                  return g.name;
                },
                enabled: selectedModel != null,
                onChanged: selectGeneration,
              ),
              const SizedBox(height: 14),
              dropdown<Engine>(
                label: 'Silnik',
                value: selectedEngine,
                items: engines,
                text: (e) =>
                    '${e.name} — ${e.code} — ${e.power ?? '?'} KM',
                enabled: selectedGeneration != null,
                onChanged: (value) {
                  setState(() {
                    selectedEngine = value;
                  });
                },
              ),
              const SizedBox(height: 30),
              sectionTitle('⚠️ KOD DTC'),
              Row(
                children: [
                  Expanded(
                    child: dropdown<DtcCode>(
                      label: 'Wybierz kod DTC',
                      value: selectedDtc,
                      items: dtcs,
                      text: (d) =>
                          '${d.code} — ${d.description}',
                      onChanged: (value) {
                        setState(() {
                          selectedDtc = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    tooltip: 'Dodaj DTC',
                    onPressed: addDtcDialog,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              sectionTitle('🔧 OPIS PROBLEMU'),
              TextField(
                controller: problemController,
                minLines: 6,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText:
                      'Np. BMW 320d szarpie podczas przyspieszania '
                      'między 1500 a 2500 obr./min...',
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
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDatabasePage() {
    return Center(
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
                'Baza samochodów',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dodawaj własne marki, modele, generacje i silniki.',
                style: TextStyle(
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 30),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: addBrandDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('DODAJ MARKĘ'),
                  ),
                  FilledButton.icon(
                    onPressed: addModelDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('DODAJ MODEL'),
                  ),
                  FilledButton.icon(
                    onPressed: addGenerationDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('DODAJ GENERACJĘ'),
                  ),
                  FilledButton.icon(
                    onPressed: addEngineDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('DODAJ SILNIK'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              buildSelectionSummary(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSelectionSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111820),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AKTUALNIE WYBRANE',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            selectedBrand == null
                ? 'Nie wybrano pojazdu.'
                : [
                    selectedBrand!.name,
                    if (selectedModel != null)
                      selectedModel!.name,
                    if (selectedGeneration != null)
                      selectedGeneration!.name,
                    if (selectedEngine != null)
                      '${selectedEngine!.name} (${selectedEngine!.code})',
                  ].join(' → '),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          Text(
            'Liczba marek w bazie: ${brands.length}',
          ),
          Text(
            'Liczba kodów DTC: ${dtcs.length}',
          ),
        ],
      ),
    );
  }

  Widget buildDtcPage() {
    return Center(
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
                'Baza kodów DTC',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Wybieraj istniejące kody lub dodawaj własne.',
                style: TextStyle(
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 25),
              FilledButton.icon(
                onPressed: addDtcDialog,
                icon: const Icon(Icons.add),
                label: const Text('DODAJ WŁASNY KOD DTC'),
              ),
              const SizedBox(height: 25),
              ...dtcs.map(
                (dtc) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111820),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      dtc.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(dtc.description),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      if (dtc.causes.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'MOŻLIWE PRZYCZYNY\n\n${dtc.causes}',
                          ),
                        ),
                      const SizedBox(height: 15),
                      if (dtc.checks.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'CO SPRAWDZIĆ\n\n${dtc.checks}',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
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

  @override
  void dispose() {
    problemController.dispose();
    super.dispose();
  }
}

class DiagnosisPage extends StatelessWidget {
  final CarBrand brand;
  final CarModel model;
  final Generation generation;
  final Engine? engine;
  final DtcCode? dtc;
  final String problem;

  const DiagnosisPage({
    super.key,
    required this.brand,
    required this.model,
    required this.generation,
    required this.engine,
    required this.dtc,
    required this.problem,
  });

  @override
  Widget build(BuildContext context) {
    final causes = <String>[];

    if (dtc != null && dtc!.causes.isNotEmpty) {
      causes.addAll(
        dtc!.causes
            .split('\n')
            .where((e) => e.trim().isNotEmpty),
      );
    }

    if (causes.isEmpty) {
      causes.addAll([
        'Układ dolotowy',
        'Układ paliwowy',
        'Układ zapłonowy / wtryskowy',
        'Układ sterowania silnikiem',
        'Czujniki silnika',
      ]);
    }

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
                resultCard(
                  'SAMOCHÓD',
                  [
                    '${brand.name} ${model.name}',
                    'Generacja: ${generation.name}',
                    if (engine != null)
                      'Silnik: ${engine!.name} (${engine!.code})',
                    if (engine != null)
                      'Paliwo: ${engine!.fuel}',
                    if (engine?.power != null)
                      'Moc: ${engine!.power} KM',
                  ].join('\n'),
                ),
                resultCard(
                  'OBJAW / PROBLEM',
                  problem,
                ),
                if (dtc != null)
                  resultCard(
                    'KOD DTC',
                    '${dtc!.code}\n${dtc!.description}',
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
                ...causes.map(
                  (cause) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111820),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            cause,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (dtc != null &&
                    dtc!.checks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'CO SPRAWDZIĆ',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  resultCard(
                    'PROCEDURA',
                    dtc!.checks,
                  ),
                ],
                const SizedBox(height: 25),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.orange.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                  child: const Text(
                    'UWAGA: wynik ma charakter pomocniczy. '
                    'Nie zastępuje profesjonalnej diagnostyki '
                    'mechanicznej ani pomiarów pojazdu.',
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Moduł wyszukiwania internetowego '
                            'podłączymy w V4.',
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

  Widget resultCard(
    String title,
    String text,
  ) {
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
}
