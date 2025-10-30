import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/acceleration_display_screen.dart';
import 'services/theme_service.dart';
import 'theme/light_theme.dart';
import 'theme/dark_theme.dart';

void main() async {
  // T015: Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // T016: Initialize ThemeService before runApp to avoid theme flicker
  final themeService = await ThemeService.initialize();

  // T017: Wrap app with ChangeNotifierProvider
  runApp(
    ChangeNotifierProvider.value(
      value: themeService,
      child: const DriveInspectionApp(),
    ),
  );
}

// T018: Convert to StatefulWidget with WidgetsBindingObserver mixin
class DriveInspectionApp extends StatefulWidget {
  const DriveInspectionApp({super.key});

  @override
  State<DriveInspectionApp> createState() => _DriveInspectionAppState();
}

class _DriveInspectionAppState extends State<DriveInspectionApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Register as observer for platform brightness changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Unregister observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // T019: Add didChangePlatformBrightness lifecycle method
  @override
  void didChangePlatformBrightness() {
    // Rebuild to pick up new system brightness
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // T020: Use Consumer<ThemeService> for reactive theme updates
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        final brightness = MediaQuery.platformBrightnessOf(context);

        // T021: Configure MaterialApp with themeMode from getEffectiveThemeMode()
        // T022: Set MaterialApp.theme to lightTheme and darkTheme
        return MaterialApp(
          title: 'Drive Inspection',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeService.getEffectiveThemeMode(brightness),
          home: const AccelerationDisplayScreen(),
        );
      },
    );
  }
}
