import 'package:flutter/material.dart';
import '../models/sensor_availability.dart';

/// Screen displayed when accelerometer sensor is unavailable or malfunctioning.
///
/// Provides user-friendly error messages and guidance based on sensor status.
class SensorErrorScreen extends StatelessWidget {
  final SensorAvailability availability;
  final VoidCallback? onRetry;

  const SensorErrorScreen({
    super.key,
    required this.availability,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Error'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIcon(),
              size: 80,
              color: _getColor(),
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
              availability.errorMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Show retry button for malfunctioning sensors
            if (availability == SensorAvailability.malfunctioning && onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),

            // For unavailable sensors, show device info
            if (availability == SensorAvailability.unavailable) ...[
              const SizedBox(height: 16),
              Text(
                'This app requires a device with accelerometer sensors to function.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (availability) {
      case SensorAvailability.unavailable:
        return Icons.phonelink_off;
      case SensorAvailability.malfunctioning:
        return Icons.warning_amber;
      default:
        return Icons.error_outline;
    }
  }

  Color _getColor() {
    switch (availability) {
      case SensorAvailability.unavailable:
        return Colors.grey.shade700;
      case SensorAvailability.malfunctioning:
        return Colors.orange.shade700;
      default:
        return Colors.red.shade700;
    }
  }

  String _getTitle() {
    switch (availability) {
      case SensorAvailability.unavailable:
        return 'No Accelerometer Detected';
      case SensorAvailability.malfunctioning:
        return 'Sensor Malfunction';
      default:
        return 'Sensor Error';
    }
  }
}
