# Tasks: Dark Mode Support with Theme Settings

**Input**: Design documents from `/specs/001-dark-mode/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/theme_service.md

**Tests**: No explicit test requirements found in the specification, so test tasks are omitted per template guidelines.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

This is a Flutter mobile project with the following structure:
- **Source code**: `lib/` at repository root
- **Tests**: `test/` at repository root
- **Platform-specific**: `ios/`, `android/` (no modifications needed for this feature)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add dependencies and create basic structure for theme support

- [x] T001 Add `provider: ^6.1.1` to pubspec.yaml dependencies
- [x] T002 [P] Add `shared_preferences: ^2.2.2` to pubspec.yaml dependencies
- [x] T003 Run `flutter pub get` to install new dependencies
- [x] T004 [P] Create `lib/theme/` directory for theme-related files
- [x] T005 [P] Create `lib/services/` directory if it doesn't exist

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core theme infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 [P] Create DataVisualizationColors theme extension in lib/theme/data_visualization_colors.dart
- [x] T007 [P] Create light theme configuration in lib/theme/light_theme.dart using Material Design 3
- [x] T008 [P] Create dark theme configuration in lib/theme/dark_theme.dart using Material Design 3
- [x] T009 Create ThemeService with ChangeNotifier in lib/services/theme_service.dart implementing the contract
- [x] T010 Add ThemeService.initialize() method with SharedPreferences loading
- [x] T011 [P] Add ThemeService.themeMode getter for current preference
- [x] T012 [P] Add ThemeService.getEffectiveThemeMode(Brightness) method
- [x] T013 Add ThemeService.setThemeMode(ThemeMode) method with persistence and notifyListeners
- [x] T014 [P] Add ThemeService.resetToDefault() method

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Automatic Dark Mode During Night Driving (Priority: P1) 🎯 MVP

**Goal**: Enable app to automatically follow device OS dark mode setting, providing dark theme during night driving without user configuration

**Independent Test**: Enable system dark mode on device and launch app - the app should immediately display with dark color scheme. Switch system setting while app is running - theme should update automatically.

### Implementation for User Story 1

- [x] T015 [US1] Update lib/main.dart to call WidgetsFlutterBinding.ensureInitialized()
- [x] T016 [US1] Initialize ThemeService in main() before runApp() in lib/main.dart
- [x] T017 [US1] Wrap app with ChangeNotifierProvider<ThemeService> in lib/main.dart
- [x] T018 [US1] Create MyApp StatefulWidget with WidgetsBindingObserver mixin in lib/main.dart
- [x] T019 [US1] Add didChangePlatformBrightness() lifecycle method to MyApp in lib/main.dart
- [x] T020 [US1] Update MyApp.build() to use Consumer<ThemeService> in lib/main.dart
- [x] T021 [US1] Configure MaterialApp with themeMode from getEffectiveThemeMode() in lib/main.dart
- [x] T022 [US1] Set MaterialApp.theme to lightTheme and MaterialApp.darkTheme to darkTheme in lib/main.dart
- [x] T023 [US1] Update lib/screens/acceleration_display_screen.dart to use Theme.of(context) colors
- [x] T024 [P] [US1] Update lib/screens/session_history_screen.dart to use Theme.of(context) colors
- [x] T025 [P] [US1] Update lib/screens/sensor_error_screen.dart to use Theme.of(context) colors (if exists)
- [x] T026 [US1] Update lib/widgets/acceleration_gauge.dart CustomPainter to accept theme colors as parameters
- [x] T027 [P] [US1] Update lib/widgets/acceleration_chart.dart to use DataVisualizationColors from theme
- [x] T028 [P] [US1] Update lib/widgets/trajectory_painter.dart CustomPainter to accept trajectoryColor parameter
- [x] T029 [P] [US1] Update lib/widgets/score_display.dart to use Theme.of(context) colors (if exists)
- [x] T030 [P] [US1] Update lib/widgets/loading_state.dart to use Theme.of(context) colors (if exists)

**Checkpoint**: At this point, User Story 1 should be fully functional - app follows system dark mode automatically

---

## Phase 4: User Story 3 - Settings Screen Access (Priority: P2)

**Goal**: Provide intuitive access to theme settings from main screens without disrupting user flow

**Independent Test**: Launch app and locate settings entry point. Tap to navigate to settings screen. Verify back navigation returns to previous screen.

**Note**: Implementing US3 before US2 because the settings screen UI is needed before we can add theme controls to it.

### Implementation for User Story 3

- [x] T031 [US3] Create SettingsScreen StatelessWidget in lib/screens/settings_screen.dart
- [x] T032 [US3] Add AppBar with title "Settings" to SettingsScreen in lib/screens/settings_screen.dart
- [x] T033 [US3] Add back button navigation to SettingsScreen in lib/screens/settings_screen.dart
- [x] T034 [US3] Create placeholder ListTile for theme settings section in lib/screens/settings_screen.dart
- [x] T035 [US3] Add settings icon/button to AppBar of lib/screens/acceleration_display_screen.dart
- [x] T036 [P] [US3] Add settings icon/button to AppBar of lib/screens/session_history_screen.dart (if exists)
- [x] T037 [US3] Implement navigation to SettingsScreen from acceleration_display_screen.dart
- [x] T038 [P] [US3] Implement navigation to SettingsScreen from session_history_screen.dart (if exists)
- [x] T039 [US3] Test navigation flow: main screen → settings → back to main screen

**Checkpoint**: At this point, User Story 3 should be fully functional - settings are accessible and navigable

---

## Phase 5: User Story 2 - Manual Theme Override in Settings (Priority: P2)

**Goal**: Allow users to manually control theme independently from device settings (Light, Dark, or Auto)

**Independent Test**: Navigate to settings and select each theme option (Light, Dark, Auto). Verify app updates immediately. Restart app and verify theme preference persists.

### Implementation for User Story 2

- [x] T040 [US2] Replace placeholder in SettingsScreen with theme selection section in lib/screens/settings_screen.dart
- [x] T041 [US2] Add Consumer<ThemeService> to SettingsScreen for reactive theme state in lib/screens/settings_screen.dart
- [x] T042 [US2] Create RadioListTile for "Light" theme option in lib/screens/settings_screen.dart
- [x] T043 [P] [US2] Create RadioListTile for "Dark" theme option in lib/screens/settings_screen.dart
- [x] T044 [P] [US2] Create RadioListTile for "Auto (Follow System)" theme option in lib/screens/settings_screen.dart
- [x] T045 [US2] Wire RadioListTile onChanged to ThemeService.setThemeMode() in lib/screens/settings_screen.dart
- [x] T046 [US2] Set RadioListTile groupValue to ThemeService.themeMode in lib/screens/settings_screen.dart
- [x] T047 [US2] Add visual feedback for current theme selection in lib/screens/settings_screen.dart
- [x] T048 [US2] Test theme switching: Light → verify light colors, Dark → verify dark colors, Auto → verify follows system
- [x] T049 [US2] Test persistence: change theme, kill app, relaunch → verify theme persisted

**Checkpoint**: All user stories should now be independently functional - complete dark mode feature delivered

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and final quality checks

- [x] T050 [P] Verify all text contrast ratios meet WCAG AA (4.5:1 minimum) using Flutter DevTools
- [x] T051 [P] Test theme transitions during active sensor data collection - verify no flickering or interruption
- [x] T052 [P] Test rapid theme switching - verify app handles gracefully without crashes
- [x] T053 [P] Test theme change while app is in background - verify updates on foreground
- [x] T054 Review and optimize theme-aware CustomPainter widgets for performance
- [x] T055 [P] Add error logging for SharedPreferences failures in ThemeService
- [x] T056 [P] Validate theme initialization timing - ensure < 1 second app launch with correct theme
- [x] T057 Code cleanup: remove any hardcoded colors from all widgets
- [x] T058 Documentation: Add theme usage examples to code comments in ThemeService
- [x] T059 [P] Run `flutter analyze` and fix any theme-related warnings
- [x] T060 [P] Final manual test: Verify all 8 success criteria from spec.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational phase completion
- **User Story 3 (Phase 4)**: Depends on Foundational phase completion (independent of US1)
- **User Story 2 (Phase 5)**: Depends on US3 completion (needs settings screen UI)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1) - Auto Dark Mode**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 3 (P2) - Settings Screen**: Can start after Foundational (Phase 2) - Independent of US1, but US2 needs it
- **User Story 2 (P2) - Manual Override**: Depends on US3 (needs settings screen to place theme controls)

### Within Each User Story

**User Story 1**:
- T015-T022: main.dart initialization (sequential - modifying same file)
- T023-T025: Update screens (can run in parallel - marked [P])
- T026-T030: Update widgets (can run in parallel - marked [P])

**User Story 3**:
- T031-T034: Create SettingsScreen (sequential - same file)
- T035-T036: Add settings icons (can run in parallel - marked [P])
- T037-T038: Add navigation logic (can run in parallel - marked [P])
- T039: Integration test (depends on all above)

**User Story 2**:
- T040-T041: Setup Consumer in SettingsScreen (sequential - same file)
- T042-T044: Create RadioListTiles (can run in parallel - marked [P])
- T045-T047: Wire up event handlers (sequential - same file)
- T048-T049: Integration tests (depends on all above)

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel (T002 with T001, T004-T005 with each other)
- All Foundational tasks marked [P] can run in parallel (T006-T008, T011-T012, T014)
- Within US1: T024-T025, T027-T030 can all run in parallel
- Within US3: T036, T038 can run in parallel with their non-parallel counterparts
- Within US2: T043-T044 can run in parallel with T042
- All Polish tasks marked [P] can run in parallel

---

## Parallel Example: User Story 1 Widgets

```bash
# After completing main.dart setup (T015-T022), launch all widget updates together:
Task: "Update lib/screens/session_history_screen.dart to use Theme.of(context) colors"
Task: "Update lib/screens/sensor_error_screen.dart to use Theme.of(context) colors"
Task: "Update lib/widgets/acceleration_chart.dart to use DataVisualizationColors from theme"
Task: "Update lib/widgets/trajectory_painter.dart CustomPainter to accept trajectoryColor parameter"
Task: "Update lib/widgets/score_display.dart to use Theme.of(context) colors"
Task: "Update lib/widgets/loading_state.dart to use Theme.of(context) colors"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: Foundational (T006-T014) - CRITICAL blocking phase
3. Complete Phase 3: User Story 1 (T015-T030)
4. **STOP and VALIDATE**: Test automatic dark mode with system settings
5. Deploy/demo if ready - users can now benefit from automatic dark mode

