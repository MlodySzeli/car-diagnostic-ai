import 'package:flutter/material.dart';

import 'database.dart';
import 'models.dart';

void main() {
  runApp(const CarDiagnosticApp());
}

class CarDiagnosticApp extends StatefulWidget {
  const CarDiagnosticApp({super.key});

  @override
  State<CarDiagnosticApp> createState() => _CarDiagnosticAppState();
}

class _CarDiagnosticAppState extends State<CarDiagnosticApp> {
  bool english = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Car Diagnostic AI v4',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: HomePage(
        english: english,
        onLanguageChanged: () => setState(() => english = !english),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.english,
    required this.onLanguageChanged,
  });

  final bool english;
  final VoidCallback onLanguageChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final db = AppDatabase.instance;

  int page = 0;
  bool loading = true;

  List<CarBrand> brands = [];
  List<CarModel> models = [];
  List<Generation> generations = [];
  List<Engine> engines = [];
  List<Category> categories = [];
  List<Subcategory> subcategories = [];
  List<DtcCode> dtcs = [];

  CarBrand? selectedBrand;
  CarModel? selectedModel;
  Generation? selectedGeneration;
  Category? selectedCategory;

  String searchQuery = '';

  String tr(String pl, String en) => widget.english ? en : pl;

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    if (mounted) setState(() => loading = true);

    await db.seedDatabase();
    final newBrands = await db.getBrands();
    final newCategories = await db.getCategories();
    final newDtcs = await db.getDtcCodes(query: searchQuery);

    if (!mounted) return;

    setState(() {
      brands = newBrands;
      categories = newCategories;
      dtcs = newDtcs;
      loading = false;
    });
  }

  Future<void> selectBrand(CarBrand item) async {
    final result = await db.getModels(item.id!);
    if (!mounted) return;

    setState(() {
      selectedBrand = item;
      models = result;
      selectedModel = null;
      generations = [];
      selectedGeneration = null;
      engines = [];
    });
  }

  Future<void> selectModel(CarModel item) async {
    final result = await db.getGenerations(item.id!);
    if (!mounted) return;

    setState(() {
      selectedModel = item;
      generations = result;
      selectedGeneration = null;
      engines = [];
    });
  }

  Future<void> selectGeneration(Generation item) async {
    final result = await db.getEngines(item.id!);
    if (!mounted) return;

    setState(() {
      selectedGeneration = item;
      engines = result;
    });
  }

  Future<void> selectCategory(Category item) async {
    final result = await db.getSubcategories(item.id!);
    if (!mounted) return;

    setState(() {
      selectedCategory = item;
      subcategories = result;
    });
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> showEditDialog({
    required String title,
    required List<_Field> fields,
    required Future<void> Function(Map<String, String>) onSave,
  }) async {
    final controllers = {
      for (final field in fields)
        field.key: TextEditingController(text: field.value),
    };

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: controllers[field.key],
                      keyboardType:
                          field.number ? TextInputType.number : null,
                      decoration: InputDecoration(
                        labelText: field.label,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tr('Anuluj', 'Cancel')),
            ),
            FilledButton(
              onPressed: () async {
                final values = {
                  for (final entry in controllers.entries)
                    entry.key: entry.value.text.trim(),
                };

                await onSave(values);

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              },
              child: Text(tr('Zapisz', 'Save')),
            ),
          ],
        );
      },
    );

    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Future<void> confirmDelete(String table, int id, String label) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('Usunąć?', 'Delete?')),
        content: Text(
          '$label\n\n${tr(
            'Element i zależne dane zostaną usunięte.',
            'The item and dependent data will be deleted.',
          )}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr('Anuluj', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr('Usuń', 'Delete')),
          ),
        ],
      ),
    );

    if (accepted != true) return;

    await db.remove(table, id);
    if (!mounted) return;

    selectedBrand = null;
    selectedModel = null;
    selectedGeneration = null;
    selectedCategory = null;
    models = [];
    generations = [];
    engines = [];
    subcategories = [];

    await loadAll();
    if (!mounted) return;

    message(tr('Usunięto', 'Deleted'));
  }

  Future<void> editBrand([CarBrand? item]) async {
    await showEditDialog(
      title: item == null
          ? tr('Dodaj markę', 'Add brand')
          : tr('Edytuj markę', 'Edit brand'),
      fields: [
        _Field('name', tr('Nazwa *', 'Name *'), item?.name ?? ''),
      ],
      onSave: (values) async {
        final name = values['name']!;
        if (name.isEmpty) return;

        if (item == null) {
          await db.insert('brands', {'name': name});
        } else {
          await db.update('brands', item.id!, {'name': name});
        }

        await loadAll();
      },
    );
  }

  Future<void> editModel([CarModel? item]) async {
    if (item == null && selectedBrand == null) {
      message(tr('Najpierw wybierz markę', 'Select a brand first'));
      return;
    }

    await showEditDialog(
      title: item == null
          ? tr('Dodaj model', 'Add model')
          : tr('Edytuj model', 'Edit model'),
      fields: [
        _Field('name', tr('Nazwa *', 'Name *'), item?.name ?? ''),
      ],
      onSave: (values) async {
        final name = values['name']!;
        if (name.isEmpty) return;

        final brandId = item?.brandId ?? selectedBrand!.id!;

        if (item == null) {
          await db.insert(
            'models',
            {'brand_id': brandId, 'name': name},
          );
        } else {
          await db.update('models', item.id!, {'name': name});
        }

        if (selectedBrand != null) {
          await selectBrand(selectedBrand!);
        }
      },
    );
  }

  Future<void> editGeneration([Generation? item]) async {
    if (item == null && selectedModel == null) {
      message(tr('Najpierw wybierz model', 'Select a model first'));
      return;
    }

    await showEditDialog(
      title: item == null
          ? tr('Dodaj generację', 'Add generation')
          : tr('Edytuj generację', 'Edit generation'),
      fields: [
        _Field('name', tr('Nazwa *', 'Name *'), item?.name ?? ''),
        _Field(
          'from',
          tr('Rok od (opcjonalnie)', 'Year from (optional)'),
          item?.yearFrom?.toString() ?? '',
          number: true,
        ),
        _Field(
          'to',
          tr('Rok do (opcjonalnie)', 'Year to (optional)'),
          item?.yearTo?.toString() ?? '',
          number: true,
        ),
      ],
      onSave: (values) async {
        final name = values['name']!;
        if (name.isEmpty) return;

        final data = <String, Object?>{
          'name': name,
          'year_from': int.tryParse(values['from']!),
          'year_to': int.tryParse(values['to']!),
        };

        if (item == null) {
          data['model_id'] = selectedModel!.id!;
          await db.insert('generations', data);
        } else {
          await db.update('generations', item.id!, data);
        }

        if (selectedModel != null) {
          await selectModel(selectedModel!);
        }
      },
    );
  }

  Future<void> editEngine([Engine? item]) async {
    if (item == null && selectedGeneration == null) {
      message(tr('Najpierw wybierz generację', 'Select a generation first'));
      return;
    }

    await showEditDialog(
      title: item == null
          ? tr('Dodaj silnik', 'Add engine')
          : tr('Edytuj silnik', 'Edit engine'),
      fields: [
        _Field('name', tr('Nazwa *', 'Name *'), item?.name ?? ''),
        _Field('code', tr('Kod', 'Code'), item?.code ?? ''),
        _Field('fuel', tr('Paliwo', 'Fuel'), item?.fuel ?? ''),
        _Field(
          'displacement',
          tr('Pojemność', 'Displacement'),
          item?.displacement?.toString() ?? '',
          number: true,
        ),
        _Field(
          'power',
          tr('Moc KM', 'Power HP'),
          item?.power?.toString() ?? '',
          number: true,
        ),
      ],
      onSave: (values) async {
        final name = values['name']!;
        if (name.isEmpty) return;

        final data = <String, Object?>{
          'name': name,
          'code': emptyToNull(values['code']!),
          'fuel': emptyToNull(values['fuel']!),
          'displacement': int.tryParse(values['displacement']!),
          'power': int.tryParse(values['power']!),
        };

        if (item == null) {
          data['generation_id'] = selectedGeneration!.id!;
          await db.insert('engines', data);
        } else {
          await db.update('engines', item.id!, data);
        }

        if (selectedGeneration != null) {
          await selectGeneration(selectedGeneration!);
        }
      },
    );
  }

  Future<void> editCategory([Category? item]) async {
    await showEditDialog(
      title: item == null
          ? tr('Dodaj kategorię', 'Add category')
          : tr('Edytuj kategorię', 'Edit category'),
      fields: [
        _Field('name', tr('Nazwa *', 'Name *'), item?.name ?? ''),
      ],
      onSave: (values) async {
        final name = values['name']!;
        if (name.isEmpty) return;

        if (item == null) {
          await db.insert('categories', {'name': name});
        } else {
          await db.update('categories', item.id!, {'name': name});
        }

        await loadAll();
      },
    );
  }

  Future<void> editSubcategory([Subcategory? item]) async {
    if (item == null && selectedCategory == null) {
      message(tr('Najpierw wybierz kategorię', 'Select a category first'));
      return;
    }

    await showEditDialog(
      title: item == null
          ? tr('Dodaj podkategorię', 'Add subcategory')
          : tr('Edytuj podkategorię', 'Edit subcategory'),
      fields: [
        _Field('name', tr('Nazwa *', 'Name *'), item?.name ?? ''),
      ],
      onSave: (values) async {
        final name = values['name']!;
        if (name.isEmpty) return;

        if (item == null) {
          await db.insert(
            'subcategories',
            {'category_id': selectedCategory!.id!, 'name': name},
          );
        } else {
          await db.update('subcategories', item.id!, {'name': name});
        }

        if (selectedCategory != null) {
          await selectCategory(selectedCategory!);
        }
      },
    );
  }

  Future<void> editDtc([DtcCode? item]) async {
    await showEditDialog(
      title: item == null
          ? tr('Dodaj błąd DTC', 'Add DTC code')
          : tr('Edytuj błąd DTC', 'Edit DTC code'),
      fields: [
        _Field('code', tr('Kod *', 'Code *'), item?.code ?? ''),
        _Field(
          'description',
          tr('Opis domyślny *', 'Default description *'),
          item?.description ?? '',
        ),
        _Field(
          'pl',
          tr('Opis po polsku', 'Polish description'),
          item?.descriptionPl ?? '',
        ),
        _Field(
          'en',
          tr('Opis po angielsku', 'English description'),
          item?.descriptionEn ?? '',
        ),
        _Field('causes', tr('Przyczyny', 'Causes'), item?.causes ?? ''),
        _Field('checks', tr('Sprawdzenie', 'Checks'), item?.checks ?? ''),
      ],
      onSave: (values) async {
        if (values['code']!.isEmpty ||
            values['description']!.isEmpty) {
          return;
        }

        final data = <String, Object?>{
          'code': values['code'],
          'description': values['description'],
          'description_pl': emptyToNull(values['pl']!),
          'description_en': emptyToNull(values['en']!),
          'causes': emptyToNull(values['causes']!),
          'checks': emptyToNull(values['checks']!),
        };

        if (item == null) {
          await db.insert('dtc_codes', data);
        } else {
          await db.update('dtc_codes', item.id!, data);
        }

        await loadAll();
      },
    );
  }

  String? emptyToNull(String value) {
    return value.trim().isEmpty ? null : value.trim();
  }

  Widget actionItem({
    required String text,
    required VoidCallback onTap,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return ListTile(
      title: Text(text),
      onTap: onTap,
      trailing: Wrap(
        children: [
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Widget section(
    String title,
    List<Widget> children,
    VoidCallback onAdd,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget vehiclesPage() {
    final widgets = <Widget>[
      section(
        tr('Marki', 'Brands'),
        brands
            .map(
              (item) => actionItem(
                text: item.name,
                onTap: () => selectBrand(item),
                onEdit: () => editBrand(item),
                onDelete: () =>
                    confirmDelete('brands', item.id!, item.name),
              ),
            )
            .toList(),
        () => editBrand(),
      ),
    ];

    if (selectedBrand != null) {
      widgets.add(
        section(
          '${tr('Modele', 'Models')} — ${selectedBrand!.name}',
          models
              .map(
                (item) => actionItem(
                  text: item.name,
                  onTap: () => selectModel(item),
                  onEdit: () => editModel(item),
                  onDelete: () =>
                      confirmDelete('models', item.id!, item.name),
                ),
              )
              .toList(),
          () => editModel(),
        ),
      );
    }

    if (selectedModel != null) {
      widgets.add(
        section(
          '${tr('Generacje', 'Generations')} — ${selectedModel!.name}',
          generations
              .map(
                (item) => actionItem(
                  text: '${item.name}'
                      '${item.yearFrom == null ? '' : ' (${item.yearFrom}-${item.yearTo ?? ''})'}',
                  onTap: () => selectGeneration(item),
                  onEdit: () => editGeneration(item),
                  onDelete: () =>
                      confirmDelete('generations', item.id!, item.name),
                ),
              )
              .toList(),
          () => editGeneration(),
        ),
      );
    }

    if (selectedGeneration != null) {
      widgets.add(
        section(
          '${tr('Silniki', 'Engines')} — ${selectedGeneration!.name}',
          engines
              .map(
                (item) => actionItem(
                  text: '${item.name}${item.code == null ? '' : ' — ${item.code}'}',
                  onTap: () {},
                  onEdit: () => editEngine(item),
                  onDelete: () =>
                      confirmDelete('engines', item.id!, item.name),
                ),
              )
              .toList(),
          () => editEngine(),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: widgets,
    );
  }

  Widget categoriesPage() {
    final widgets = <Widget>[
      section(
        tr('Kategorie', 'Categories'),
        categories
            .map(
              (item) => actionItem(
                text: item.name,
                onTap: () => selectCategory(item),
                onEdit: () => editCategory(item),
                onDelete: () =>
                    confirmDelete('categories', item.id!, item.name),
              ),
            )
            .toList(),
        () => editCategory(),
      ),
    ];

    if (selectedCategory != null) {
      widgets.add(
        section(
          '${tr('Podkategorie', 'Subcategories')} — ${selectedCategory!.name}',
          subcategories
              .map(
                (item) => actionItem(
                  text: item.name,
                  onTap: () {},
                  onEdit: () => editSubcategory(item),
                  onDelete: () =>
                      confirmDelete('subcategories', item.id!, item.name),
                ),
              )
              .toList(),
          () => editSubcategory(),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: widgets,
    );
  }

  Widget dtcPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (value) async {
              searchQuery = value;
              final result = await db.getDtcCodes(query: searchQuery);
              if (!mounted) return;
              setState(() => dtcs = result);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: tr(
                'Szukaj kodu lub opisu',
                'Search code or description',
              ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: dtcs.length,
            itemBuilder: (context, index) {
              final item = dtcs[index];
              final description = widget.english
                  ? (item.descriptionEn ?? item.description)
                  : (item.descriptionPl ?? item.description);

              final details = <String>[
                if (item.causes != null && item.causes!.isNotEmpty)
                  item.causes!,
                if (item.checks != null && item.checks!.isNotEmpty)
                  item.checks!,
              ];

              return Card(
                child: ListTile(
                  title: Text('${item.code} — $description'),
                  subtitle: details.isEmpty
                      ? null
                      : Text(details.join('\n')),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        onPressed: () => editDtc(item),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () =>
                            confirmDelete('dtc_codes', item.id!, item.code),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      tr('Pojazdy', 'Vehicles'),
      tr('Kategorie', 'Categories'),
      tr('Błędy DTC', 'DTC codes'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Car Diagnostic AI v4 — ${titles[page]}'),
        actions: [
          IconButton(
            onPressed: widget.onLanguageChanged,
            icon: const Icon(Icons.language),
            tooltip: widget.english ? 'Polski' : 'English',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: page,
              children: [
                vehiclesPage(),
                categoriesPage(),
                dtcPage(),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (value) {
          setState(() => page = value);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.directions_car),
            label: titles[0],
          ),
          NavigationDestination(
            icon: const Icon(Icons.category),
            label: titles[1],
          ),
          NavigationDestination(
            icon: const Icon(Icons.build),
            label: titles[2],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (page == 0) {
            editBrand();
          } else if (page == 1) {
            editCategory();
          } else {
            editDtc();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(tr('Dodaj', 'Add')),
      ),
    );
  }
}

class _Field {
  const _Field(
    this.key,
    this.label,
    this.value, {
    this.number = false,
  });

  final String key;
  final String label;
  final String value;
  final bool number;
}
