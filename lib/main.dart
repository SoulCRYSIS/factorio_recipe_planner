import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/data_manager.dart';
import 'providers/planner_provider.dart';
import 'screens/planner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dataManager = DataManager();
  // In a real app, you might want to show a loading screen instead of awaiting here.
  // But for simplicity, we wait for data load.
  await dataManager.loadData();

  final plannerProvider = PlannerProvider(dataManager);
  
  // Populate initial recipes (limited set for performance safety)
  // plannerProvider.populateAllRecipes();

  runApp(
    MultiProvider(
      providers: [
        Provider<DataManager>.value(value: dataManager),
        ChangeNotifierProvider.value(value: plannerProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Factorio Recipe Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const PlannerScreen(),
    );
  }
}
