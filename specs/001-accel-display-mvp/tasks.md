# Tasks: Real-time Acceleration Display MVP

**Input**: Design documents from `/Users/ttakahashi/workspace/drive_inspection/specs/001-accel-display-mvp/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/, research.md, quickstart.md

**Tests**: Tests are NOT explicitly requested in the specification, so test tasks are NOT included. Focus is on implementation and manual device testing.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Flutter mobile project structure: `lib/`, `test/` at repository root
- Platform-specific: `ios/Runner/`, `android/app/src/main/`
- All paths relative to `/Users/ttakahashi/workspace/drive_inspection/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, dependency installation, and platform configuration

- [X] T001 Update pubspec.yaml with required dependencies (sensors_plus: ^6.0.1, permission_handler: ^11.3.1, rxdart: ^0.28.0)
- [X] T002 Run `flutter pub get` to install all dependencies
- [X] T003 [P] Add NSMotionUsageDescription to ios/Runner/Info.plist for motion sensor permission
- [X] T004 [P] Verify Android minimum SDK version (API 21) in android/app/build.gradle
- [X] T005 [P] Create lib/models/ directory for data models
- [X] T006 [P] Create lib/services/ directory for business logic
- [X] T007 [P] Create lib/screens/ directory for top-level pages
- [X] T008 [P] Create lib/widgets/ directory for reusable UI components

**Checkpoint**: Project structure ready, dependencies installed, platform configurations complete

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data models and enums that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T009 [P] Create AccelerationReading model in lib/models/acceleration_reading.dart (x, y, z fields, magnitude calculation, validation)
- [X] T010 [P] Create TrajectoryPoint model in lib/models/trajectory_point.dart (x, y canvas coordinates, timestamp, magnitude)
- [X] T011 [P] Create TrajectoryBuffer service in lib/services/trajectory_buffer.dart (ChangeNotifier, FIFO queue, 300 max points)
- [X] T012 [P] Create PermissionStatus enum in lib/models/permission_status.dart (notDetermined, granted, denied, restricted, permanentlyDenied)
- [X] T013 [P] Create SensorAvailability enum in lib/models/sensor_availability.dart (available, unavailable, malfunctioning, unknown)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - View Real-time Acceleration (Priority: P1) 🎯 MVP

**Goal**: Display real-time G-force magnitude and direction with 10-second trajectory visualization at 30 Hz update rate

**Independent Test**: Launch app on physical device with sensor permission granted, move device in different directions, verify:
- G-force values update ~30 times/second
- Trajectory path displays and updates in real-time
- Stationary device shows ~0g horizontal, ~1g vertical (gravity)
- Trajectory shows last 10 seconds of movement

### Core Services for User Story 1

- [X] T014 [US1] Implement AccelerometerService in lib/services/accelerometer_service.dart (userAccelerometerEvents stream at 30 Hz, RxDart sampling, pause/resume/dispose lifecycle)
- [X] T015 [US1] Add stream error handling and sensor validation to AccelerometerService
- [X] T016 [US1] Implement stream-to-TrajectoryBuffer integration (transform AccelerationReading → TrajectoryPoint with canvas scaling)

### UI Components for User Story 1

- [X] T017 [P] [US1] Create AccelerationGauge widget in lib/widgets/acceleration_gauge.dart (displays magnitude, lateral, longitudinal G-forces with color coding)
- [X] T018 [P] [US1] Create TrajectoryPainter CustomPainter in lib/widgets/trajectory_painter.dart (Path rendering from TrajectoryBuffer, RepaintBoundary optimization)
- [X] T019 [US1] Create AccelerationDisplayScreen in lib/screens/acceleration_display_screen.dart (integrates AccelerationGauge + TrajectoryPainter, WidgetsBindingObserver for lifecycle)

### App Integration for User Story 1

- [X] T020 [US1] Update lib/main.dart to launch AccelerationDisplayScreen as home screen
- [X] T021 [US1] Add lifecycle management to AccelerationDisplayScreen (pause sensors on background, resume on foreground)
- [X] T022 [US1] Add clear trajectory button to AccelerationDisplayScreen AppBar
- [X] T023 [US1] Verify 30 Hz update rate with debug logging (measure actual emission frequency)

**Checkpoint**: At this point, User Story 1 should be fully functional on physical device - real-time acceleration display with trajectory visualization working

