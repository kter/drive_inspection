import 'package:flutter/material.dart';
import '../models/acceleration_reading.dart';

/// Line chart displaying acceleration history over time.
///
/// Shows 3-axis acceleration (lateral, longitudinal, vertical) as separate
/// colored lines with time on X-axis and G-force on Y-axis.
class AccelerationChart extends StatelessWidget {
  final List<AccelerationReading> readings;
  final Duration timeWindow;

  const AccelerationChart({
    super.key,
    required this.readings,
    this.timeWindow = const Duration(seconds: 30),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.white,
      ),
      child: CustomPaint(
        painter: _AccelerationChartPainter(readings),
        size: Size.infinite,
        child: Container(),
      ),
    );
  }
}

class _AccelerationChartPainter extends CustomPainter {
  final List<AccelerationReading> readings;

  _AccelerationChartPainter(this.readings);

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.isEmpty) {
      _drawPlaceholder(canvas, size);
      return;
    }

    // Draw axes
    _drawAxes(canvas, size);

    // Draw grid lines
    _drawGridLines(canvas, size);

    // Draw data lines for lateral and longitudinal axes
    _drawDataLine(
      canvas,
      size,
      readings.map((r) => r.lateralG).toList(),
      Colors.red,
    );
    _drawDataLine(
      canvas,
      size,
      readings.map((r) => r.longitudinalG).toList(),
      Colors.green,
    );

    // Draw legend
    _drawLegend(canvas, size);
  }

  void _drawAxes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1.0;

    // Y-axis
    canvas.drawLine(
      Offset(30, 10),
      Offset(30, size.height - 30),
      paint,
    );

    // X-axis
    canvas.drawLine(
      Offset(30, size.height - 30),
      Offset(size.width - 10, size.height - 30),
      paint,
    );
  }

  void _drawGridLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    final chartHeight = size.height - 40;
    final chartWidth = size.width - 40;

    // Horizontal grid lines (G values: -0.4, -0.2, 0, 0.2, 0.4)
    for (int i = 0; i <= 4; i++) {
      final y = 10 + (chartHeight * i / 4);
      canvas.drawLine(
        Offset(30, y),
        Offset(30 + chartWidth, y),
        paint,
      );

      // Y-axis labels
      final gValue = 0.4 - (i * 0.2);
      final textPainter = TextPainter(
        text: TextSpan(
          text: gValue.toStringAsFixed(1),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(2, y - 6));
    }

    // X-axis time labels (30s, 20s, 10s, 0s) - left to right shows time ago
    for (int i = 0; i <= 3; i++) {
      final x = 30 + (chartWidth * i / 3);
      final timeValue = (3 - i) * 10;

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${timeValue}s',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 25),
      );
    }
  }

  void _drawDataLine(
    Canvas canvas,
    Size size,
    List<double> values,
    Color color,
  ) {
    if (values.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final chartHeight = size.height - 40;
    final chartWidth = size.width - 40;

    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final x = 30 + (chartWidth * i / (values.length - 1));
      // Map G value (-0.4 to 0.4) to canvas Y (invert: top is positive)
      // Clamp to range to prevent drawing outside bounds
      final clampedValue = values[i].clamp(-0.4, 0.4);
      final normalizedY = (0.4 - clampedValue) / 0.8; // Map -0.4..0.4 to 1..0
      final y = 10 + (chartHeight * normalizedY);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawLegend(Canvas canvas, Size size) {
    final labels = [
      ('Lateral', Colors.red),
      ('Longitudinal', Colors.green),
    ];

    double xOffset = size.width - 150;
    const double yOffset = 15.0;

    for (var i = 0; i < labels.length; i++) {
      final (label, color) = labels[i];

      // Draw color indicator line
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.0;

      canvas.drawLine(
        Offset(xOffset, yOffset + (i * 15)),
        Offset(xOffset + 15, yOffset + (i * 15)),
        paint,
      );

      // Draw label text
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(xOffset + 20, yOffset + (i * 15) - 5),
      );
    }
  }

  void _drawPlaceholder(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'No data yet',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_AccelerationChartPainter oldDelegate) {
    return readings != oldDelegate.readings;
  }
}
