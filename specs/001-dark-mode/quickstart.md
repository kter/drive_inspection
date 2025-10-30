# Developer Quickstart: Dark Mode Implementation

**Feature**: Dark Mode Support with Theme Settings
**Date**: 2025-10-29
**Audience**: Developers adding theme support to screens and widgets

## Overview

This guide helps you make your screens and widgets theme-aware in the driving inspection app. The theme system uses Flutter's built-in `ThemeMode` with a `ThemeService` that manages preferences and propagates changes via `Provider`.

## Quick Reference

### Accessing Theme Colors

```dart
// In any widget's build method
final theme = Theme.of(context);

// Standard Material colors
final backgroundColor = theme.colorScheme.background;
final primaryColor = theme.colorScheme.primary;
final textColor = theme.colorScheme.onBackground;
final surfaceColor = theme.colorScheme.surface;

// Custom visualization colors
final vizColors = theme.extension<DataVisualizationColors>()!;
final trajectoryColor = vizColors.trajectoryColor;
final gaugeWarning = vizColors.gaugeWarning;
final gaugeDanger = vizColors.gaugeDanger;
```

### Accessing Theme Service

```dart
// Read-only access (no rebuild on change)
final themeService = context.read<ThemeService>();
final currentMode = themeService.themeMode;

// Reactive access (rebuilds when theme changes)
final themeService = context.watch<ThemeService>();

// Using Consumer for granular rebuilds
Consumer<ThemeService>(
  builder: (context, themeService, child) {
    return Widget(...);
  },
)
```

### Changing Theme

```dart
// From any widget with access to context
final themeService = context.read<ThemeService>();

// Set specific theme
await themeService.setThemeMode(ThemeMode.dark);
await themeService.setThemeMode(ThemeMode.light);

// Reset to system default
await themeService.resetToDefault();
```

---

## Adding Theme Support to New Screens

### Step 1: Use Theme Colors

Replace all hardcoded colors with theme-based colors:

**❌ Before (hardcoded)**:
```dart
class MyNewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: Text('My Screen', style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        color: Colors.grey[100],
        child: Text('Content', style: TextStyle(color: Colors.black)),
      ),
    );
  }
}
```

**✅ After (theme-aware)**:
```dart
class MyNewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text('My Screen'),
      ),
      body: Container(
        color: theme.colorScheme.surface,
        child: Text(
          'Content',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}
```

### Step 2: Use Semantic Color Roles

Material Design 3 provides semantic color roles. Use them for consistent theming:

| Use Case | Color Role | Usage |
|----------|------------|-------|
| Primary actions (buttons, FABs) | `primary` | `theme.colorScheme.primary` |
| Text on primary color | `onPrimary` | `theme.colorScheme.onPrimary` |
| Secondary actions | `secondary` | `theme.colorScheme.secondary` |
| Error states | `error` | `theme.colorScheme.error` |
| Background | `background` | `theme.colorScheme.background` |
| Text on background | `onBackground` | `theme.colorScheme.onBackground` |
| Cards, dialogs | `surface` | `theme.colorScheme.surface` |
| Text on surface | `onSurface` | `theme.colorScheme.onSurface` |

---

## Making Existing Widgets Theme-Aware

### Text Widgets

**❌ Before**:
```dart
Text('Hello', style: TextStyle(color: Colors.black))
```

**✅ After**:
```dart
Text('Hello', style: TextStyle(color: Theme.of(context).colorScheme.onBackground))

// Or use TextTheme (preferred)
Text('Hello', style: Theme.of(context).textTheme.bodyLarge)
```

### Icons

**❌ Before**:
```dart
Icon(Icons.settings, color: Colors.grey[700])
```

**✅ After**:
```dart
Icon(Icons.settings, color: Theme.of(context).iconTheme.color)

// Or explicitly
Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurface)
```

### CustomPainter Widgets

For widgets using `CustomPainter` (trajectory, gauges, charts), you need special handling:

**❌ Before (hardcoded)**:
```dart
class TrajectoryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.6)
      ..strokeWidth = 2.0;
    // ... drawing logic
  }
}
```

**✅ After (theme-aware)**:
```dart
class TrajectoryPainter extends CustomPainter {
  final Color trajectoryColor;

  TrajectoryPainter({required this.trajectoryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = trajectoryColor
      ..strokeWidth = 2.0;
    // ... drawing logic
  }

  @override
  bool shouldRepaint(TrajectoryPainter oldDelegate) {
    return trajectoryColor != oldDelegate.trajectoryColor;
  }
}

// Usage in widget:
@override
Widget build(BuildContext context) {
  final vizColors = Theme.of(context).extension<DataVisualizationColors>()!;

  return CustomPaint(
    painter: TrajectoryPainter(trajectoryColor: vizColors.trajectoryColor),
  );
}
```

### Data Visualization Colors

For gauges, charts, and trajectory visualization, use the custom `DataVisualizationColors` extension:

