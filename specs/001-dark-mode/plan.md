# Implementation Plan: Dark Mode Support with Theme Settings

**Branch**: `001-dark-mode` | **Date**: 2025-10-29 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-dark-mode/spec.md`

## Summary

Implement dark mode support for the driving inspection app to reduce eye strain and improve safety during night driving. The system will automatically follow the device's OS dark mode setting by default, with manual override options (Light, Dark, Auto) accessible through a new settings screen. Theme changes must apply immediately without app restart and maintain readability across all UI elements including real-time acceleration visualizations.

**Technical Approach**: Leverage Flutter's built-in ThemeMode and Theme system with reactive state management (ChangeNotifier/Provider) for theme switching. Use SharedPreferences for theme preference persistence. Detect system theme changes via MediaQuery.platformBrightnessOf with WidgetsBindingObserver lifecycle hooks.

## Technical Context

**Language/Version**: Dart 3.9.2 / Flutter SDK 3.24+
**Primary Dependencies**:
- Flutter Material Design (built-in theming)
- shared_preferences (theme preference persistence)
- provider (state management for theme changes)

**Storage**: SharedPreferences for theme mode preference (key-value store)
**Testing**: flutter test (widget tests, integration tests)
**Target Platform**: iOS 15+ and Android 8.0+
**Project Type**: Mobile (Flutter single codebase)
**Performance Goals**:
- Theme switch < 300ms
- App launch with correct theme < 1 second
- Zero UI flickering during theme transitions

**Constraints**:
- Must not interrupt ongoing sensor data collection during theme switches
- 4.5:1 minimum contrast ratio (WCAG AA) for all text
- Smooth transitions without janky animations or layout shifts

**Scale/Scope**:
- 4 screens total (acceleration display, session history, settings, error screens)
- ~10 custom widgets requiring theme-aware colors
- 2 color schemes (light + dark)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Note**: The project constitution file is currently a template and has not been customized with project-specific principles. No constitution gates can be evaluated at this time.

**Recommendations for Constitution**:
1. Consider defining principles around UI/UX consistency
2. Establish testing requirements for theme changes
3. Define accessibility standards (e.g., WCAG AA minimum)

**Status**: ✅ **PASSED** (No constitution gates defined)

## Project Structure

### Documentation (this feature)

```text
specs/001-dark-mode/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: Best practices research
├── data-model.md        # Phase 1: Theme preference data model
├── quickstart.md        # Phase 1: Developer onboarding guide
├── contracts/           # Phase 1: Service contracts
│   └── theme_service.md # Theme management contract
└── checklists/
    └── requirements.md  # Specification validation (completed)
```

### Source Code (repository root)

```text
lib/
├── models/
│   └── theme_preference.dart      # NEW: Theme mode enum and preference model
├── services/
│   └── theme_service.dart          # NEW: Theme management service
├── screens/
│   ├── acceleration_display_screen.dart  # MODIFIED: Theme-aware colors
│   ├── session_history_screen.dart       # MODIFIED: Theme-aware colors
│   ├── sensor_error_screen.dart          # MODIFIED: Theme-aware colors
│   └── settings_screen.dart              # NEW: Settings screen with theme selector
├── widgets/
│   ├── acceleration_gauge.dart           # MODIFIED: Theme-aware visualization
│   ├── acceleration_chart.dart           # MODIFIED: Theme-aware chart colors
│   ├── trajectory_painter.dart           # MODIFIED: Theme-aware trajectory colors
│   ├── score_display.dart                # MODIFIED: Theme-aware colors
│   └── loading_state.dart                # MODIFIED: Theme-aware colors
└── main.dart                              # MODIFIED: MaterialApp theme configuration

test/
├── models/
│   └── theme_preference_test.dart        # NEW: Unit tests for model
├── services/
│   └── theme_service_test.dart           # NEW: Unit tests for service
├── screens/
│   └── settings_screen_test.dart         # NEW: Widget tests
└── integration/
    └── theme_switching_test.dart         # NEW: Integration tests for theme changes
