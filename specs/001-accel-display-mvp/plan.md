# Implementation Plan: Real-time Acceleration Display MVP

**Branch**: `001-accel-display-mvp` | **Date**: 2025-10-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-accel-display-mvp/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Build a mobile application (iOS & Android) that displays real-time acceleration data from device sensors with visual trajectory visualization. The MVP focuses exclusively on displaying G-force magnitude and direction at 30 Hz update rate, showing the last 10 seconds of acceleration history with trajectory path. This provides the foundation for future driving score calculation and ranking features.

## Technical Context

**Language/Version**: Dart 3.9.2+ with Flutter 3.x (current Flutter stable)
**Primary Dependencies**:
- sensors_plus (^6.0.1) - Cross-platform accelerometer access
- permission_handler (^11.3.1) - Runtime permission management for iOS/Android
- rxdart (^0.28.0) - Stream utilities for backpressure handling
- Built-in CustomPainter - No external visualization library needed

**Storage**: N/A (no data persistence in MVP)
**Testing**: flutter_test (SDK), mockito (^5.4.4) for mocking sensor data
**Target Platform**: iOS 12.0+, Android API 21+ (Android 5.0 Lollipop)
**Project Type**: Mobile (Flutter cross-platform)
**Performance Goals**:
- 30 Hz sensor data processing (33.3ms per update)
- < 100ms latency from sensor reading to display update
- Smooth 60 fps UI rendering during trajectory animation

**Constraints**:
- Must handle sensor updates at 30 Hz without dropped frames
- Trajectory buffer limited to 10 seconds (300 data points at 30 Hz)
- Memory-efficient trajectory rendering for continuous 1-hour operation
- Platform-specific permission handling (iOS Info.plist, Android manifest)

**Scale/Scope**:
- Single-screen MVP application
- ~5-8 core Flutter widgets/screens
- 2-3 core service classes (sensor, permission, data processing)
- Cross-platform deployment (iOS + Android)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Status**: Constitution template not yet populated. Proceeding with standard Flutter best practices:
- **Clean Architecture**: Separation of concerns (UI, business logic, data layer)
- **Testability**: Unit tests for services, widget tests for UI
- **Platform Abstraction**: Use Flutter plugins for cross-platform sensor access
- **Performance**: Efficient state management for high-frequency updates

**No violations identified** - Standard Flutter mobile app architecture applies.

## Project Structure

### Documentation (this feature)

```text
specs/001-accel-display-mvp/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── main.dart                      # App entry point
├── models/
│   ├── acceleration_reading.dart  # Acceleration data model
│   └── trajectory_point.dart      # Trajectory visualization data
├── services/
│   ├── accelerometer_service.dart # Sensor data acquisition
│   └── permission_service.dart    # Permission handling
├── screens/
│   ├── acceleration_display_screen.dart  # Main display screen
│   └── permission_error_screen.dart      # Permission denied UI
└── widgets/
    ├── acceleration_gauge.dart    # G-force magnitude display
    ├── direction_indicator.dart   # Directional arrow/compass
    └── trajectory_painter.dart    # Custom painter for trajectory path

test/
├── models/
│   ├── acceleration_reading_test.dart
│   └── trajectory_point_test.dart
├── services/
│   ├── accelerometer_service_test.dart
│   └── permission_service_test.dart
└── widgets/
    └── acceleration_display_screen_test.dart

ios/
└── Runner/
    └── Info.plist  # NSMotionUsageDescription for sensor permission

android/
└── app/
    └── src/main/
        └── AndroidManifest.xml  # Sensor permissions declaration
```

**Structure Decision**: Standard Flutter mobile project structure with feature-based organization. The `lib/` directory follows a layered architecture pattern:
- **models/**: Pure Dart data classes
- **services/**: Business logic and platform integration
- **screens/**: Top-level page widgets
- **widgets/**: Reusable UI components

This structure supports the mobile-specific requirements (iOS + Android) and aligns with Flutter community best practices.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

N/A - No constitutional violations. Standard Flutter architecture applied.
