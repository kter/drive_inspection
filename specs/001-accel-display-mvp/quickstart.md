# Quickstart Guide: Real-time Acceleration Display MVP

**Feature**: 001-accel-display-mvp
**Date**: 2025-10-26
**Audience**: Developers implementing this feature

---

## Overview

This guide provides step-by-step instructions to implement the real-time acceleration display MVP for iOS and Android using Flutter. The implementation focuses on displaying G-force data at 30 Hz with a 10-second trajectory visualization.

**Estimated Implementation Time**: 8-12 hours for experienced Flutter developer

---

## Prerequisites

### Development Environment

**Required**:
- Flutter SDK 3.x+ (current stable)
- Dart 3.9.2+
- Xcode 14+ (for iOS development)
- Android Studio with SDK 21+ (for Android development)

**Verify installation**:
```bash
flutter doctor -v
dart --version
```

### Physical Devices

**CRITICAL**: Simulators/emulators do not have real accelerometers!

Required for testing:
- iOS device (iPhone with iOS 12.0+)
- Android device (API 21+, Android 5.0 Lollipop)

---

## Step 1: Project Setup (15 minutes)

### 1.1 Update pubspec.yaml

Add dependencies to `/Users/ttakahashi/workspace/drive_inspection/pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # NEW: Sensor and permission dependencies
  sensors_plus: ^6.0.1
  permission_handler: ^11.3.1
  rxdart: ^0.28.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

  # NEW: Testing dependencies
  mockito: ^5.4.4
  mocktail: ^1.0.0
  build_runner: ^2.4.0
```

**Install dependencies**:
```bash
cd /Users/ttakahashi/workspace/drive_inspection
flutter pub get
```

### 1.2 Platform-Specific Configuration

**iOS** - Edit `ios/Runner/Info.plist`:

```xml
<dict>
  <!-- Existing keys... -->

  <!-- ADD THIS: Motion sensor permission -->
  <key>NSMotionUsageDescription</key>
  <string>This app monitors vehicle acceleration for driving analysis.</string>
</dict>
```

**Android** - No additional configuration needed for accelerometer.

Verify minimum SDK in `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Already set
    }
}
```

---

## Step 2: Create Data Models (30 minutes)

### 2.1 Create models directory

```bash
mkdir -p lib/models
```

### 2.2 Create AccelerationReading model

File: `lib/models/acceleration_reading.dart`

```dart
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class AccelerationReading {
  final double x;          // m/s²
  final double y;          // m/s²
  final double z;          // m/s²
  final DateTime timestamp;

  AccelerationReading({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  }) {
    assert(!x.isNaN && !x.isInfinite, 'X must be finite');
    assert(!y.isNaN && !y.isInfinite, 'Y must be finite');
    assert(!z.isNaN && !z.isInfinite, 'Z must be finite');
  }

  /// Create from sensors_plus AccelerometerEvent
  factory AccelerationReading.fromEvent(AccelerometerEvent event) {
    return AccelerationReading(
      x: event.x,
      y: event.y,
      z: event.z,
      timestamp: DateTime.now(),
    );
  }

  /// Total acceleration magnitude in G-forces (1g = 9.81 m/s²)
  double get magnitude {
    return sqrt(x * x + y * y + z * z) / 9.81;
  }

  /// Lateral G-force (left/right)
  double get lateralG => x / 9.81;

  /// Longitudinal G-force (forward/backward)
  double get longitudinalG => y / 9.81;

  /// Vertical G-force (up/down)
  double get verticalG => z / 9.81;

  bool get isValid => !x.isNaN && !y.isNaN && !z.isNaN;
}
```

### 2.3 Create TrajectoryPoint model

File: `lib/models/trajectory_point.dart`

```dart
class TrajectoryPoint {
  final double x;          // Canvas position
  final double y;          // Canvas position
  final DateTime timestamp;
  final double magnitude;   // For color coding

  TrajectoryPoint({
    required this.x,
    required this.y,
    required this.timestamp,
    required this.magnitude,
  });

  /// Create from AccelerationReading with canvas scaling
  factory TrajectoryPoint.fromReading(
    AccelerationReading reading,
    double scaleX,
    double scaleY,
    double centerX,
    double centerY,
  ) {
    return TrajectoryPoint(
      x: centerX + (reading.x * scaleX),
      y: centerY - (reading.y * scaleY), // Invert Y for canvas
      timestamp: reading.timestamp,
      magnitude: reading.magnitude,
    );
  }
}
```

---

## Step 3: Create Services (1-2 hours)

### 3.1 Create services directory

```bash
mkdir -p lib/services
```

### 3.2 Create AccelerometerService

File: `lib/services/accelerometer_service.dart`