---

## Phase 4: User Story 2 - Handle Sensor Permissions (Priority: P1)

**Goal**: Request and manage sensor permissions with clear user guidance when permission is denied

**Independent Test**: Fresh install on iOS device, verify:
- Permission dialog appears with explanation
- Permission denial shows error screen with "Open Settings" option
- Permission granted proceeds to acceleration display
- Settings link opens iOS Settings app

### Services for User Story 2

- [ ] T024 [US2] Implement PermissionService in lib/services/permission_service.dart (checkPermissionStatus, requestPermission, openAppSettings methods)
- [ ] T025 [US2] Add canRequestPermission logic to PermissionService (handles permanentlyDenied, restricted states)

### UI Components for User Story 2

- [ ] T026 [P] [US2] Create PermissionErrorScreen in lib/screens/permission_error_screen.dart (shows error when permission denied, displays instructions)
- [ ] T027 [P] [US2] Create PermissionGateWidget in lib/widgets/permission_gate.dart (wraps app, checks permission before showing main content)
- [ ] T028 [US2] Add "Open Settings" button to PermissionErrorScreen that calls PermissionService.openAppSettings()

### Integration for User Story 2

- [ ] T029 [US2] Update lib/main.dart to wrap AccelerationDisplayScreen with PermissionGateWidget
- [ ] T030 [US2] Add permission request flow to PermissionGateWidget (check status → request if notDetermined → show appropriate screen)
- [ ] T031 [US2] Handle permission state transitions (notDetermined → granted/denied, denied → permanentlyDenied)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work - permission flow prevents app launch without sensor access, clear error messaging guides users

---

## Phase 5: User Story 3 - Handle Sensor Errors (Priority: P2)

**Goal**: Inform users when accelerometer is unavailable or malfunctioning with clear error messages and recovery options

**Independent Test**: Test on device without accelerometer (if available) or simulate sensor failure, verify:
- "Device not compatible" message appears if no sensor
- Error message with retry option appears on sensor malfunction
- Warning appears for unstable sensor readings

### Error Handling for User Story 3

- [ ] T032 [US3] Add sensor availability check to AccelerometerService.initialize() (detect if device has accelerometer)
- [ ] T033 [US3] Implement sensor malfunction detection in AccelerometerService (catch stream errors, detect invalid data patterns)
- [ ] T034 [US3] Add SensorAvailability status tracking to AccelerometerService (available, unavailable, malfunctioning states)

### UI Components for User Story 3

- [ ] T035 [P] [US3] Create SensorErrorScreen in lib/screens/sensor_error_screen.dart (displays error based on SensorAvailability state)
- [ ] T036 [P] [US3] Add retry button to SensorErrorScreen (attempts to reinitialize AccelerometerService)
- [ ] T037 [US3] Create SensorWarningWidget in lib/widgets/sensor_warning.dart (non-blocking warning overlay for unstable readings)

### Integration for User Story 3

- [ ] T038 [US3] Update AccelerationDisplayScreen to handle sensor initialization errors (show SensorErrorScreen on failure)
- [ ] T039 [US3] Add sensor stream error listener to AccelerationDisplayScreen (show SensorWarningWidget on malfunction)
- [ ] T040 [US3] Implement retry logic in SensorErrorScreen (reinitialize service, return to display on success)

**Checkpoint**: All three user stories now complete - comprehensive error handling covers permission denied, sensor unavailable, and sensor malfunctioning scenarios

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories, performance validation, and deployment preparation

- [ ] T041 [P] Add app icon and splash screen for iOS and Android
- [ ] T042 [P] Update app name from "Drive Inspection" to final product name in pubspec.yaml, Info.plist, AndroidManifest.xml
- [ ] T043 Profile app on physical device in release mode (verify 60 fps, < 100ms latency, stable memory)
- [ ] T044 Measure actual sensor update rate on both iOS and Android devices (verify ~30 Hz ±5 Hz)
- [ ] T045 Run 1-hour continuous operation test (verify no crashes, memory stable, battery consumption < 25%)
- [ ] T046 [P] Test trajectory rendering performance (verify smooth updates, no dropped frames at 30 Hz)
- [ ] T047 [P] Verify trajectory buffer FIFO behavior (exactly 10 seconds history, oldest points removed)
- [ ] T048 Test lifecycle management (app pause/resume, background/foreground transitions)
- [ ] T049 [P] Code cleanup and documentation (add kdoc comments to public APIs)
- [ ] T050 Create build configurations for iOS and Android release builds

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion (T001-T008) - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion (T009-T013)
  - User Story 1 (T014-T023): Can start after Foundational
  - User Story 2 (T024-T031): Can start after Foundational, integrates with US1
  - User Story 3 (T032-T040): Can start after Foundational, integrates with US1
