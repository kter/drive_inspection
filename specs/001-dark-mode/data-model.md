# Data Model: Dark Mode Theme System

**Feature**: Dark Mode Support with Theme Settings
**Date**: 2025-10-29
**Status**: Design Complete

## Overview

This document defines the data structures and state management for the dark mode feature. The system uses Flutter's built-in `ThemeMode` enum with custom state management through `ChangeNotifier` and persistence via `SharedPreferences`.

## Entity Definitions

### 1. ThemeMode (Flutter Built-in Enum)

**Source**: `package:flutter/material.dart`

```dart
enum ThemeMode {
  /// Use either the light or dark theme based on what the user has selected in
  /// the system settings.
  system,

  /// Always use the light mode regardless of system preference.
  light,

  /// Always use the dark mode regardless of system preference.
  dark,
}
```

**Usage**: Direct usage of Flutter's enum, no custom wrapper needed.

**Persistence Format**: String representation of enum name
- `"system"` → `ThemeMode.system`
- `"light"` → `ThemeMode.light`
- `"dark"` → `ThemeMode.dark`

---

### 2. ThemeService (State Management)

**Purpose**: Manages theme preference persistence and propagates changes to the UI

**Type**: `ChangeNotifier` (extends `flutter:foundation`)

**State Fields**:

```dart
class ThemeService extends ChangeNotifier {
  /// Current theme mode preference (what user selected)
  ThemeMode _themeMode;

  /// SharedPreferences instance for persistence
  final SharedPreferences _prefs;

  /// Storage key for theme preference
  static const String _themeModeKey = 'theme_mode';
}
```

**Computed Properties**:

```dart
/// Get current theme mode preference
ThemeMode get themeMode => _themeMode;

/// Get effective theme mode based on system brightness
/// (resolves 'system' to actual light/dark)
ThemeMode getEffectiveThemeMode(Brightness systemBrightness) {
  if (_themeMode == ThemeMode.system) {
    return systemBrightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;
  }
  return _themeMode;
}
```

**Methods**:

```dart
/// Initialize theme service - loads saved preference
/// Should be called before runApp()
static Future<ThemeService> initialize() async {
  final prefs = await SharedPreferences.getInstance();
  final savedMode = prefs.getString(_themeModeKey);

  ThemeMode initialMode = ThemeMode.system; // Default
  if (savedMode != null) {
    try {
      initialMode = ThemeMode.values.byName(savedMode);
    } catch (e) {
      // Invalid value - use default and clear corrupted data
      await prefs.remove(_themeModeKey);
    }
  }

  return ThemeService._(prefs, initialMode);
}

/// Set theme mode preference and persist
Future<void> setThemeMode(ThemeMode mode) async {
  if (_themeMode == mode) return; // No change

  _themeMode = mode;
  await _prefs.setString(_themeModeKey, mode.name);
  notifyListeners(); // Trigger UI rebuild
}

/// Reset to default (system)
Future<void> resetToDefault() async {
  await setThemeMode(ThemeMode.system);
}
```

**Validation Rules**:
- Theme mode must be one of the three valid `ThemeMode` enum values
- Invalid persisted values are rejected and replaced with default
- Concurrent calls to `setThemeMode()` are safe (async operations queued)

**State Transitions**:

```
Initial State: system (default) or loaded from storage
  ↓
User selects Light → _themeMode = light, persist, notify
  ↓
User selects Dark → _themeMode = dark, persist, notify
  ↓
User selects Auto → _themeMode = system, persist, notify
  ↓
System brightness changes (only affects UI if _themeMode == system)
```

**Error Handling**:
- **Storage Read Failure**: Default to `ThemeMode.system`
- **Storage Write Failure**: Log error, continue with in-memory state only
- **Corrupted Data**: Clear corrupted value, default to `ThemeMode.system`

---

### 3. ThemeData (Flutter Built-in)

**Purpose**: Defines the actual color schemes and visual properties for light and dark themes

**Light Theme Configuration**:

```dart
ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: Colors.blue[700]!,
    secondary: Colors.orange[700]!,
    error: Colors.red[700]!,
    surface: Colors.white,
    background: Colors.grey[50]!,
  ),
  // Custom colors for data visualization
  extensions: <ThemeExtension<dynamic>>[
    DataVisualizationColors(
      trajectoryColor: Colors.blue.withOpacity(0.6),
      gaugeWarning: Colors.orange[600]!,
      gaugeDanger: Colors.red[600]!,
      chartPrimary: Colors.blue[600]!,
      chartSecondary: Colors.orange[600]!,
    ),
  ],
);
```

**Dark Theme Configuration**:

```dart
ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: Colors.blue[200]!,
    secondary: Colors.orange[200]!,
    error: Colors.red[300]!,
    surface: Colors.grey[900]!,
    background: Colors.black,
  ),
  // Custom colors for data visualization
  extensions: <ThemeExtension<dynamic>>[
    DataVisualizationColors(
      trajectoryColor: Colors.blue[200]!.withOpacity(0.7),
      gaugeWarning: Colors.orange[300]!,
      gaugeDanger: Colors.red[300]!,
      chartPrimary: Colors.blue[300]!,
      chartSecondary: Colors.orange[300]!,
    ),
  ],
);
```

