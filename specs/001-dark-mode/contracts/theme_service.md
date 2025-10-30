# Service Contract: ThemeService

**Feature**: Dark Mode Support with Theme Settings
**Service**: ThemeService
**Type**: State Management Service (ChangeNotifier)
**Date**: 2025-10-29

## Overview

`ThemeService` manages theme mode preferences, persistence, and state changes throughout the application. It acts as the single source of truth for theme configuration and provides a reactive interface for UI components to respond to theme changes.

## Responsibilities

1. Load theme preference from persistent storage on initialization
2. Persist theme preference changes to storage
3. Notify listeners when theme changes
4. Resolve "system" theme mode to actual light/dark based on platform brightness
5. Validate theme mode values before persisting

## Public Interface

### Initialization

```dart
/// Initialize theme service with saved preferences
/// MUST be called before runApp() to avoid initial theme flicker
///
/// Returns: Initialized ThemeService instance
/// Throws: Never (uses default on error)
static Future<ThemeService> initialize() async
```

**Behavior**:
- Loads `theme_mode` from SharedPreferences
- If key doesn't exist, defaults to `ThemeMode.system`
- If value is corrupted/invalid, clears it and defaults to `ThemeMode.system`
- Returns ThemeService instance ready for use

**Error Handling**:
- Storage read failure → Log error, use default
- Invalid enum value → Clear storage, use default
- Never throws exceptions to caller

---

### State Access

```dart
/// Get current theme mode preference
///
/// Returns: ThemeMode.light | ThemeMode.dark | ThemeMode.system
ThemeMode get themeMode
```

**Behavior**:
- Returns the user's saved preference (not the effective theme)
- If user selected "Auto", returns `ThemeMode.system`
- Synchronous access (preference is cached in memory)

---

```dart
/// Resolve effective theme mode based on system brightness
/// Used by MaterialApp to determine which theme to apply
///
/// Params:
///   systemBrightness - Current platform brightness from MediaQuery
///
/// Returns: ThemeMode.light | ThemeMode.dark (never system)
ThemeMode getEffectiveThemeMode(Brightness systemBrightness)
```

**Behavior**:
- If `themeMode == ThemeMode.system`:
  - Returns `ThemeMode.dark` if `systemBrightness == Brightness.dark`
  - Returns `ThemeMode.light` if `systemBrightness == Brightness.light`
- Otherwise, returns `themeMode` as-is
- Pure function (no side effects)

**Usage Example**:
```dart
Consumer<ThemeService>(
  builder: (context, themeService, _) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final effectiveMode = themeService.getEffectiveThemeMode(brightness);

    return MaterialApp(
      themeMode: effectiveMode,
      // ...
    );
  },
)
```

---

### State Mutation

```dart
/// Update theme mode preference
/// Persists to storage and notifies listeners
///
/// Params:
///   mode - New theme mode (light, dark, or system)
///
/// Returns: Future that completes when persisted
/// Throws: Never (logs errors)
Future<void> setThemeMode(ThemeMode mode) async
```

**Behavior**:
1. Check if `mode` equals current `_themeMode`
   - If equal, return early (no-op)
2. Update in-memory `_themeMode`
3. Persist to SharedPreferences as `mode.name` string
4. Call `notifyListeners()` to trigger UI rebuilds
5. Return when persistence completes

**Side Effects**:
- Triggers rebuild of all listeners (Provider consumers)
- Writes to disk (SharedPreferences)
- UI transitions to new theme immediately

**Error Handling**:
- Storage write failure → Log error, continue with in-memory state
- Invalid mode → Never occurs (enum type safety)

**Performance**:
- Early return if mode unchanged (optimization)
- Async persistence doesn't block UI updates
- Listeners notified before persistence completes (optimistic update)

---

```dart
/// Reset theme preference to default (system)
/// Convenience method equivalent to setThemeMode(ThemeMode.system)
///
/// Returns: Future that completes when persisted
Future<void> resetToDefault() async
```

**Behavior**:
- Calls `setThemeMode(ThemeMode.system)`
- Same persistence and notification semantics

---

## Events

### Listener Notifications (ChangeNotifier)

```dart
/// Inherited from ChangeNotifier
/// Called automatically after setThemeMode() or resetToDefault()
void notifyListeners()
```

**When Emitted**:
- After `setThemeMode()` updates in-memory state
- Before persistence completes (optimistic update)
- Never emitted if theme mode unchanged

**Listeners Receive**:
- No event data (listeners query `themeMode` getter)
- Triggered via `Provider` / `Consumer` rebuild

---

## Storage Contract

### SharedPreferences Schema

**Key**: `"theme_mode"`

**Values**:
- `"light"` → `ThemeMode.light`
- `"dark"` → `ThemeMode.dark`
- `"system"` → `ThemeMode.system`

**Type**: `String` (enum name)

**Encoding**: `ThemeMode.name` (e.g., `ThemeMode.light.name == "light"`)

**Decoding**: `ThemeMode.values.byName(savedValue)`

**Default**: `"system"` if key missing or invalid

---

## Dependencies

### External Packages

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2  # Persistence
```

**No other service dependencies** - ThemeService is self-contained.

---

## Usage Example

### App Initialization

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme service before runApp
  final themeService = await ThemeService.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: themeService,
      child: const MyApp(),
    ),
  );
}
```

### MaterialApp Integration

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

### Settings Screen Integration

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return RadioListTile<ThemeMode>(
      title: const Text('Light'),
      value: ThemeMode.light,
      groupValue: themeService.themeMode,
      onChanged: (mode) => themeService.setThemeMode(mode!),
    );
  }
}
```

---

## Testing Contract

### Unit Test Requirements

```dart
// MUST pass
test('initialize() loads saved preference')
test('initialize() defaults to system when key missing')
test('initialize() defaults to system when value corrupted')
test('setThemeMode() persists to SharedPreferences')
test('setThemeMode() notifies listeners')
test('setThemeMode() does not notify if mode unchanged')
test('getEffectiveThemeMode() resolves system to light/dark')
test('getEffectiveThemeMode() passes through non-system modes')
test('resetToDefault() sets theme to system')
```

### Integration Test Requirements

```dart
// MUST pass
testWidgets('theme changes propagate to MaterialApp')
testWidgets('theme persists across app restarts')
testWidgets('theme responds to system brightness changes in Auto mode')
testWidgets('theme does not respond to system changes in manual mode')
```

---

## Performance Constraints

- **Initialization**: < 100ms (preference load from disk)
- **Theme Switch**: < 10ms (in-memory + persist async)
- **Listener Notification**: < 5ms (Provider rebuild)
- **Memory**: < 1KB (single enum value cached)

---

## Error Handling Strategy

| Error Condition | Handling | User Impact |
|-----------------|----------|-------------|
| Storage read failure | Log error, use default | Default theme on launch |
| Storage write failure | Log error, continue with in-memory | Theme not persisted |
| Corrupted preference value | Clear and default | Default theme, corruption cleared |
| Concurrent setThemeMode() calls | Queue async operations | All changes applied in order |

**Logging**:
- Use `debugPrint()` for development
- Use `Logger` package for production (if available)
- Never throw exceptions to caller

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-10-29 | Initial contract definition |

---

**Contract Status**: ✅ Approved for Implementation
