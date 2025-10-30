import 'package:flutter/material.dart';
import '../models/acceleration_reading.dart';
import '../theme/data_visualization_colors.dart';

/// Displays current G-force magnitude and components with color coding.
///
/// Shows total magnitude, lateral (left/right), and longitudinal (forward/backward)
/// G-forces. Vertical component is excluded as it's not relevant for driving.
/// Color changes based on magnitude intensity.
class AccelerationGauge extends StatelessWidget {
  final AccelerationReading? reading;

  const AccelerationGauge({super.key, this.reading});

  @override
  Widget build(BuildContext context) {
    if (reading == null) {
      return Text(
        '-- g',
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }

    final magnitude = reading!.magnitude;
    final color = _getColorForMagnitude(context, magnitude);

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
          context,
          'Lateral',
          reading!.lateralG,
          Icons.swap_horiz,
        ),
        const SizedBox(height: 8),
        _buildComponentRow(
          context,
          'Longitudinal',
          reading!.longitudinalG,
          Icons.swap_vert,
        ),
      ],
    );
  }

  /// Build a row showing a single G-force component
  Widget _buildComponentRow(
      BuildContext context, String label, double value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
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
  /// Green/Primary: < 0.3g (gentle)
  /// Orange/Warning: 0.3g - 0.6g (moderate)
  /// Red/Danger: > 0.6g (hard)
  Color _getColorForMagnitude(BuildContext context, double magnitude) {
    final vizColors = Theme.of(context).extension<DataVisualizationColors>()!;
    if (magnitude < 0.3) return Theme.of(context).colorScheme.primary;
    if (magnitude < 0.6) return vizColors.gaugeWarning;
    return vizColors.gaugeDanger;
  }
}
