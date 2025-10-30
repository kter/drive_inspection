import 'package:flutter/material.dart';
import '../services/trajectory_buffer.dart';

/// CustomPainter for rendering acceleration trajectory path.
///
/// Draws a continuous path from trajectory points in the buffer,
/// with a current position indicator. Uses RepaintBoundary optimization
/// for efficient rendering at 30 Hz update rate.
///
/// Performance optimizations:
/// - Caches Paint objects to avoid allocation on every frame
/// - Caches TextPainter objects for static labels
/// - Reuses Paint objects with modified alpha for trajectory gradient
class TrajectoryPainter extends CustomPainter {
  final TrajectoryBuffer buffer;
  final Color trajectoryColor;
  final Color currentPositionColor;
  final Color gridColor;
  final Color textColor;

  // Cached Paint objects for performance
  late final Paint _trajectoryPaint;
  late final Paint _outerIndicatorPaint;
  late final Paint _innerIndicatorPaint;
  late final Paint _circlePaint;
  late final Paint _crosshairPaint;
  late final Paint _dotPaint;

  // Cached TextPainters for static labels
  late final List<TextPainter> _gLabelPainters;
  late final TextPainter _placeholderPainter;

  /// Create painter that listens to buffer changes
  ///
  /// The painter will automatically repaint when buffer is updated
  /// via ChangeNotifier.
  TrajectoryPainter(
    this.buffer, {
    required this.trajectoryColor,
    required this.currentPositionColor,
    required this.gridColor,
    required this.textColor,
  }) : super(repaint: buffer) {
    // Initialize cached Paint objects
    _trajectoryPaint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _outerIndicatorPaint = Paint()
      ..color = currentPositionColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    _innerIndicatorPaint = Paint()
      ..color = currentPositionColor
      ..style = PaintingStyle.fill;

    _circlePaint = Paint()
      ..color = gridColor.withValues(alpha: 0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    _crosshairPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    _dotPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Initialize cached TextPainters for G labels
    final textStyle = TextStyle(
      color: gridColor.withValues(alpha: 0.6),
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );

    _gLabelPainters = [0.1, 0.2, 0.3, 0.4].map((gLevel) {
      final painter = TextPainter(
        text: TextSpan(
          text: '${gLevel.toStringAsFixed(1)}G',
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      return painter;
    }).toList();

    // Initialize placeholder TextPainter
    _placeholderPainter = TextPainter(
      text: TextSpan(
        text: 'Move device to see trajectory',
        style: TextStyle(
          color: textColor,
          fontSize: 16,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    _placeholderPainter.layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final points = buffer.points;

    // Always draw concentric circles and center crosshair
    _drawConcentricCircles(canvas, size);
    _drawCenterCrosshair(canvas, size);

    if (points.isEmpty) {
      // Draw placeholder when no data
      _drawPlaceholder(canvas, size);
      return;
    }

    // Draw trajectory path
    _drawTrajectoryPath(canvas, points);

    // Draw current position indicator
    _drawCurrentPositionIndicator(canvas, points.last);
  }

  /// Draw trajectory path connecting all points with fade-out effect
  void _drawTrajectoryPath(Canvas canvas, List points) {
    if (points.length < 2) return;

    // Draw line segments with gradient alpha (older = more transparent)
    // Reuse cached Paint object, only update color for each segment
    for (int i = 0; i < points.length - 1; i++) {
      final progress = i / (points.length - 1);
      final alpha = 0.1 + (progress * 0.6); // Fade from 0.1 to 0.7

      _trajectoryPaint.color = trajectoryColor.withValues(alpha: alpha);

      canvas.drawLine(
        Offset(points[i].x, points[i].y),
        Offset(points[i + 1].x, points[i + 1].y),
        _trajectoryPaint,
      );
    }
  }

  /// Draw indicator at current acceleration position
  void _drawCurrentPositionIndicator(Canvas canvas, dynamic currentPoint) {
    // Outer circle (pulsing effect) - use cached Paint
    canvas.drawCircle(
      Offset(currentPoint.x, currentPoint.y),
      10.0,
      _outerIndicatorPaint,
    );

    // Inner circle (solid) - use cached Paint
    canvas.drawCircle(
      Offset(currentPoint.x, currentPoint.y),
      6.0,
      _innerIndicatorPaint,
    );
  }

  /// Draw concentric circles for G-force reference (0.1G, 0.2G, 0.3G, 0.4G)
  void _drawConcentricCircles(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Calculate scale factor dynamically to fill ~85% of canvas
    const gToMetersPerSecondSquared = 9.81;
    const maxG = 0.4;
    final maxAcceleration = maxG * gToMetersPerSecondSquared;

    // Use 85% of the smaller dimension for the maximum circle
    final maxRadius = (size.width < size.height ? size.width : size.height) / 2 * 0.85;
    final scaleFactor = maxRadius / maxAcceleration;

    final gLevels = [0.1, 0.2, 0.3, 0.4];

    for (int i = 0; i < gLevels.length; i++) {
      final gLevel = gLevels[i];
      final radius = gLevel * gToMetersPerSecondSquared * scaleFactor;

      // Draw circle using cached Paint
      canvas.drawCircle(
        Offset(centerX, centerY),
        radius,
        _circlePaint,
      );

      // Draw label at top of circle using cached TextPainter
      final textPainter = _gLabelPainters[i];
      textPainter.paint(
        canvas,
        Offset(
          centerX - textPainter.width / 2,
          centerY - radius - textPainter.height - 2,
        ),
      );
    }
  }

  /// Draw center reference crosshair
  void _drawCenterCrosshair(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final crosshairSize = 20.0;

    // Horizontal line - use cached Paint
    canvas.drawLine(
      Offset(centerX - crosshairSize, centerY),
      Offset(centerX + crosshairSize, centerY),
      _crosshairPaint,
    );

    // Vertical line - use cached Paint
    canvas.drawLine(
      Offset(centerX, centerY - crosshairSize),
      Offset(centerX, centerY + crosshairSize),
      _crosshairPaint,
    );

    // Center dot - use cached Paint
    canvas.drawCircle(Offset(centerX, centerY), 3.0, _dotPaint);
  }

  /// Draw placeholder text when no data
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
  bool shouldRepaint(TrajectoryPainter oldDelegate) {
    // Always repaint when buffer notifies changes
    return true;
  }
}
