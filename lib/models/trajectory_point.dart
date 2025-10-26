import 'acceleration_reading.dart';

/// Represents a historical acceleration data point used for trajectory path visualization.
///
/// Stores position data for rendering acceleration history as a 2D trajectory path over time.
/// Coordinates are in canvas space, not acceleration space.
class TrajectoryPoint {
  /// Horizontal position on canvas (mapped from acceleration.x)
  final double x;

  /// Vertical position on canvas (mapped from acceleration.y)
  final double y;

  /// When this trajectory point was recorded
  final DateTime timestamp;

  /// G-force magnitude at this point (for color coding)
  final double magnitude;

  TrajectoryPoint({
    required this.x,
    required this.y,
    required this.timestamp,
    required this.magnitude,
  }) {
    assert(!x.isNaN && !x.isInfinite, 'X position must be finite');
    assert(!y.isNaN && !y.isInfinite, 'Y position must be finite');
    assert(
      timestamp.isBefore(DateTime.now().add(const Duration(seconds: 1))),
      'Timestamp cannot be in future',
    );
    assert(magnitude >= 0, 'Magnitude must be non-negative');
  }

  /// Create from AccelerationReading with canvas scaling
  ///
  /// Transforms acceleration data into canvas coordinates using the provided
  /// scale factors and center point.
  ///
  /// [reading] - The acceleration reading to transform
  /// [scaleX] - Horizontal scale factor (pixels per m/s²)
  /// [scaleY] - Vertical scale factor (pixels per m/s²)
  /// [centerX] - Canvas center X coordinate
  /// [centerY] - Canvas center Y coordinate
  factory TrajectoryPoint.fromReading(
    AccelerationReading reading,
    double scaleX,
    double scaleY,
    double centerX,
    double centerY,
  ) {
    return TrajectoryPoint(
      x: centerX + (reading.x * scaleX),
      y: centerY - (reading.y * scaleY), // Invert Y for canvas coordinates
      timestamp: reading.timestamp,
      magnitude: reading.magnitude,
    );
  }

  @override
  String toString() {
    return 'TrajectoryPoint(x: ${x.toStringAsFixed(1)}, '
           'y: ${y.toStringAsFixed(1)}, '
           'magnitude: ${magnitude.toStringAsFixed(2)}g)';
  }
}