```dart
@override
Widget build(BuildContext context) {
  final vizColors = Theme.of(context).extension<DataVisualizationColors>()!;

  return CustomPaint(
    painter: AccelerationGaugePainter(
      safeColor: vizColors.chartPrimary,
      warningColor: vizColors.gaugeWarning,
      dangerColor: vizColors.gaugeDanger,
    ),
  );
}
```

**Available Visualization Colors**:
- `trajectoryColor` - Trail color for acceleration trajectory
- `gaugeWarning` - Warning threshold color (medium acceleration)
- `gaugeDanger` - Danger threshold color (high acceleration)
- `chartPrimary` - Primary chart/graph color
- `chartSecondary` - Secondary chart/graph color

---

## Testing Theme Changes Locally

### Manual Testing

1. **Run the app**:
   ```bash
   flutter run
   ```

2. **Test Auto Mode** (default):
   - Change system dark mode setting on device/simulator
   - App should respond immediately without restart
   - iOS: Settings > Display & Brightness > Dark
   - Android: Settings > Display > Dark theme

3. **Test Manual Override**:
   - Open Settings screen in app
   - Select "Light" - verify light theme applied
   - Select "Dark" - verify dark theme applied
   - Select "Auto" - verify follows system setting

4. **Test Persistence**:
   - Change theme to "Dark"
   - Fully quit app (not just background)
   - Relaunch app
   - Verify dark theme is still active

### Automated Widget Tests

Create widget tests that verify theme application:

```dart
testWidgets('Widget displays correctly in light theme', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(),
      home: MyWidget(),
    ),
  );

  // Verify light theme colors
  final container = tester.widget<Container>(find.byType(Container));
  expect(container.color, equals(Colors.white));
});

testWidgets('Widget displays correctly in dark theme', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: MyWidget(),
    ),
  );

  // Verify dark theme colors
  final container = tester.widget<Container>(find.byType(Container));
  expect(container.color, equals(Colors.grey[900]));
});
```

### Testing Theme Switching

```dart
testWidgets('Theme switches update widget colors', (tester) async {
  final themeService = await ThemeService.initialize();

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: themeService,
      child: Consumer<ThemeService>(
        builder: (context, service, _) {
          final brightness = MediaQuery.platformBrightnessOf(context);
          return MaterialApp(
            themeMode: service.getEffectiveThemeMode(brightness),
            theme: lightTheme,
            darkTheme: darkTheme,
            home: MyWidget(),
          );
        },
      ),
    ),
  );

  // Initial theme
  expect(find.text('Light Mode Active'), findsOneWidget);

  // Switch to dark
  themeService.setThemeMode(ThemeMode.dark);
  await tester.pumpAndSettle();

  // Verify dark theme applied
  expect(find.text('Dark Mode Active'), findsOneWidget);
});
```

---

## Verifying Contrast Ratios for New Colors

### WCAG AA Requirements

All text and interactive elements must meet **WCAG AA** standards:
- **Normal text** (< 18pt): 4.5:1 minimum contrast ratio
- **Large text** (≥ 18pt): 3.0:1 minimum contrast ratio
- **Interactive elements**: 3.0:1 minimum contrast ratio

### Using Flutter DevTools

1. **Run app in debug mode**:
   ```bash
   flutter run
   ```

2. **Open DevTools**:
   - Press `v` in terminal, or
   - Open browser at `http://localhost:9100`

3. **Navigate to Inspector tab**

4. **Select widget with text/color**

5. **Check "Highlight Repaint" and color info in details panel**

### Using WebAIM Contrast Checker

For spot-checking specific color combinations:

1. Open [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

2. Extract hex values from your theme:
   ```dart
   // In Flutter DevTools console or code
   print(Colors.blue[700]!.value.toRadixString(16)); // Foreground
   print(Colors.white.value.toRadixString(16));      // Background
   ```

3. Input foreground and background colors

4. Verify passes WCAG AA for normal or large text

### Automated Contrast Testing

Add contrast validation to your widget tests:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double calculateContrastRatio(Color foreground, Color background) {
  // Implementation of WCAG contrast ratio formula
  // (simplified - use a package like `contrast` for production)

  double getLuminance(Color color) {
    return color.computeLuminance();
  }

  final fgLum = getLuminance(foreground);
  final bgLum = getLuminance(background);

  final lighter = max(fgLum, bgLum);
  final darker = min(fgLum, bgLum);

  return (lighter + 0.05) / (darker + 0.05);
}

test('Light theme text has sufficient contrast', () {
  final theme = ThemeData.light();
  final textColor = theme.colorScheme.onBackground;
  final backgroundColor = theme.colorScheme.background;

  final ratio = calculateContrastRatio(textColor, backgroundColor);
  expect(ratio, greaterThanOrEqualTo(4.5),
    reason: 'Text must have 4.5:1 contrast for WCAG AA');
});
```

---

## Troubleshooting Common Theme Issues

### Issue 1: Theme Not Updating on Change

**Symptom**: Changing theme preference doesn't update UI

**Causes & Solutions**:

1. **Widget not listening to ThemeService**:
   ```dart
   // ❌ Wrong - no rebuild on change
   final theme = context.read<ThemeService>();

   // ✅ Correct - rebuilds on change
   final theme = context.watch<ThemeService>();
   ```

2. **MaterialApp not consuming ThemeService**:
   ```dart
   // ✅ Ensure MaterialApp is wrapped in Consumer
   Consumer<ThemeService>(
     builder: (context, themeService, _) {
       final brightness = MediaQuery.platformBrightnessOf(context);
       return MaterialApp(
         themeMode: themeService.getEffectiveThemeMode(brightness),
         theme: lightTheme,
         darkTheme: darkTheme,
         // ...
       );
     },
   )
   ```

### Issue 2: Flicker on App Launch

**Symptom**: Wrong theme briefly shows before correct theme loads

**Solution**: Ensure `ThemeService.initialize()` is called **before** `runApp()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load theme BEFORE building UI
  final themeService = await ThemeService.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: themeService,
      child: const MyApp(),
    ),
  );
}
```

### Issue 3: Custom Colors Not Theming

**Symptom**: CustomPainter or hardcoded colors don't respond to theme

**Solution**: Pass theme colors as constructor parameters:

```dart
// In CustomPainter widget
class MyPainter extends CustomPainter {
  final Color primaryColor;

  MyPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = primaryColor;
    // ...
  }

  @override
  bool shouldRepaint(MyPainter oldDelegate) {
    return primaryColor != oldDelegate.primaryColor;
  }
}

// Usage
@override
Widget build(BuildContext context) {
  return CustomPaint(
    painter: MyPainter(
      primaryColor: Theme.of(context).colorScheme.primary,
    ),
  );
}
```

### Issue 4: Auto Mode Not Responding to System Changes

**Symptom**: Changing OS dark mode doesn't update app in Auto mode

**Solution**: Ensure `MyApp` implements `WidgetsBindingObserver`:

```dart
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // System theme changed - trigger rebuild
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        final brightness = MediaQuery.platformBrightnessOf(context);
        return MaterialApp(
          themeMode: themeService.getEffectiveThemeMode(brightness),
          theme: lightTheme,
          darkTheme: darkTheme,
          home: const AccelerationDisplayScreen(),
        );
      },
    );
  }
}
```

### Issue 5: Theme Not Persisting Across Restarts

**Symptom**: Theme resets to default after app restart

**Causes & Solutions**:

1. **Persistence not awaited**:
   ```dart
   // ❌ Wrong - may not complete before app closes
   void setTheme(ThemeMode mode) {
     themeService.setThemeMode(mode); // Not awaited
   }

   // ✅ Correct - wait for persistence
   Future<void> setTheme(ThemeMode mode) async {
     await themeService.setThemeMode(mode);
   }
   ```

2. **SharedPreferences write failing silently**:
   - Check console for error logs
   - Verify storage permissions on device
   - Test on different device/simulator

---

## Performance Best Practices

### 1. Avoid Unnecessary Rebuilds

Use `Consumer` instead of `context.watch` for localized rebuilds:

```dart
// ❌ Rebuilds entire screen on theme change
@override
Widget build(BuildContext context) {
  final themeService = context.watch<ThemeService>();
  return Scaffold(/* entire screen */);
}

// ✅ Only rebuilds MaterialApp on theme change
@override
Widget build(BuildContext context) {
  return Consumer<ThemeService>(
    builder: (context, themeService, child) {
      return MaterialApp(/* only this rebuilds */);
    },
    child: /* static child not rebuilt */,
  );
}
```

### 2. Cache Theme-Dependent Calculations

If you compute colors or styles based on theme, cache them:

```dart
// ❌ Recomputes every frame
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final gradient = LinearGradient(
    colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
  );
  return Container(decoration: BoxDecoration(gradient: gradient));
}

// ✅ Caches gradient until theme changes
late final LinearGradient _gradient;

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final theme = Theme.of(context);
  _gradient = LinearGradient(
    colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
  );
}

@override
Widget build(BuildContext context) {
  return Container(decoration: BoxDecoration(gradient: _gradient));
}
```

### 3. Use const Widgets Where Possible

```dart
// ✅ Widget doesn't depend on theme - use const
return const Text('Static Text');

// ✅ Even with theme, parts can be const
return Text(
  'Themed Text',
  style: TextStyle(color: Theme.of(context).colorScheme.primary),
);
```

---

## Additional Resources

- **Material Design 3 Color System**: [m3.material.io/styles/color](https://m3.material.io/styles/color)
- **Flutter Theme Documentation**: [docs.flutter.dev/cookbook/design/themes](https://docs.flutter.dev/cookbook/design/themes)
- **WCAG Contrast Guidelines**: [webaim.org/articles/contrast](https://webaim.org/articles/contrast/)
- **Service Contract**: `specs/001-dark-mode/contracts/theme_service.md`
- **Data Model**: `specs/001-dark-mode/data-model.md`

---

**Last Updated**: 2025-10-29
**Status**: Ready for implementation phase
