import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:euro_explorer/injection_container.dart' as di;
import 'package:euro_explorer/presentation/pages/countries_page.dart';
import 'package:euro_explorer/presentation/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await di.init();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const EuroExplorerApp());
}

class EuroExplorerApp extends StatelessWidget {
  const EuroExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EuroExplorer',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const CountriesPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
