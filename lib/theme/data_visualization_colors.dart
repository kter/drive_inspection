import 'package:flutter/material.dart';

/// Custom theme extension for data visualization colors
/// Used for trajectory, gauges, and charts in both light and dark themes
class DataVisualizationColors extends ThemeExtension<DataVisualizationColors> {
  final Color trajectoryColor;
  final Color gaugeWarning;
  final Color gaugeDanger;
  final Color chartPrimary;
  final Color chartSecondary;

  const DataVisualizationColors({
    required this.trajectoryColor,
    required this.gaugeWarning,
    required this.gaugeDanger,
    required this.chartPrimary,
    required this.chartSecondary,
  });

  @override
  DataVisualizationColors copyWith({
    Color? trajectoryColor,
    Color? gaugeWarning,
    Color? gaugeDanger,
    Color? chartPrimary,
    Color? chartSecondary,
  }) {
    return DataVisualizationColors(
      trajectoryColor: trajectoryColor ?? this.trajectoryColor,
      gaugeWarning: gaugeWarning ?? this.gaugeWarning,
      gaugeDanger: gaugeDanger ?? this.gaugeDanger,
      chartPrimary: chartPrimary ?? this.chartPrimary,
      chartSecondary: chartSecondary ?? this.chartSecondary,
    );
  }

  @override
  DataVisualizationColors lerp(
    ThemeExtension<DataVisualizationColors>? other,
    double t,
  ) {
    if (other is! DataVisualizationColors) return this;
    return DataVisualizationColors(
      trajectoryColor: Color.lerp(trajectoryColor, other.trajectoryColor, t)!,
      gaugeWarning: Color.lerp(gaugeWarning, other.gaugeWarning, t)!,
      gaugeDanger: Color.lerp(gaugeDanger, other.gaugeDanger, t)!,
      chartPrimary: Color.lerp(chartPrimary, other.chartPrimary, t)!,
      chartSecondary: Color.lerp(chartSecondary, other.chartSecondary, t)!,
    );
  }
}
