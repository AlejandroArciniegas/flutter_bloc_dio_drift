import 'package:euro_explorer/injection_container.dart' as di;
import 'package:euro_explorer/presentation/pages/countries_page.dart';
import 'package:euro_explorer/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class EuroExplorerApp extends StatefulWidget {
  const EuroExplorerApp({super.key});

  @override
  State<EuroExplorerApp> createState() => _EuroExplorerAppState();
}

class _EuroExplorerAppState extends State<EuroExplorerApp> {
  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EuroExplorer',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const CountriesPage(), // Direct to main app, no splash screen
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Splash screen shown during shader warmup to prevent jank
class ShaderWarmupSplashScreen extends StatelessWidget {
  const ShaderWarmupSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'EuroExplorer',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Optimizing performance...',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary, 
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
