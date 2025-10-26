import 'package:permission_handler/permission_handler.dart' as ph;
import '../models/permission_status.dart' as app;

/// Manages runtime permissions for motion sensors across iOS and Android.
///
/// Handles permission checking, requesting, and provides methods to open
/// system settings when permission is denied.
class PermissionService {
  /// Check current permission status for motion sensors.
  ///
  /// Does not request permission, only checks current state.
  /// On Android, accelerometer doesn't require permission (always returns granted).
  /// On iOS, checks motion sensor permission status.
  Future<app.PermissionStatus> checkPermissionStatus() async {
    final status = await ph.Permission.sensors.status;
    return _convertStatus(status);
  }

  /// Request motion sensor permission from user.
  ///
  /// On iOS: Shows system permission dialog.
  /// On Android: No-op, returns granted (accelerometer doesn't require permission).
  Future<app.PermissionStatus> requestPermission() async {
    final status = await ph.Permission.sensors.request();
    return _convertStatus(status);
  }

  /// Open app settings for user to manually enable permission.
  ///
  /// Useful when permission is permanently denied.
  /// Returns true if settings were opened successfully.
  Future<bool> openAppSettings() async {
    return await ph.openAppSettings();
  }

  /// Check if permission can be requested.
  ///
  /// Returns false if permission is granted, permanently denied, or restricted.
  /// Returns true if permission is not determined or denied (can retry).
  bool canRequestPermission(app.PermissionStatus status) {
    return status == app.PermissionStatus.notDetermined ||
           status == app.PermissionStatus.denied;
  }

  /// Convert permission_handler status to app PermissionStatus
  app.PermissionStatus _convertStatus(ph.PermissionStatus status) {
    switch (status) {
      case ph.PermissionStatus.granted:
        return app.PermissionStatus.granted;
      case ph.PermissionStatus.denied:
        return app.PermissionStatus.denied;
      case ph.PermissionStatus.restricted:
        return app.PermissionStatus.restricted;
      case ph.PermissionStatus.limited:
        return app.PermissionStatus.granted; // Limited is good enough
      case ph.PermissionStatus.permanentlyDenied:
        return app.PermissionStatus.permanentlyDenied;
      case ph.PermissionStatus.provisional:
        return app.PermissionStatus.granted; // Provisional is good enough
    }
  }
}
