/// Represents the availability and status of accelerometer hardware.
///
/// Used for error handling and user messaging when sensor issues occur.
enum SensorAvailability {
  /// Sensor present and functioning normally
  available,

  /// Device has no accelerometer hardware
  unavailable,

  /// Sensor present but returning errors or invalid data
  malfunctioning,

  /// Status not yet determined
  unknown,
}

/// Extension methods for SensorAvailability
extension SensorAvailabilityExtensions on SensorAvailability {
  /// Check if sensor is available and working
  bool get isAvailable => this == SensorAvailability.available;

  /// Check if sensor is completely unavailable (no hardware)
  bool get isUnavailable => this == SensorAvailability.unavailable;

  /// Check if sensor exists but has problems
  bool get hasProblem =>
      this == SensorAvailability.malfunctioning ||
      this == SensorAvailability.unknown;

  /// Get user-friendly error message
  String get errorMessage {
    switch (this) {
      case SensorAvailability.available:
        return 'Sensor working normally';
      case SensorAvailability.unavailable:
        return 'This device does not have an accelerometer sensor';
      case SensorAvailability.malfunctioning:
        return 'Accelerometer sensor may be malfunctioning';
      case SensorAvailability.unknown:
        return 'Sensor status unknown';
    }
  }

  /// Get suggested action for user
  String get suggestedAction {
    switch (this) {
      case SensorAvailability.available:
        return '';
      case SensorAvailability.unavailable:
        return 'This app requires a device with an accelerometer to function.';
      case SensorAvailability.malfunctioning:
        return 'Try restarting the app or your device.';
      case SensorAvailability.unknown:
        return 'Please wait while we check sensor availability.';
    }
  }
}
