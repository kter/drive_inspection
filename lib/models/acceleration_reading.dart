import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// Represents a single point-in-time measurement from the accelerometer sensor.
///
/// Captures raw or processed acceleration data from device sensors with temporal context.
/// All acceleration values are in m/s², with magnitude computed in G-forces (1g = 9.81 m/s²).
class AccelerationReading {
  /// Acceleration along X-axis in m/s² (lateral: left/right)
  final double x;

  /// Acceleration along Y-axis in m/s² (longitudinal: forward/backward)
  final double y;

  /// Acceleration along Z-axis in m/s² (vertical: up/down)
  final double z;

  /// When the reading was captured
  final DateTime timestamp;

  AccelerationReading({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  }) {
    assert(!x.isNaN && !x.isInfinite, 'X acceleration must be finite');
    assert(!y.isNaN && !y.isInfinite, 'Y acceleration must be finite');
    assert(!z.isNaN && !z.isInfinite, 'Z acceleration must be finite');
    assert(
      timestamp.isBefore(DateTime.now().add(const Duration(seconds: 1))),
      'Timestamp cannot be in future',
    );
  }

  /// Create from sensors_plus UserAccelerometerEvent
  factory AccelerationReading.fromEvent(UserAccelerometerEvent event) {
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

  /// Check if all values are valid (not NaN or infinite)
  bool get isValid => !x.isNaN && !y.isNaN && !z.isNaN &&
                      !x.isInfinite && !y.isInfinite && !z.isInfinite;

  @override
  String toString() {
    return 'AccelerationReading(x: ${x.toStringAsFixed(2)}, '
           'y: ${y.toStringAsFixed(2)}, '
           'z: ${z.toStringAsFixed(2)}, '
           'magnitude: ${magnitude.toStringAsFixed(2)}g)';
  }
}