- **Polish (Phase 6)**: Depends on all user stories being complete (T014-T040)

### User Story Dependencies

- **User Story 1 (P1)**: Core functionality - NO dependencies on other stories, depends only on Foundational (Phase 2)
- **User Story 2 (P1)**: Wraps User Story 1 with permission gate - depends on US1 existing but independently testable
- **User Story 3 (P2)**: Error handling for User Story 1 - depends on US1 AccelerometerService but independently testable

### Within Each User Story

**User Story 1 Flow**:
1. T014-T016 (Services) BEFORE T017-T019 (UI) - services provide data to UI
2. T017-T018 can run in parallel (different files)
3. T019 depends on T017, T018 (integrates widgets)
4. T020-T023 integrate everything (sequential, depends on T014-T019)

**User Story 2 Flow**:
1. T024-T025 (Service) BEFORE T026-T028 (UI)
2. T026-T027 can run in parallel (different files)
3. T029-T031 integrate everything (sequential)

**User Story 3 Flow**:
1. T032-T034 (enhance AccelerometerService) BEFORE T035-T037 (UI)
2. T035-T036 can run in parallel (different files)
3. T038-T040 integrate everything (sequential)

### Parallel Opportunities

**Setup Phase (T001-T008)**:
- T003 (iOS config) || T004 (Android config) || T005-T008 (directory creation)

**Foundational Phase (T009-T013)**:
- ALL can run in parallel (T009 || T010 || T011 || T012 || T013) - different files, no dependencies

**User Story 1 Models/Widgets (after Foundational)**:
- T017 (AccelerationGauge) || T018 (TrajectoryPainter) - different files

**User Story 2 UI Components (after T024-T025)**:
- T026 (PermissionErrorScreen) || T027 (PermissionGateWidget) - different files

**User Story 3 UI Components (after T032-T034)**:
- T035 (SensorErrorScreen) || T036 (retry button) || T037 (SensorWarningWidget) - can be done in parallel

**Polish Phase (T041-T050)**:
- T041 (icons) || T042 (app name) || T046 (trajectory perf) || T047 (buffer test) || T049 (docs) - independent tasks

---

## Parallel Example: User Story 1

```bash
# After Foundational Phase (T009-T013) completes:

# Launch UI widgets in parallel:
Task T017: "Create AccelerationGauge widget in lib/widgets/acceleration_gauge.dart"
Task T018: "Create TrajectoryPainter CustomPainter in lib/widgets/trajectory_painter.dart"

# Both can be developed simultaneously by different developers or in parallel tool invocations
```

---

## Parallel Example: Multiple User Stories