**MVP Delivers**: Automatic dark mode that follows OS setting - solves the core night driving problem

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → **Deploy/Demo MVP** (automatic dark mode working!)
3. Add User Story 3 → Test independently → Settings screen accessible
4. Add User Story 2 → Test independently → **Deploy/Demo Full Feature** (manual theme control!)
5. Complete Polish → Final release
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (T001-T014)
2. Once Foundational is done:
   - Developer A: User Story 1 (T015-T030) - Automatic theme
   - Developer B: User Story 3 (T031-T039) - Settings screen
3. Once US3 complete:
   - Developer B: User Story 2 (T040-T049) - Manual override
4. Team completes Polish together (T050-T060)

**Note**: US1 and US3 are fully independent after Foundational phase and can proceed in parallel.

---

## Notes

- [P] tasks = different files, no dependencies - safe to parallelize
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- No test tasks included (not requested in specification)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- ThemeService must be initialized before runApp() to avoid theme flicker (T016)
- All widgets must use Theme.of(context) instead of hardcoded colors
- CustomPainter widgets need theme colors passed as constructor parameters
- Verify WCAG AA contrast (4.5:1) during polish phase (T050)

---

## Success Validation Checklist

After completing all tasks, verify these success criteria from spec.md:

- [x] SC-001: Dark interface appears within 1 second on launch during system dark mode
- [x] SC-002: 100% of screens display correctly in both light and dark themes
- [x] SC-003: Theme transitions complete within 300ms without disrupting data collection
- [x] SC-004: Theme settings accessible within 3 taps from any main screen
- [x] SC-005: Theme preferences persist across 100% of app restarts
- [x] SC-006: All text maintains 4.5:1 contrast ratio in both themes (WCAG AA)
- [x] SC-007: App responds to system theme changes within 1 second when returning from background
- [x] SC-008: Data visualizations maintain full readability in both themes

---

**Generated**: 2025-10-29
**Total Tasks**: 60
**User Stories**: 3 (US1: 16 tasks, US2: 10 tasks, US3: 9 tasks)
**Parallel Opportunities**: 25 tasks marked [P] can run in parallel with others
**MVP Scope**: Phase 1 + Phase 2 + Phase 3 (Tasks T001-T030) = 30 tasks
