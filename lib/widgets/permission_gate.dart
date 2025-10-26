import 'package:flutter/material.dart';
import '../models/permission_status.dart';
import '../services/permission_service.dart';
import '../screens/permission_error_screen.dart';

/// Gate widget that ensures motion sensor permission is granted before
/// displaying child widget.
///
/// Handles permission checking, requesting, and error states with smooth
/// transitions between states. Automatically requests permission on first
/// launch (notDetermined state).
class PermissionGate extends StatefulWidget {
  final Widget child;

  const PermissionGate({
    super.key,
    required this.child,
  });

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> with WidgetsBindingObserver {
  final PermissionService _permissionService = PermissionService();
  PermissionStatus _currentStatus = PermissionStatus.notDetermined;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndRequestPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check permission when app comes back from background
    // (user may have changed permission in Settings)
    if (state == AppLifecycleState.resumed) {
      _checkAndRequestPermission();
    }
  }

  /// Check current permission status and request if needed
  Future<void> _checkAndRequestPermission() async {
    setState(() {
      _isChecking = true;
    });

    try {
      // Check current status
      PermissionStatus status = await _permissionService.checkPermissionStatus();

      // Auto-request if permission is not determined
      if (status == PermissionStatus.notDetermined) {
        status = await _permissionService.requestPermission();
      }

      if (mounted) {
        setState(() {
          _currentStatus = status;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentStatus = PermissionStatus.denied;
          _isChecking = false;
        });
      }
    }
  }

  /// Handle retry action from error screen
  Future<void> _handleRetry() async {
    setState(() {
      _isChecking = true;
    });

    try {
      // If we can request permission, request it
      if (_permissionService.canRequestPermission(_currentStatus)) {
        final status = await _permissionService.requestPermission();
        if (mounted) {
          setState(() {
            _currentStatus = status;
            _isChecking = false;
          });
        }
      } else {
        // Just re-check status (in case user changed it in Settings)
        await _checkAndRequestPermission();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking permission
    if (_isChecking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Checking permissions...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show child if permission is granted
    if (_currentStatus.isGranted) {
      return widget.child;
    }

    // Show error screen for denied/restricted permissions
    return PermissionErrorScreen(
      status: _currentStatus,
      permissionService: _permissionService,
      onRetry: _handleRetry,
    );
  }
}