```bash
# After Foundational Phase completes, if team has 3 developers:

Developer A (or Parallel Task Set 1):
  - T014-T023 (User Story 1 complete)

Developer B (or Parallel Task Set 2):
  - T024-T031 (User Story 2 complete)
  # Note: Will need to integrate with US1 output at T029-T031

Developer C (or Parallel Task Set 3):
  - T032-T040 (User Story 3 complete)
  # Note: Will need to integrate with US1 service at T032-T034
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

**Recommended for initial implementation**:

1. Complete Phase 1: Setup (T001-T008)
2. Complete Phase 2: Foundational (T009-T013) - CRITICAL
3. Complete Phase 3: User Story 1 (T014-T023)
4. **STOP and VALIDATE**: Test on physical iOS and Android devices
   - Verify 30 Hz updates
   - Verify trajectory visualization
   - Verify 10-second history
   - Check performance (60 fps, < 100ms latency)
5. Deploy/demo if ready - this is a working MVP!

### Incremental Delivery (Recommended)

**Build and test each story independently**:

1. **Foundation**: Complete Setup (T001-T008) + Foundational (T009-T013) → verify models and structure
2. **MVP Release**: Add User Story 1 (T014-T023) → Test independently → Deploy/Demo ✅
3. **Permission Flow**: Add User Story 2 (T024-T031) → Test independently → Deploy/Demo ✅
4. **Error Handling**: Add User Story 3 (T032-T040) → Test independently → Deploy/Demo ✅
5. **Polish**: Complete Phase 6 (T041-T050) → Final validation → Production release

**Key advantage**: Each story adds value without breaking previous stories. Can ship MVP after Story 1, then incrementally improve.

### Parallel Team Strategy

**With multiple developers or parallel task execution**:

1. **Together**: Complete Setup (T001-T008) + Foundational (T009-T013)
2. **Parallel Development** (once T013 completes):
   - Stream 1: User Story 1 (T014-T023) - Core MVP
   - Stream 2: User Story 2 (T024-T031) - Permission flow
   - Stream 3: User Story 3 (T032-T040) - Error handling
3. **Integration**: Stories integrate at main.dart and screens - coordinate T029-T031 and T038-T040
4. **Polish**: Team reconvenes for Phase 6 (T041-T050)

---

## Validation Checklist

### After User Story 1 (MVP)
- [ ] App launches on iOS physical device
- [ ] App launches on Android physical device
- [ ] Sensor permission granted successfully (iOS)
- [ ] Acceleration values update in real-time (~30 Hz measured)
- [ ] G-force magnitude displayed accurately
- [ ] Trajectory path renders and updates smoothly
- [ ] Trajectory shows exactly 10 seconds of history
- [ ] App maintains 60 fps during sensor updates
- [ ] Latency < 100ms from movement to display update
- [ ] Clear button resets trajectory
- [ ] App pauses sensors when backgrounded
- [ ] App resumes sensors when foregrounded
- [ ] No crashes during 10-minute operation

### After User Story 2 (Permission Flow)
- [ ] Fresh install shows permission request dialog (iOS)
- [ ] Permission explanation text is clear
- [ ] Permission denial shows error screen
- [ ] "Open Settings" button works (iOS)
- [ ] Permission grant proceeds to acceleration display
- [ ] Android devices skip permission (accelerometer doesn't require it)

### After User Story 3 (Error Handling)
- [ ] Sensor unavailable shows appropriate error message
- [ ] Sensor malfunction triggers error screen
- [ ] Retry button attempts to reinitialize sensor
- [ ] Warning appears for unstable sensor readings
- [ ] Error messages are user-friendly (no technical jargon)

### After Polish (Final Validation)
- [ ] App icon and splash screen present on both platforms
- [ ] App name correctly updated everywhere
- [ ] 1-hour continuous operation test passes
- [ ] Memory usage stable over 1 hour
- [ ] Battery consumption < 25% per hour
- [ ] Performance profiling shows no bottlenecks
- [ ] Code documentation complete
- [ ] Release builds created for iOS and Android

---

## Notes

- **[P] tasks**: Different files, no dependencies - safe to parallelize
- **[Story] label**: Maps task to specific user story for traceability
- **Each user story independently testable**: Can verify functionality without other stories
- **Physical devices required**: Simulators/emulators don't have real accelerometers
- **Platform-specific testing**: Must test on BOTH iOS and Android
- **Performance critical**: Profile in release mode, not debug mode
- **Commit strategy**: Commit after completing each user story phase
- **Stop at checkpoints**: Validate story works independently before proceeding
- **Avoid**: Vague tasks, same-file conflicts between parallel tasks, cross-story dependencies that break independence

---

## Task Count Summary

- **Total Tasks**: 50
- **Setup Phase**: 8 tasks
- **Foundational Phase**: 5 tasks (BLOCKING)
- **User Story 1 (MVP)**: 10 tasks
- **User Story 2**: 8 tasks
- **User Story 3**: 9 tasks
- **Polish Phase**: 10 tasks

**Parallel Opportunities**:
- Setup: 6 parallel tasks (T003-T008)
- Foundational: 5 parallel tasks (T009-T013)
- User Story 1: 2 parallel widgets (T017-T018)
- User Story 2: 2 parallel UI (T026-T027)
- User Story 3: 3 parallel UI (T035-T037)
- Polish: 5 parallel tasks (T041, T042, T046, T047, T049)

**Suggested MVP Scope**: Phase 1 + Phase 2 + Phase 3 (T001-T023) = 23 tasks for working MVP