**Custom Theme Extension** (for data visualization):

```dart
class DataVisualizationColors extends ThemeExtension<DataVisualizationColors> {
  final Color trajectoryColor;
  final Color gaugeWarning;
  final Color gaugeDanger;
  final Color chartPrimary;
  final Color chartSecondary;

  const DataVisualizationColors({
    required this.trajectoryColor,
    required this.gaugeWarning,
    required this.gaugeDanger,
    required this.chartPrimary,
    required this.chartSecondary,
  });

  @override
  DataVisualizationColors copyWith({
    Color? trajectoryColor,
    Color? gaugeWarning,
    Color? gaugeDanger,
    Color? chartPrimary,
    Color? chartSecondary,
  }) {
    return DataVisualizationColors(
      trajectoryColor: trajectoryColor ?? this.trajectoryColor,
      gaugeWarning: gaugeWarning ?? this.gaugeWarning,
      gaugeDanger: gaugeDanger ?? this.gaugeDanger,
      chartPrimary: chartPrimary ?? this.chartPrimary,
      chartSecondary: chartSecondary ?? this.chartSecondary,
    );
  }

  @override
  DataVisualizationColors lerp(
    ThemeExtension<DataVisualizationColors>? other,
    double t,
  ) {
    if (other is! DataVisualizationColors) return this;
    return DataVisualizationColors(
      trajectoryColor: Color.lerp(trajectoryColor, other.trajectoryColor, t)!,
      gaugeWarning: Color.lerp(gaugeWarning, other.gaugeWarning, t)!,
      gaugeDanger: Color.lerp(gaugeDanger, other.gaugeDanger, t)!,
      chartPrimary: Color.lerp(chartPrimary, other.chartPrimary, t)!,
      chartSecondary: Color.lerp(chartSecondary, other.chartSecondary, t)!,
    );
  }
}
```

**Usage in Widgets**:

```dart
// Standard Material colors
final theme = Theme.of(context);
final primaryColor = theme.colorScheme.primary;
final backgroundColor = theme.colorScheme.background;

// Custom visualization colors
final vizColors = theme.extension<DataVisualizationColors>()!;
final trajectoryColor = vizColors.trajectoryColor;
```

---

## Data Relationships

```
ThemeService (State Management)
  ├── persists to → SharedPreferences
  ├── notifies → Provider Listeners
  └── provides → ThemeMode enum value
                   ↓
              MaterialApp.themeMode
                   ↓
        Selects between lightTheme/darkTheme
                   ↓
              ThemeData (active theme)
                   ↓
        Consumed by widgets via Theme.of(context)
```

---

## Persistence Schema

**Storage Type**: SharedPreferences (key-value store)

**Keys & Values**:

| Key | Type | Values | Default | Notes |
|-----|------|--------|---------|-------|
| `theme_mode` | String | `"light"`, `"dark"`, `"system"` | `"system"` | Enum name |

**Storage Lifecycle**:

1. **App Launch**: Load `theme_mode` from SharedPreferences before `runApp()`
2. **User Changes Theme**: Save to SharedPreferences immediately
3. **App Termination**: No explicit save needed (SharedPreferences persists automatically)

**Migration Strategy**: N/A (new feature, no existing data to migrate)

---

## Validation & Constraints

### ThemeMode Validation

- **Valid Values**: Only `ThemeMode.light`, `ThemeMode.dark`, `ThemeMode.system`
- **Validation Point**: Before persisting to SharedPreferences
- **Invalid Handling**: Reject and use default (`ThemeMode.system`)

### Color Contrast Validation

- **Minimum Ratio**: 4.5:1 for normal text (WCAG AA)
- **Validation Tool**: Flutter DevTools Color Contrast Checker
- **Validation Point**: During theme design (pre-implementation)
- **Affected Elements**: All text, icons, and interactive elements

### Storage Integrity

- **Corruption Handling**: Clear corrupted key, use default value
- **Missing Key**: Treat as first launch, use default
- **Type Mismatch**: Clear and reset to default

---

## Testing Considerations

### Unit Tests

```dart
test('ThemeService initializes with default system mode', () async {
  final service = await ThemeService.initialize();
  expect(service.themeMode, ThemeMode.system);
});

test('ThemeService persists theme mode selection', () async {
  final service = await ThemeService.initialize();
  await service.setThemeMode(ThemeMode.dark);

  // Verify persistence
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.getString('theme_mode'), 'dark');
});

test('ThemeService handles corrupted data gracefully', () async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('theme_mode', 'invalid_mode');

  final service = await ThemeService.initialize();
  expect(service.themeMode, ThemeMode.system); // Falls back to default
});
```

### Widget Tests

```dart
testWidgets('Theme changes propagate to UI', (tester) async {
  final service = await ThemeService.initialize();

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: service,
      child: MyApp(),
    ),
  );

  // Initial theme
  expect(find.byType(MaterialApp), findsOneWidget);

  // Change theme
  service.setThemeMode(ThemeMode.dark);
  await tester.pumpAndSettle();

  // Verify dark theme applied
  final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
  expect(materialApp.themeMode, ThemeMode.dark);
});
```

---

**Data Model Status**: ✅ Complete - Ready for contract definition
