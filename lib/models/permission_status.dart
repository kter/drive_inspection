/// Represents the state of sensor permissions.
///
/// Used to determine UI flow for permission handling across iOS and Android platforms.
enum PermissionStatus {
  /// Permission not yet requested (iOS only)
  notDetermined,

  /// User granted permission
  granted,

  /// User explicitly denied permission (can request again)
  denied,

  /// Permission restricted by system (iOS parental controls, etc.)
  restricted,

  /// User denied with "don't ask again" (Android)
  permanentlyDenied,
}

/// Extension methods for PermissionStatus
extension PermissionStatusExtensions on PermissionStatus {
  /// Check if permission is granted
  bool get isGranted => this == PermissionStatus.granted;

  /// Check if we can request permission
  ///
  /// Returns false if permission is granted, permanently denied, or restricted.
  bool get canRequest =>
      this == PermissionStatus.notDetermined ||
      this == PermissionStatus.denied;

  /// Check if permission requires opening settings to change
  bool get requiresSettings =>
      this == PermissionStatus.permanentlyDenied ||
      this == PermissionStatus.restricted;

  /// Get user-friendly description
  String get description {
    switch (this) {
      case PermissionStatus.notDetermined:
        return 'Permission not yet requested';
      case PermissionStatus.granted:
        return 'Permission granted';
      case PermissionStatus.denied:
        return 'Permission denied';
      case PermissionStatus.restricted:
        return 'Permission restricted by system';
      case PermissionStatus.permanentlyDenied:
        return 'Permission permanently denied';
    }
  }
}
