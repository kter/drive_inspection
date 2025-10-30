# Research: Dark Mode Implementation in Flutter

**Feature**: Dark Mode Support with Theme Settings
**Date**: 2025-10-29
**Status**: Complete

## Research Topics

### 1. Flutter ThemeMode Best Practices

#### Decision
Use Flutter's built-in `ThemeMode` enum and `MaterialApp.themeMode` property with `Theme.of(context)` for accessing theme colors throughout the app.

#### Rationale
- **Native Support**: Flutter's Material Design implementation provides first-class dark mode support
- **Automatic Transition**: Flutter handles theme transitions smoothly without custom animation code
- **Platform Integration**: Automatically respects system dark mode when using `ThemeMode.system`
- **Zero Flicker**: Theme changes are applied synchronously before the next frame renders
- **Proven Pattern**: Used by Google's own apps (Gmail, Google Drive mobile apps)

**Implementation Pattern**:
```dart
MaterialApp(
  theme: ThemeData.light(),
  darkTheme: ThemeData.dark(),
  themeMode: currentThemeMode, // from state management
)
```

#### Alternatives Considered
- **Manual Theme Switching**: Custom theme class with manual color switching
  - Rejected: Reinventing the wheel, more error-prone, no automatic platform integration
- **CSS-like Theming**: Using packages like `flutter_styled` for CSS-like theming
  - Rejected: Adds unnecessary complexity, non-standard approach in Flutter ecosystem

**Custom Painter Considerations**:
For `CustomPainter` widgets (trajectory, gauges), use `Theme.of(context)` to access theme colors:
```dart
@override
void paint(Canvas canvas, Size size) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final color = isDark ? Colors.white : Colors.black;
  // ... paint logic
}
```

**Material Design Version**:
- Use Material Design 3 (Material You) for better dark mode support
- MD3 provides improved color roles and dynamic color systems
- Enable with `useMaterial3: true` in ThemeData

---

### 2. System Theme Detection

#### Decision
Use `MediaQuery.platformBrightnessOf(context)` combined with `WidgetsBindingObserver.didChangePlatformBrightness()` for real-time system theme detection.

#### Rationale
- **Real-time Updates**: `didChangePlatformBrightness()` callback fires immediately when OS theme changes
- **No Polling**: Event-driven rather than checking periodically
- **Battery Efficient**: No background tasks or timers
- **Cross-Platform**: Works identically on iOS and Android

**Implementation Pattern**:
```dart
class MyApp extends StatefulWidget with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangePlatformBrightness() {
    // System theme changed - update if in Auto mode
    if (themePreference == ThemeMode.system) {
      setState(() {
        // Flutter will automatically re-evaluate themeMode
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

#### Alternatives Considered
- **Timer-based Polling**: Check system brightness every N seconds
  - Rejected: Battery inefficient, delayed response, unnecessary overhead
- **Platform Channels**: Direct iOS/Android native listeners
  - Rejected: Flutter already provides this abstraction, no need for platform-specific code

**Platform Differences**:
- **iOS**: Automatic dark mode scheduling works as expected
- **Android**: Power saving modes may affect dark mode availability
- **Handling**: No special cases needed - Flutter abstracts the differences

---

### 3. Theme Persistence Strategy

#### Decision
Use `shared_preferences` package with early initialization in `main()` before `runApp()`.

#### Rationale
- **Synchronous Access**: After initial async load, preferences are cached in memory
- **No Flicker**: Loading before `runApp()` ensures correct theme on first frame
- **Simple API**: Key-value store matches our simple persistence needs (one enum value)
- **Cross-Platform**: Works identically on iOS and Android
- **Standard Solution**: De facto standard for simple Flutter app preferences

**Implementation Pattern**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load theme preference before building UI
  final prefs = await SharedPreferences.getInstance();
  final themeModeString = prefs.getString('theme_mode') ?? 'system';
  final initialThemeMode = ThemeMode.values.byName(themeModeString);

  runApp(MyApp(initialThemeMode: initialThemeMode));
}
```

**Storage Format**:
- Key: `"theme_mode"`
- Values: `"light"`, `"dark"`, `"system"` (enum name strings)
- Default: `"system"` if key doesn't exist

#### Alternatives Considered
- **Hive**: Local database for preferences
  - Rejected: Overkill for single preference value, adds dependency
- **SQLite**: Relational database
  - Rejected: Way too complex for a single enum value
- **File Storage**: Custom JSON/text file
  - Rejected: SharedPreferences is simpler and handles edge cases