```dart
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:rxdart/rxdart.dart';
import '../models/acceleration_reading.dart';

class AccelerometerService {
  StreamSubscription? _subscription;
  final _controller = StreamController<AccelerationReading>.broadcast();

  Stream<AccelerationReading> get stream => _controller.stream;

  bool _isInitialized = false;
  bool _isPaused = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _subscription = userAccelerometerEvents(
        samplingPeriod: const Duration(milliseconds: 33), // 30 Hz
      )
      // Sample to prevent buffering
      .sample(const Duration(milliseconds: 33))
      .map((event) => AccelerationReading.fromEvent(event))
      .where((reading) => reading.isValid)
      .listen(
        (reading) => _controller.add(reading),
        onError: (error) => _controller.addError(error),
        cancelOnError: false,
      );

      _isInitialized = true;
    } catch (e) {
      _controller.addError(Exception('Failed to initialize sensor: $e'));
      rethrow;
    }
  }

  void pause() {
    if (!_isPaused) {
      _subscription?.pause();
      _isPaused = true;
    }
  }

  void resume() {
    if (_isPaused) {
      _subscription?.resume();
      _isPaused = false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
    _isInitialized = false;
  }
}
```

### 3.3 Create PermissionService

File: `lib/services/permission_service.dart`

```dart
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<PermissionStatus> checkPermissionStatus() async {
    // On Android, sensors don't require permission - always granted
    // On iOS, check motion sensor permission
    return await Permission.sensors.status;
  }

  Future<PermissionStatus> requestPermission() async {
    return await Permission.sensors.request();
  }

  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  bool canRequestPermission(PermissionStatus status) {
    return status != PermissionStatus.granted &&
           status != PermissionStatus.permanentlyDenied &&
           status != PermissionStatus.restricted;
  }
}
```

### 3.4 Create TrajectoryBuffer

File: `lib/services/trajectory_buffer.dart`

```dart
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/trajectory_point.dart';

class TrajectoryBuffer extends ChangeNotifier {
  static const int maxPoints = 300; // 10 seconds × 30 Hz

  final Queue<TrajectoryPoint> _points = Queue<TrajectoryPoint>();

  List<TrajectoryPoint> get points => _points.toList();

  int get length => _points.length;

  void addPoint(TrajectoryPoint point) {
    _points.add(point);
    if (_points.length > maxPoints) {
      _points.removeFirst(); // FIFO
    }
    notifyListeners();
  }

  void clear() {
    _points.clear();
    notifyListeners();
  }
}
```

---

## Step 4: Create UI Widgets (2-3 hours)

### 4.1 Create widgets directory

```bash
mkdir -p lib/widgets
```

### 4.2 Create TrajectoryPainter

File: `lib/widgets/trajectory_painter.dart`

```dart
import 'package:flutter/material.dart';
import '../services/trajectory_buffer.dart';

class TrajectoryPainter extends CustomPainter {
  final TrajectoryBuffer buffer;

  TrajectoryPainter(this.buffer) : super(repaint: buffer);

  @override
  void paint(Canvas canvas, Size size) {
    final points = buffer.points;
    if (points.isEmpty) return;

    final path = Path();
    path.moveTo(points.first.x, points.first.y);

    for (final point in points.skip(1)) {
      path.lineTo(point.x, point.y);
    }

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);

    // Draw current position indicator
    if (points.isNotEmpty) {
      final current = points.last;
      final indicatorPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(current.x, current.y),
        6.0,
        indicatorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(TrajectoryPainter oldDelegate) => true;
}
```

### 4.3 Create AccelerationGauge

File: `lib/widgets/acceleration_gauge.dart`

```dart
import 'package:flutter/material.dart';
import '../models/acceleration_reading.dart';

class AccelerationGauge extends StatelessWidget {
  final AccelerationReading? reading;

  const AccelerationGauge({Key? key, this.reading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (reading == null) {
      return const Text(
        '-- g',
        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
      );
    }

    final magnitude = reading!.magnitude;
    final color = _getColorForMagnitude(magnitude);

    return Column(
      children: [
        Text(
          '${magnitude.toStringAsFixed(2)} g',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Lateral: ${reading!.lateralG.toStringAsFixed(2)}g',
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          'Longitudinal: ${reading!.longitudinalG.toStringAsFixed(2)}g',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Color _getColorForMagnitude(double magnitude) {
    if (magnitude < 0.3) return Colors.green;
    if (magnitude < 0.6) return Colors.orange;
    return Colors.red;
  }
}
```

---

## Step 5: Create Main Screen (1 hour)

### 5.1 Create screens directory

```bash
mkdir -p lib/screens
```

### 5.2 Create AccelerationDisplayScreen

