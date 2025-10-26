import 'package:flutter/material.dart';
import '../models/acceleration_reading.dart';

/// Displays current G-force magnitude and components with color coding.
///
/// Shows total magnitude, lateral (left/right), and longitudinal (forward/backward)
/// G-forces. Color changes based on magnitude intensity.
class AccelerationGauge extends StatelessWidget {
  final AccelerationReading? reading;

  const AccelerationGauge({super.key, this.reading});

  @override
  Widget build(BuildContext context) {
    if (reading == null) {
      return const Text(
        '-- g',
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      );
    }

    final magnitude = reading!.magnitude;
    final color = _getColorForMagnitude(magnitude);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main magnitude display
        Text(
          '${magnitude.toStringAsFixed(2)} g',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 16),

        // Component displays
        _buildComponentRow(
          'Lateral',
          reading!.lateralG,
          Icons.swap_horiz,
        ),
        const SizedBox(height: 8),
        _buildComponentRow(
          'Longitudinal',
          reading!.longitudinalG,
          Icons.swap_vert,
        ),
        const SizedBox(height: 8),
        _buildComponentRow(
          'Vertical',
          reading!.verticalG,
          Icons.height,
        ),
      ],
    );
  }

  /// Build a row showing a single G-force component
  Widget _buildComponentRow(String label, double value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        SizedBox(
          width: 80,
          child: Text(
            '${value.toStringAsFixed(2)}g',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  /// Get color based on G-force magnitude
  ///
  /// Green: < 0.3g (gentle)
  /// Orange: 0.3g - 0.6g (moderate)
  /// Red: > 0.6g (hard)
  Color _getColorForMagnitude(double magnitude) {
    if (magnitude < 0.3) return Colors.green;
    if (magnitude < 0.6) return Colors.orange;
    return Colors.red;
  }
}
