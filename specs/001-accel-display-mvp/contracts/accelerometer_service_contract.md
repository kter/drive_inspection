# AccelerometerService Contract

**Service**: AccelerometerService
**Purpose**: Provide real-time accelerometer data stream with 30 Hz update rate
**Type**: Internal service interface

---

## Interface Definition

### Stream Provider

```dart
abstract class IAccelerometerService {
  /// Provides real-time acceleration readings at 30 Hz
  ///
  /// Emits AccelerationReading objects containing x, y, z acceleration
  /// and calculated magnitude. Stream is hot (broadcast) and can have
  /// multiple listeners.
  ///
  /// Throws:
  /// - SensorUnavailableException if device has no accelerometer
  /// - SensorPermissionDeniedException if user denies permission
  ///
  /// Returns: Broadcast stream of acceleration readings
  Stream<AccelerationReading> get accelerationStream;

  /// Current sensor availability status
  ///
  /// Returns: SensorAvailability enum (available, unavailable, malfunctioning)
  SensorAvailability get sensorStatus;

  /// Initialize the service and start sensor monitoring
  ///
  /// Must be called before accessing accelerationStream.
  /// Requests necessary permissions on platforms that require it (iOS).
  ///
  /// Returns: Future<void> that completes when initialization is done
  /// Throws: SensorUnavailableException if sensor cannot be initialized
  Future<void> initialize();

  /// Stop sensor monitoring and clean up resources
  ///
  /// Cancels sensor stream subscriptions and releases resources.
  /// Should be called when service is no longer needed.
  ///
  /// Returns: void
  void dispose();

  /// Pause sensor updates (for battery optimization)
  ///
  /// Temporarily stops sensor readings without disposing resources.
  /// Useful when app goes to background.
  ///
  /// Returns: void
  void pause();

  /// Resume sensor updates after pause
  ///
  /// Restarts sensor readings after previous pause() call.
  ///
  /// Returns: void
  void resume();
}
```

---

## Behavior Specifications

### Initialization Sequence

1. Check sensor availability (SensorAvailability.available required)
2. Request permissions if platform requires (iOS: NSMotionUsageDescription)
3. Configure sensor sampling rate to 30 Hz (33ms period)
4. Start listening to userAccelerometerEvents stream
5. Set up stream transformation pipeline
6. Mark service as initialized

### Stream Characteristics

**Update Rate**: 30 Hz (33 milliseconds between emissions)
- Platform note: Android treats this as hint, actual rate may vary (20-50 Hz)
- iOS supports this rate reliably

**Backpressure Handling**: Stream uses `.sample()` to prevent buffering
- Only latest value per 33ms window is emitted
- Older values discarded if UI processing takes > 33ms

**Error Handling**:
- Sensor disconnection → emit error on stream
- Invalid sensor data (NaN, Infinity) → filtered out, not emitted
- Permission denial → throw exception during initialize()

### Lifecycle Management

**On initialize()**:
- ✅ Create StreamController
- ✅ Subscribe to sensor events
- ✅ Set up transformation pipeline
- ✅ Verify sensor availability

**On pause()**:
- ✅ Pause sensor subscription (StreamSubscription.pause())
- ❌ Do NOT cancel subscription
- ❌ Do NOT dispose resources

**On resume()**:
- ✅ Resume sensor subscription (StreamSubscription.resume())
- ✅ Continue from previous state

**On dispose()**:
- ✅ Cancel all sensor subscriptions
- ✅ Close StreamController
- ✅ Release all resources
- ❌ Cannot be used again after dispose

---

## Data Transformations

### Raw Sensor Event → AccelerationReading

```
Input: AccelerometerEvent from sensors_plus
  - x: double (m/s²)
  - y: double (m/s²)
  - z: double (m/s²)

Transformations:
  1. Validate: Check for NaN, Infinity → discard if invalid
  2. Create AccelerationReading with timestamp
  3. Calculate magnitude: sqrt(x² + y² + z²) / 9.81

Output: AccelerationReading
  - x, y, z (m/s²)
  - timestamp (DateTime.now())
  - magnitude (G-forces)
```

### Stream Pipeline

```
userAccelerometerEvents(samplingPeriod: 33ms)
  ↓
.sample(Duration(milliseconds: 33))  // Backpressure handling
  ↓
.map((event) => AccelerationReading.fromEvent(event))
  ↓
.where((reading) => reading.isValid)  // Filter invalid data
  ↓
accelerationStream (broadcast)
```