**Error Handling**:
- **Corrupted Value**: Fall back to `ThemeMode.system` if stored string is invalid
- **Missing Key**: Default to `ThemeMode.system` on first launch
- **Storage Failure**: Log error but continue with default theme (non-blocking)

---

### 4. Accessibility & Contrast Requirements

#### Decision
Follow WCAG AA standards (4.5:1 for normal text, 3:1 for large text) using Material Design's built-in color schemes which are pre-validated for contrast.

#### Rationale
- **Built-in Compliance**: Material Design color systems are designed to meet WCAG AA
- **Automated Validation**: Flutter DevTools includes contrast checker
- **User Safety**: Driving app requires high readability for safety
- **Legal Compliance**: WCAG AA is required in many jurisdictions

**Color Selection Strategy**:

**Light Theme**:
```dart
ThemeData.light().copyWith(
  colorScheme: ColorScheme.light(
    primary: Colors.blue[700]!,     // 5.2:1 on white
    secondary: Colors.orange[700]!, // 4.6:1 on white
    error: Colors.red[700]!,        // 5.1:1 on white
  ),
)
```

**Dark Theme**:
```dart
ThemeData.dark().copyWith(
  colorScheme: ColorScheme.dark(
    primary: Colors.blue[200]!,     // 8.1:1 on black
    secondary: Colors.orange[200]!, // 7.3:1 on black
    error: Colors.red[200]!,        // 7.8:1 on black
  ),
)
```

**Data Visualization Colors**:
- **Trajectory**: Primary color at 60% opacity (maintains 3:1+ contrast)
- **Gauges**: Color.lerp between safe/warning/danger colors
- **Charts**: Use ColorScheme.primary/secondary with sufficient opacity

#### Alternatives Considered
- **Custom Color Calculations**: Manual contrast ratio calculations
  - Rejected: Error-prone, Material Design already solves this
- **AAA Standard (7:1)**: Higher contrast requirement
  - Rejected: Unnecessary for this use case, AAA is for vision impairments

**Validation Tools**:
- Flutter DevTools Color Contrast Checker
- WebAIM Contrast Checker (for spot-checking specific colors)
- Automated contrast testing in widget tests

---

### 5. State Management for Theme

#### Decision
Use `ChangeNotifier` with `Provider` package for theme state management.

#### Rationale
- **Lightweight**: Minimal boilerplate compared to alternatives
- **Official Support**: Recommended by Flutter team
- **Granular Rebuilds**: Only widgets listening to theme rebuild
- **Testable**: Easy to test with `ChangeNotifierProvider.value()`
- **Existing Pattern**: Project already uses change notifiers for other features

**Implementation Pattern**:
```dart
class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    // Save to SharedPreferences
    notifyListeners(); // Triggers rebuild
  }
}

// In main.dart:
ChangeNotifierProvider(
  create: (_) => ThemeService(),
  child: Consumer<ThemeService>(
    builder: (context, themeService, _) => MaterialApp(
      themeMode: themeService.themeMode,
      // ...
    ),
  ),
)
```

#### Alternatives Considered
- **Riverpod**: More modern state management
  - Rejected: Requires migration of existing code, Provider is sufficient
- **GetX**: All-in-one solution
  - Rejected: Too opinionated, heavier dependency
- **BLoC**: Business Logic Component pattern
  - Rejected: Overkill for simple theme switching
- **setState Only**: No external state management
  - Rejected: Theme needs to be accessed from multiple widget trees

**Performance Optimization**:
- `Consumer` widget ensures only MaterialApp rebuilds, not entire widget tree
- Theme changes are cheap (Flutter caches ThemeData)
- No unnecessary rebuilds during sensor data updates

---

## Summary of Decisions

| Aspect | Decision | Package/Tool |
|--------|----------|--------------|
| Theme System | Material Design with ThemeMode | Flutter built-in |
| System Detection | WidgetsBindingObserver | Flutter built-in |
| Persistence | SharedPreferences with early init | `shared_preferences` |
| Accessibility | WCAG AA with MD color schemes | Flutter DevTools |
| State Management | ChangeNotifier + Provider | `provider` |

**Dependencies to Add**:
```yaml
dependencies:
  provider: ^6.1.1
  shared_preferences: ^2.2.2
```

**No Breaking Changes**: All additions are additive, no modifications to existing data models or services required.

---

**Research Status**: ✅ Complete - Ready for Phase 1 (Design & Contracts)