File: `lib/screens/acceleration_display_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../models/acceleration_reading.dart';
import '../models/trajectory_point.dart';
import '../services/accelerometer_service.dart';
import '../services/trajectory_buffer.dart';
import '../widgets/acceleration_gauge.dart';
import '../widgets/trajectory_painter.dart';

class AccelerationDisplayScreen extends StatefulWidget {
  const AccelerationDisplayScreen({Key? key}) : super(key: key);

  @override
  State<AccelerationDisplayScreen> createState() =>
      _AccelerationDisplayScreenState();
}

class _AccelerationDisplayScreenState extends State<AccelerationDisplayScreen>
    with WidgetsBindingObserver {
  late AccelerometerService _service;
  late TrajectoryBuffer _buffer;
  AccelerationReading? _currentReading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = AccelerometerService();
    _buffer = TrajectoryBuffer();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _service.initialize();
      _service.stream.listen((reading) {
        setState(() => _currentReading = reading);

        // Add to trajectory buffer
        final center = MediaQuery.of(context).size;
        final point = TrajectoryPoint.fromReading(
          reading,
          20.0, // Scale factor X
          20.0, // Scale factor Y
          center.width / 2,
          center.height / 2,
        );
        _buffer.addPoint(point);
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _service.pause();
    } else if (state == AppLifecycleState.resumed) {
      _service.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $message')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('G-Force Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _buffer.clear,
            tooltip: 'Clear trajectory',
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          AccelerationGauge(reading: _currentReading),
          const SizedBox(height: 20),
          const Text('Trajectory (10 seconds)'),
          Expanded(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: TrajectoryPainter(_buffer),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Step 6: Update Main App (15 minutes)

### 6.1 Update lib/main.dart

```dart
import 'package:flutter/material.dart';
import 'screens/acceleration_display_screen.dart';

void main() {
  runApp(const DriveInspectionApp());
}

class DriveInspectionApp extends StatelessWidget {
  const DriveInspectionApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drive Inspection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AccelerationDisplayScreen(),
    );
  }
}
```

---

## Step 7: Testing (1-2 hours)

### 7.1 Run on Physical Device

**iOS**:
```bash
flutter run -d <ios-device-id>
```

**Android**:
```bash
flutter run -d <android-device-id>
```

List devices:
```bash
flutter devices
```

### 7.2 Manual Testing Checklist

- [ ] App launches without crashes
- [ ] Permission dialog appears (iOS)
- [ ] G-force values update in real-time (~30 Hz)
- [ ] Trajectory path displays and updates
- [ ] Stationary device shows ~0g (horizontal), ~1g (vertical due to gravity)
- [ ] Moving device shows changing values
- [ ] Trajectory clears when Clear button pressed
- [ ] App pauses sensor when backgrounded
- [ ] App resumes sensor when foregrounded
- [ ] No memory leaks during 1-hour operation

### 7.3 Unit Testing

Create test file: `test/models/acceleration_reading_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drive_inspection/models/acceleration_reading.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  group('AccelerationReading', () {
    test('calculates magnitude correctly', () {
      final reading = AccelerationReading(
        x: 0.0,
        y: 4.905, // 0.5g forward
        z: 0.0,
        timestamp: DateTime.now(),
      );

      expect(reading.magnitude, closeTo(0.5, 0.01));
    });

    test('validates finite values', () {
      expect(
        () => AccelerationReading(
          x: double.nan,
          y: 0.0,
          z: 0.0,
          timestamp: DateTime.now(),
        ),
        throwsAssertionError,
      );
    });
  });
}
```

Run tests:
```bash
flutter test
```

---

## Step 8: Performance Validation (30 minutes)

### 8.1 Profile on Physical Device

```bash
flutter run --profile -d <device-id>
```

### 8.2 Monitor Performance

1. Open Flutter DevTools:
   ```bash
   flutter pub global activate devtools
   flutter pub global run devtools
   ```

2. Check metrics:
   - **Frame rate**: Should stay at 60 fps
   - **Memory**: Should stabilize around 50-100 MB
   - **CPU**: Should be < 20% for sensor processing

### 8.3 Verify Update Rate

Add debug print to verify 30 Hz:
```dart
int _eventCount = 0;
DateTime? _lastCheck;

_service.stream.listen((reading) {
  _eventCount++;
  final now = DateTime.now();
  if (_lastCheck != null &&
      now.difference(_lastCheck!).inSeconds >= 1) {
    print('Actual rate: $_eventCount Hz');
    _eventCount = 0;
    _lastCheck = now;
  } else if (_lastCheck == null) {
    _lastCheck = now;
  }
});
```

Expected output: ~30 Hz (±5 Hz acceptable)

---

## Troubleshooting

### Issue: App crashes on iOS launch

**Solution**: Check Info.plist has NSMotionUsageDescription

### Issue: No sensor data on simulator

**Solution**: Must use physical device - simulators don't have sensors

### Issue: Actual sampling rate is < 30 Hz

**Solution**: This is expected on some Android devices - the rate is a hint only

### Issue: UI stutters during updates

**Solution**: Wrap CustomPaint in RepaintBoundary, use ChangeNotifier pattern

### Issue: Memory grows continuously

**Solution**: Verify TrajectoryBuffer is removing old points (FIFO queue working)

---

## Next Steps

After MVP is working:

1. Add unit tests for all models and services
2. Add widget tests for UI components
3. Profile battery consumption over 1-hour session
4. Implement error handling screens
5. Add visual polish (color gradients, animations)

Then proceed to `/speckit.tasks` to generate implementation task list.

---

## Reference

- **Spec**: [spec.md](./spec.md)
- **Plan**: [plan.md](./plan.md)
- **Research**: [research.md](./research.md)
- **Data Model**: [data-model.md](./data-model.md)
- **Contracts**: [contracts/](./contracts/)

---

**Estimated total time**: 8-12 hours for complete MVP implementation
