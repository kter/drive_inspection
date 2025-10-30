import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme management service that handles theme mode preferences,
/// persistence, and state changes throughout the application.
///
/// This service acts as the single source of truth for theme configuration
/// and provides a reactive interface via ChangeNotifier for UI components
/// to respond to theme changes.
///
/// ## Usage Example
///
/// ### 1. Initialize before runApp() in main.dart:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   final themeService = await ThemeService.initialize();
///   runApp(
///     ChangeNotifierProvider.value(
///       value: themeService,
///       child: const MyApp(),
///     ),
///   );
/// }
/// ```
///
/// ### 2. Use in MaterialApp to configure themes:
/// ```dart
/// Consumer<ThemeService>(
///   builder: (context, themeService, _) {
///     final brightness = MediaQuery.platformBrightnessOf(context);
///     return MaterialApp(
///       theme: lightTheme,
///       darkTheme: darkTheme,
///       themeMode: themeService.getEffectiveThemeMode(brightness),
///       home: const HomeScreen(),
///     );
///   },
/// )
/// ```
///
/// ### 3. Access in settings screen to allow user control:
/// ```dart
/// Consumer<ThemeService>(
///   builder: (context, themeService, _) {
///     return RadioListTile<ThemeMode>(
///       title: const Text('Dark Mode'),
///       value: ThemeMode.dark,
///       groupValue: themeService.themeMode,
///       onChanged: (value) => themeService.setThemeMode(value!),
///     );
///   },
/// )
/// ```
///
/// ### 4. Use theme colors in widgets:
/// ```dart
/// Text(
///   'Hello',
///   style: TextStyle(color: Theme.of(context).colorScheme.primary),
/// )
/// ```
class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode;
  final SharedPreferences _prefs;

  /// Storage key for theme preference
  static const String _themeModeKey = 'theme_mode';

  /// Private constructor
  ThemeService._(this._prefs, this._themeMode);

  /// Initialize theme service with saved preferences.
  /// MUST be called before runApp() to avoid initial theme flicker.
  ///
  /// Returns: Initialized ThemeService instance
  /// Throws: Never (uses default on error)
  static Future<ThemeService> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeModeKey);

      ThemeMode initialMode = ThemeMode.system; // Default
      if (savedMode != null) {
        try {
          initialMode = ThemeMode.values.byName(savedMode);
        } catch (e) {
          // Invalid value - use default and clear corrupted data
          debugPrint('ThemeService: Invalid theme mode "$savedMode", using default');
          await prefs.remove(_themeModeKey);
        }
      }

      return ThemeService._(prefs, initialMode);
    } catch (e) {
      // Storage read failure - use default
      debugPrint('ThemeService: Failed to initialize: $e');
      // Create a minimal instance with default settings
      final prefs = await SharedPreferences.getInstance();
      return ThemeService._(prefs, ThemeMode.system);
    }
  }

  /// Get current theme mode preference
  ///
  /// Returns: ThemeMode.light | ThemeMode.dark | ThemeMode.system
  ThemeMode get themeMode => _themeMode;

  /// Resolve effective theme mode based on system brightness.
  /// Used by MaterialApp to determine which theme to apply.
  ///
  /// Params:
  ///   systemBrightness - Current platform brightness from MediaQuery
  ///
  /// Returns: ThemeMode.light | ThemeMode.dark (never system)
  ThemeMode getEffectiveThemeMode(Brightness systemBrightness) {
    if (_themeMode == ThemeMode.system) {
      return systemBrightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light;
    }
    return _themeMode;
  }

  /// Update theme mode preference.
  /// Persists to storage and notifies listeners.
  ///
  /// Params:
  ///   mode - New theme mode (light, dark, or system)
  ///
  /// Returns: Future that completes when persisted
  /// Throws: Never (logs errors)
  Future<void> setThemeMode(ThemeMode mode) async {
    // Early return if mode unchanged (optimization)
    if (_themeMode == mode) return;

    // Update in-memory state
    _themeMode = mode;

    // Notify listeners immediately (optimistic update)
    notifyListeners();

    // Persist to storage
    try {
      await _prefs.setString(_themeModeKey, mode.name);
    } catch (e) {
      // Storage write failure - log error, continue with in-memory state
      debugPrint('ThemeService: Failed to persist theme mode: $e');
    }
  }

  /// Reset theme preference to default (system).
  /// Convenience method equivalent to setThemeMode(ThemeMode.system).
  ///
  /// Returns: Future that completes when persisted
  Future<void> resetToDefault() async {
    await setThemeMode(ThemeMode.system);
  }
}
