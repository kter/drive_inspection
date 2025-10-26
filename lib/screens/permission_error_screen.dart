import 'package:flutter/material.dart';
import '../models/permission_status.dart';
import '../services/permission_service.dart';

/// Screen displayed when sensor permission is denied or restricted.
///
/// Provides user-friendly explanation and "Open Settings" button for
/// permanently denied permissions.
class PermissionErrorScreen extends StatelessWidget {
  final PermissionStatus status;
  final PermissionService permissionService;
  final VoidCallback onRetry;

  const PermissionErrorScreen({
    super.key,
    required this.status,
    required this.permissionService,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Required'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sensors_off,
              size: 80,
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 24),
            Text(
              _getTitle(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _getMessage(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Show appropriate action button based on permission status
            if (status.requiresSettings)
              ElevatedButton.icon(
                onPressed: () async {
                  final opened = await permissionService.openAppSettings();
                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open settings'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (status) {
      case PermissionStatus.denied:
        return 'Motion Sensor Access Denied';
      case PermissionStatus.permanentlyDenied:
        return 'Permission Required';
      case PermissionStatus.restricted:
        return 'Motion Sensors Restricted';
      default:
        return 'Permission Required';
    }
  }

  String _getMessage() {
    switch (status) {
      case PermissionStatus.denied:
        return 'This app needs access to motion sensors to display acceleration data. Please grant permission to continue.';
      case PermissionStatus.permanentlyDenied:
        return 'Motion sensor permission was previously denied. Please enable it in Settings to use this app.';
      case PermissionStatus.restricted:
        return 'Motion sensors are restricted on this device. This may be due to parental controls or device management policies.';
      default:
        return 'This app requires motion sensor access to function properly.';
    }
  }
}