```

**Structure Decision**: This is a Flutter mobile application following the standard single-project structure. The app uses a feature-based organization with `/models`, `/services`, `/screens`, and `/widgets` directories. Theme support will be added as a cross-cutting concern affecting all visual layers.

## Complexity Tracking

**No constitutional violations to justify** - the constitution is not yet defined for this project.

## Phase 0: Outline & Research

### Research Topics

Based on the Technical Context unknowns and feature requirements, the following research is needed:

1. **Flutter ThemeMode Best Practices**
   - How to implement smooth theme transitions without UI flicker
   - Best practices for theme-aware CustomPainter widgets (trajectory, gauges, charts)
   - Material Design 3 vs Material Design 2 for dark mode implementation

2. **System Theme Detection**
   - How to detect OS dark mode changes in real-time using MediaQuery
   - WidgetsBindingObserver lifecycle integration for background/foreground theme sync
   - Platform-specific behavior differences (iOS vs Android)

3. **Theme Persistence Strategy**
   - SharedPreferences best practices for theme preference storage
   - When to initialize theme on app startup vs first screen load
   - Error handling for corrupted/missing preferences

4. **Accessibility & Contrast Requirements**
   - WCAG AA contrast ratio guidelines for mobile apps
   - Tools/methods to validate contrast ratios during development
   - Color palette selection for data visualizations in dark mode

5. **State Management for Theme**
   - Provider vs Riverpod vs GetX for theme state management
   - How to propagate theme changes to all widgets efficiently
   - Avoiding unnecessary rebuilds during theme switches

### Research Output

**Output File**: `specs/001-dark-mode/research.md`

The research phase will consolidate findings for each topic with:
- **Decision**: What approach/tool was chosen
- **Rationale**: Why this choice is best for the project
- **Alternatives Considered**: What else was evaluated and why rejected

## Phase 1: Design & Contracts

### Data Model

**Output File**: `specs/001-dark-mode/data-model.md`

Key entities to model:

1. **ThemePreference**
   - Fields: themeMode (enum: light/dark/system), lastModified
   - Validation: themeMode must be one of the three valid options
   - Persistence: SharedPreferences with key "theme_mode"

2. **ThemeColors** (Color Scheme)
   - Light Mode Palette: background, surface, primary, secondary, error, text colors
   - Dark Mode Palette: corresponding dark theme colors
   - Data Visualization Colors: trajectory, gauge, chart colors for both themes

3. **ThemeState** (Runtime State)
   - Current effective theme (resolved from preference + system setting)
   - System brightness (light/dark from OS)
   - User preference override (if any)

### Service Contracts

**Output Directory**: `specs/001-dark-mode/contracts/`

#### ThemeService Contract

**File**: `theme_service.md`

```text
ThemeService
  Methods:
    - initialize(): Future<void>
      → Loads saved preference from storage
      → Sets initial theme based on preference + system setting
      → Returns: void

    - getCurrentThemeMode(): ThemeMode
      → Returns: Current effective theme mode (light/dark)

    - getThemePreference(): ThemeMode
      → Returns: User's saved preference (light/dark/system)

    - setThemePreference(ThemeMode): Future<void>
      → Validates input is valid ThemeMode
      → Saves preference to persistent storage
      → Notifies listeners of theme change
      → Returns: void

    - getEffectiveTheme(Brightness): ThemeMode
      → Input: system brightness
      → Returns: Resolved theme mode based on preference + system

  Events (ChangeNotifier):
    - notifyListeners()
      → Emitted when theme changes
      → Triggers widget rebuilds consuming the theme

  Storage:
    - Key: "theme_mode"
    - Values: "light" | "dark" | "system"
    - Location: SharedPreferences
```

### Developer Quickstart

**Output File**: `specs/001-dark-mode/quickstart.md`

Contents:
- How to add theme support to new screens
- How to make existing widgets theme-aware
- Testing theme changes locally
- Verifying contrast ratios for new colors
- Troubleshooting common theme issues

### Agent Context Update

After completing Phase 1, run:
```bash
.specify/scripts/bash/update-agent-context.sh claude
```

This will update the Claude-specific context file with:
- New dependencies: shared_preferences, provider
- New patterns: ThemeMode usage, theme-aware widgets
- Testing approach for theme switching

## Phase 2: Task Generation

**Not executed by `/speckit.plan`** - use `/speckit.tasks` command separately.

The task generation will create a dependency-ordered `tasks.md` file breaking down the implementation into:
1. Setup & Infrastructure tasks
2. Model & Service implementation
3. UI Migration tasks (screen by screen)
4. Testing tasks
5. Documentation tasks

---

**Plan Status**: Ready for Phase 0 research execution
