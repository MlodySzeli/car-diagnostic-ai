import 'package:flutter/material.dart';

import 'database.dart';
import 'models.dart';
import 'services/dtc_service.dart';
import 'services/internet_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const CarDiagnosticApp(),
  );
}

class CarDiagnosticApp extends StatelessWidget {
  const CarDiagnosticApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Car Diagnostic AI',

      theme: ThemeData(
        useMaterial3: true,

        colorSchemeSeed:
            Colors.blue,

        scaffoldBackgroundColor:
            const Color(0xFFF5F6FA),

        appBarTheme:
            const AppBarTheme(
          centerTitle: true,
        ),
      ),

      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() {
    return _HomePageState();
  }
}

class _HomePageState
    extends State<HomePage> {
  final AppDatabase db =
      AppDatabase.instance;

  late final DtcSearchService
      dtcService =
      DtcSearchService(db);

  final InternetService
      internetService =
      InternetService();

  int currentPage = 0;

  bool loading = true;

  String vehicleQuery = '';
  String dtcQuery = '';
  String internetQuery = '';

  String? selectedVehicle;

  bool dtcSearching = false;

  DtcCode? dtcResult;

  List<VehicleSearchResult>
      vehicleResults = [];

  List<InternetResult>
      internetResults = [];

  @override
  void initState() {
    super.initState();

    initializeApp();
  }

  Future<void> initializeApp() async {
    await db.seedDatabase();

    if (!mounted) {
      return;
    }

    setState(() {
      loading = false;
    });
  }

  void showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> searchVehicles() async {
    final results =
        await db.searchVehicles(
      vehicleQuery,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      vehicleResults = results;
    });
  }

  Future<void> searchDtc() async {
    final query =
        dtcQuery.trim();

    if (query.isEmpty) {
      return;
    }

    setState(() {
      dtcSearching = true;
      dtcResult = null;
    });

    final result =
        await dtcService.findOrSearch(
      query,
      vehicleContext:
          selectedVehicle,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      dtcResult = result;
      dtcSearching = false;
    });

    if (result == null) {
      showMessage(
        'Nie znaleziono automatycznej '
        'odpowiedzi dla tego kodu.',
      );
    }
  }

  Future<void> searchInternet() async {
    final results =
        await internetService.search(
      internetQuery,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      internetResults = results;
    });
  }

  Widget buildSearchField({
    required String label,
    required ValueChanged<String>
        onChanged,
    required VoidCallback onSearch,
  }) {
    return TextField(
      onChanged: onChanged,

      onSubmitted: (_) {
        onSearch();
      },

      decoration: InputDecoration(
        labelText: label,

        prefixIcon:
            const Icon(Icons.search),

        suffixIcon: IconButton(
          icon:
              const Icon(Icons.search),

          onPressed: onSearch,
        ),

        border:
            const OutlineInputBorder(),
      ),
    );
  }

  Widget buildHomePage() {
    return ListView(
      padding:
          const EdgeInsets.all(16),

      children: [
        const SizedBox(height: 10),

        Center(
          child: Icon(
            Icons.car_repair,
            size: 70,
            color:
                Theme.of(context)
                    .colorScheme
                    .primary,
          ),
        ),

        const SizedBox(height: 12),

        Center(
          child: Text(
            'CAR DIAGNOSTIC AI',

            style:
                Theme.of(context)
                    .textTheme
                    .headlineSmall,
          ),
        ),

        const SizedBox(height: 8),

        const Center(
          child: Text(
            'Diagnostyka samochodowa',
          ),
        ),

        const SizedBox(height: 25),

        buildHomeCard(
          icon:
              Icons.directions_car,

          title:
              'Wyszukiwarka pojazdów',

          subtitle:
              'Marka • Model • Generacja • Silnik',

          onTap: () {
            setState(() {
              currentPage = 1;
            });
          },
        ),

        buildHomeCard(
          icon: Icons.build,

          title:
              'Kody błędów DTC',

          subtitle:
              'Lokalna baza i automatyczne wyszukiwanie',

          onTap: () {
            setState(() {
              currentPage = 2;
            });
          },
        ),

        buildHomeCard(
          icon:
              Icons.language,

          title:
              'Wyszukiwanie internetowe',

          subtitle:
              'Informacje techniczne',

          onTap: () {
            setState(() {
              currentPage = 3;
            });
          },
        ),

        buildHomeCard(
          icon:
              Icons.storage,

          title:
              'Baza danych',

          subtitle:
              'Pojazdy i dane diagnostyczne',

          onTap: () {
            setState(() {
              currentPage = 4;
            });
          },
        ),
      ],
    );
  }

  Widget buildHomeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      child: ListTile(
        leading: Icon(
          icon,
          size: 35,
        ),

        title: Text(title),

        subtitle:
            Text(subtitle),

        trailing:
            const Icon(
          Icons.chevron_right,
        ),

        onTap: onTap,
      ),
    );
  }

  Widget buildVehiclePage() {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.all(12),

          child:
              buildSearchField(
            label:
                'Szukaj marki, modelu, generacji lub silnika',

            onChanged: (value) {
              vehicleQuery = value;
            },

            onSearch:
                searchVehicles,
          ),
        ),

        if (selectedVehicle != null)
          Padding(
            padding:
                const EdgeInsets.all(8),

            child: Chip(
              avatar: const Icon(
                Icons.directions_car,
              ),

              label: Text(
                'Wybrany: '
                '$selectedVehicle',
              ),

              onDeleted: () {
                setState(() {
                  selectedVehicle =
                      null;
                });
              },
            ),
          ),

        Expanded(
          child:
              vehicleResults.isEmpty
                  ? const Center(
                      child: Text(
                        'Wyszukaj pojazd',
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.all(
                        12,
                      ),

                      itemCount:
                          vehicleResults
                              .length,

                      itemBuilder:
                          (
                        context,
                        index,
                      ) {
                        final vehicle =
                            vehicleResults[
                                index];

                        final title =
                            '${vehicle.brand} '
                            '${vehicle.model}';

                        final subtitle =
                            '${vehicle.generation}\n'
                            '${vehicle.engine}'
                            '${vehicle.engineCode == null ? '' : ' • ${vehicle.engineCode}'}'
                            '${vehicle.fuel == null ? '' : ' • ${vehicle.fuel}'}'
                            '${vehicle.power == null ? '' : ' • ${vehicle.power} KM'}';

                        return Card(
                          child:
                              ListTile(
                            leading:
                                const Icon(
                              Icons
                                  .directions_car,
                            ),

                            title:
                                Text(title),

                            subtitle:
                                Text(
                              subtitle,
                            ),

                            isThreeLine:
                                true,

                            onTap: () {
                              setState(
                                () {
                                  selectedVehicle =
                                      '$title '
                                      '${vehicle.generation} '
                                      '${vehicle.engine}';
                                },
                              );

                              showMessage(
                                'Pojazd wybrany',
                              );
                            },
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget buildDtcPage() {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.all(12),

          child:
              buildSearchField(
            label:
                'Wpisz kod DTC, np. P0420',

            onChanged: (value) {
              dtcQuery =
                  value.toUpperCase();
            },

            onSearch: searchDtc,
          ),
        ),

        if (selectedVehicle != null)
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
            ),

            child: Text(
              'Kontekst pojazdu: '
              '$selectedVehicle',
            ),
          ),

        if (dtcSearching)
          const Padding(
            padding:
                EdgeInsets.all(20),

            child: Column(
              children: [
                CircularProgressIndicator(),

                SizedBox(height: 12),

                Text(
                  'Sprawdzanie lokalnej bazy...\n'
                  'Jeżeli kodu nie ma, program '
                  'automatycznie szuka w internecie.',
                  textAlign:
                      TextAlign.center,
                ),
              ],
            ),
          ),

        Expanded(
          child: ListView(
            padding:
                const EdgeInsets.all(12),

            children: [
              if (dtcResult != null)
                buildDtcResult(
                  dtcResult!,
                ),

              if (dtcResult == null &&
                  !dtcSearching &&
                  dtcQuery.isNotEmpty)
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        const Text(
                          'Brak wyniku',
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        FilledButton.icon(
                          icon:
                              const Icon(
                            Icons.language,
                          ),

                          label: const Text(
                            'Szukaj dokładniej '
                            'w internecie',
                          ),

                          onPressed: () {
                            internetService
                                .openWebSearch(
                              '$dtcQuery DTC '
                              '${selectedVehicle ?? ''}',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildDtcResult(
    DtcCode dtc,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              dtc.code,

              style:
                  Theme.of(context)
                      .textTheme
                      .headlineMedium,
            ),

            const SizedBox(height: 10),

            Text(
              dtc.description,

              style:
                  Theme.of(context)
                      .textTheme
                      .titleMedium,
            ),

            if (dtc.causes != null &&
                dtc.causes!.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(
                  top: 20,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    const Text(
                      'Możliwe przyczyny',

                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      dtc.causes!,
                    ),
                  ],
                ),
              ),

            if (dtc.checks != null &&
                dtc.checks!.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(
                  top: 20,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    const Text(
                      'Co sprawdzić',

                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      dtc.checks!,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            const Text(
              'Uwaga: informacje znalezione '
              'w internecie należy zawsze '
              'zweryfikować przed naprawą.',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInternetPage() {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.all(12),

          child:
              buildSearchField(
            label:
                'Szukaj informacji technicznych',

            onChanged: (value) {
              internetQuery = value;
            },

            onSearch:
                searchInternet,
          ),
        ),

        Expanded(
          child: ListView(
            padding:
                const EdgeInsets.all(12),

            children: [
              for (final result
                  in internetResults)
                Card(
                  child: ListTile(
                    title:
                        Text(result.title),

                    subtitle: Text(
                      result.text,

                      maxLines: 4,

                      overflow:
                          TextOverflow
                              .ellipsis,
                    ),

                    trailing:
                        const Icon(
                      Icons.open_in_new,
                    ),

                    onTap: () {
                      internetService
                          .openWebSearch(
                        result.title,
                      );
                    },
                  ),
                ),

              if (internetQuery.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 10,
                  ),

                  child:
                      FilledButton.icon(
                    icon:
                        const Icon(
                      Icons.language,
                    ),

                    label: const Text(
                      'Otwórz pełne wyszukiwanie '
                      'w przeglądarce',
                    ),

                    onPressed: () {
                      internetService
                          .openWebSearch(
                        internetQuery,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildDatabasePage() {
    return const Center(
      child: Padding(
        padding:
            EdgeInsets.all(20),

        child: Text(
          'Marki samochodów są niezależne '
          'od kategorii diagnostycznych.\n\n'
          'Struktura pojazdów:\n'
          'Marka → Model → Generacja → Silnik',
          textAlign:
              TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final pages = [
      buildHomePage(),
      buildVehiclePage(),
      buildDtcPage(),
      buildInternetPage(),
      buildDatabasePage(),
    ];

    final titles = [
      'Car Diagnostic AI',
      'Pojazdy',
      'Błędy DTC',
      'Internet',
      'Baza danych',
    ];

    return Scaffold(
      appBar: AppBar(
        title:
            Text(titles[currentPage]),

        leading:
            currentPage == 0
                ? null
                : IconButton(
                    icon:
                        const Icon(
                      Icons.arrow_back,
                    ),

                    onPressed: () {
                      setState(() {
                        currentPage = 0;
                      });
                    },
                  ),
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : pages[currentPage],

      bottomNavigationBar:
          NavigationBar(
        selectedIndex:
            currentPage > 3
                ? 0
                : currentPage,

        onDestinationSelected:
            (index) {
          setState(() {
            currentPage = index;
          });
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Start',
          ),

          NavigationDestination(
            icon:
                Icon(
              Icons.directions_car,
            ),
            label: 'Pojazdy',
          ),

          NavigationDestination(
            icon:
                Icon(Icons.build),
            label: 'DTC',
          ),

          NavigationDestination(
            icon:
                Icon(Icons.language),
            label: 'Internet',
          ),
        ],
      ),
    );
  }
}
