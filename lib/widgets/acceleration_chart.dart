import 'package:flutter/material.dart';
import '../models/acceleration_reading.dart';
import '../theme/data_visualization_colors.dart';

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
    final theme = Theme.of(context);
    final vizColors = theme.extension<DataVisualizationColors>()!;

    return Container(
      height: 150,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8.0),
        color: theme.colorScheme.surface,
      ),
      child: CustomPaint(
        painter: _AccelerationChartPainter(
          readings,
          lateralColor: vizColors.chartPrimary,
          longitudinalColor: vizColors.chartSecondary,
          axesColor: theme.colorScheme.outline,
          gridColor: theme.colorScheme.outline.withValues(alpha: 0.3),
          textColor: theme.colorScheme.onSurface,
        ),
        size: Size.infinite,
        child: Container(),
      ),
    );
  }
}

/// CustomPainter for acceleration chart with performance optimizations.
///
/// Performance optimizations:
/// - Caches Paint objects to avoid allocation on every frame
/// - Caches TextPainter objects for static labels
/// - Efficiently compares readings lists in shouldRepaint
class _AccelerationChartPainter extends CustomPainter {
  final List<AccelerationReading> readings;
  final Color lateralColor;
  final Color longitudinalColor;
  final Color axesColor;
  final Color gridColor;
  final Color textColor;

  // Cached Paint objects for performance
  late final Paint _axesPaint;
  late final Paint _gridPaint;
  late final Paint _lateralLinePaint;
  late final Paint _longitudinalLinePaint;
  late final Paint _legendLinePaint;

  // Cached TextPainters for static labels
  late final List<TextPainter> _yAxisLabelPainters;
  late final List<TextPainter> _xAxisLabelPainters;
  late final TextPainter _placeholderPainter;
  late final List<TextPainter> _legendLabelPainters;

  _AccelerationChartPainter(
    this.readings, {
    required this.lateralColor,
    required this.longitudinalColor,
    required this.axesColor,
    required this.gridColor,
    required this.textColor,
  }) {
    // Initialize cached Paint objects
    _axesPaint = Paint()
      ..color = axesColor
      ..strokeWidth = 1.0;

    _gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    _lateralLinePaint = Paint()
      ..color = lateralColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _longitudinalLinePaint = Paint()
      ..color = longitudinalColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _legendLinePaint = Paint()
      ..strokeWidth = 2.0;

    // Initialize Y-axis labels (G values: 0.4, 0.2, 0, -0.2, -0.4)
    final labelStyle = TextStyle(
      color: textColor,
      fontSize: 10,
    );

    _yAxisLabelPainters = [0.4, 0.2, 0, -0.2, -0.4].map((gValue) {
      final painter = TextPainter(
        text: TextSpan(
          text: gValue.toStringAsFixed(1),
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      return painter;
    }).toList();

    // Initialize X-axis labels (30s, 20s, 10s, 0s)
    _xAxisLabelPainters = [30, 20, 10, 0].map((timeValue) {
      final painter = TextPainter(
        text: TextSpan(
          text: '${timeValue}s',
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      return painter;
    }).toList();

    // Initialize placeholder
    _placeholderPainter = TextPainter(
      text: TextSpan(
        text: 'No data yet',
        style: TextStyle(
          color: textColor,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    _placeholderPainter.layout();

    // Initialize legend labels
    _legendLabelPainters = ['Lateral', 'Longitudinal'].map((label) {
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      return painter;
    }).toList();
  }

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

    // Draw data lines for lateral and longitudinal axes using cached Paint objects
    _drawDataLine(
      canvas,
      size,
      readings.map((r) => r.lateralG).toList(),
      _lateralLinePaint,
    );
    _drawDataLine(
      canvas,
      size,
      readings.map((r) => r.longitudinalG).toList(),
      _longitudinalLinePaint,
    );

    // Draw legend
    _drawLegend(canvas, size);
  }

  void _drawAxes(Canvas canvas, Size size) {
    // Y-axis - use cached Paint
    canvas.drawLine(
      Offset(30, 10),
      Offset(30, size.height - 30),
      _axesPaint,
    );

    // X-axis - use cached Paint
    canvas.drawLine(
      Offset(30, size.height - 30),
      Offset(size.width - 10, size.height - 30),
      _axesPaint,
    );
  }

  void _drawGridLines(Canvas canvas, Size size) {
    final chartHeight = size.height - 40;
    final chartWidth = size.width - 40;

    // Horizontal grid lines (G values: 0.4, 0.2, 0, -0.2, -0.4)
    for (int i = 0; i <= 4; i++) {
      final y = 10 + (chartHeight * i / 4);

      // Draw grid line using cached Paint
      canvas.drawLine(
        Offset(30, y),
        Offset(30 + chartWidth, y),
        _gridPaint,
      );

      // Y-axis labels using cached TextPainter
      _yAxisLabelPainters[i].paint(canvas, Offset(2, y - 6));
    }

    // X-axis time labels (30s, 20s, 10s, 0s) - left to right shows time ago
    for (int i = 0; i <= 3; i++) {
      final x = 30 + (chartWidth * i / 3);

      // Use cached TextPainter for X-axis labels
      final textPainter = _xAxisLabelPainters[i];
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
    Paint linePaint,
  ) {
    if (values.length < 2) return;

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

    // Use cached Paint object passed as parameter
    canvas.drawPath(path, linePaint);
  }

  void _drawLegend(Canvas canvas, Size size) {
    final colors = [lateralColor, longitudinalColor];

    double xOffset = size.width - 150;
    const double yOffset = 15.0;

    for (var i = 0; i < colors.length; i++) {
      // Draw color indicator line using cached Paint with updated color
      _legendLinePaint.color = colors[i];
      canvas.drawLine(
        Offset(xOffset, yOffset + (i * 15)),
        Offset(xOffset + 15, yOffset + (i * 15)),
        _legendLinePaint,
      );

      // Draw label text using cached TextPainter
      _legendLabelPainters[i].paint(
        canvas,
        Offset(xOffset + 20, yOffset + (i * 15) - 5),
      );
    }
  }

  void _drawPlaceholder(Canvas canvas, Size size) {
    // Use cached TextPainter
    _placeholderPainter.paint(
      canvas,
      Offset(
        (size.width - _placeholderPainter.width) / 2,
        (size.height - _placeholderPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_AccelerationChartPainter oldDelegate) {
    return readings != oldDelegate.readings;
  }
}