---

## Error Scenarios

### SensorUnavailableException

**When**: Device has no accelerometer hardware
**Thrown by**: initialize()
**User Action**: Display error message "Device not compatible"

```dart
throw SensorUnavailableException(
  'This device does not have an accelerometer sensor.'
);
```

### SensorPermissionDeniedException

**When**: User denies motion sensor permission (iOS)
**Thrown by**: initialize()
**User Action**: Display instructions to enable in Settings

```dart
throw SensorPermissionDeniedException(
  'Motion sensor permission is required. Please enable in Settings.'
);
```

### SensorMalfunctionException

**When**: Sensor returns errors during operation
**Emitted**: On accelerationStream as error event
**User Action**: Display warning "Sensor may be malfunctioning"

```dart
streamController.addError(
  SensorMalfunctionException('Accelerometer returned invalid data')
);
```

---

## Performance Requirements

### Update Frequency
- **Target**: 30 Hz (±2 Hz acceptable)
- **Measured**: Actual emissions per second
- **Monitoring**: Track emission timestamps, calculate actual rate

### Latency
- **Target**: < 100ms from sensor reading to stream emission
- **Measurement**: timestamp in AccelerationReading vs DateTime.now()

### Memory
- **Target**: < 1 MB for service (excluding buffer)
- **Monitoring**: Dart Observatory memory profiling
- **No leaks**: Stable memory usage over 1-hour operation

### CPU Usage
- **Target**: < 5% CPU for sensor processing
- **Monitoring**: Flutter DevTools performance tab
- **UI Thread**: Sensor processing must not block UI (use isolates if needed)

---

## Testing Contract

### Unit Tests Required

1. **Stream initialization**
   - Verify stream is broadcast (supports multiple listeners)
   - Verify stream emits at ~30 Hz rate
   - Verify AccelerationReading structure is correct

2. **Error handling**
   - Mock sensor unavailable → throw SensorUnavailableException
   - Mock permission denied → throw SensorPermissionDeniedException
   - Mock invalid sensor data → filter out, don't emit

3. **Lifecycle**
   - Call pause() → stream pauses
   - Call resume() → stream resumes
   - Call dispose() → stream closes
   - Call after dispose() → throw StateError

4. **Backpressure**
   - Emit 100 events rapidly → only latest per 33ms window appears
   - Verify no buffering (memory stays constant)

### Mock Implementation for Testing

```dart
class MockAccelerometerService implements IAccelerometerService {
  final StreamController<AccelerationReading> _controller =
      StreamController.broadcast();

  @override
  Stream<AccelerationReading> get accelerationStream => _controller.stream;

  @override
  SensorAvailability get sensorStatus => SensorAvailability.available;

  void emitTestReading(AccelerationReading reading) {
    _controller.add(reading);
  }

  void emitError(Object error) {
    _controller.addError(error);
  }

  // ... implement other methods
}
```

---

## Platform-Specific Notes

### iOS Requirements

**Info.plist**:
```xml
<key>NSMotionUsageDescription</key>
<string>This app monitors vehicle acceleration for driving analysis.</string>
```

**Minimum Version**: iOS 12.0+
**Permission**: Runtime permission required (handled by initialize())

### Android Requirements

**Permissions**: None required for accelerometer/gyroscope
**Minimum SDK**: API 21 (Android 5.0 Lollipop)
**Sampling Rate**: Hint only, actual rate varies by device

---

## Dependencies

**External**:
- sensors_plus: ^6.0.1 (accelerometer access)
- permission_handler: ^11.3.1 (iOS permission management)
- rxdart: ^0.28.0 (stream sampling)

**Internal**:
- AccelerationReading (data model)
- SensorAvailability (enum)

---

## Example Usage

```dart
class AccelerationScreen extends StatefulWidget {
  @override
  _AccelerationScreenState createState() => _AccelerationScreenState();
}

class _AccelerationScreenState extends State<AccelerationScreen>
    with WidgetsBindingObserver {
  late IAccelerometerService _service;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = AccelerometerService();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _service.initialize();
      _subscription = _service.accelerationStream.listen(
        (reading) {
          // Update UI with acceleration data
          setState(() { /* ... */ });
        },
        onError: (error) {
          // Handle errors
          showErrorDialog(error);
        },
      );
    } on SensorUnavailableException {
      showDialog(/* Device not compatible */);
    } on SensorPermissionDeniedException {
      showDialog(/* Permission denied */);
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
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build UI...
  }
}
```
