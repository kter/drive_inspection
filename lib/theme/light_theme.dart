import 'package:flutter/material.dart';
import 'data_visualization_colors.dart';

/// Light theme configuration using Material Design 3
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: Colors.blue[700]!,
    secondary: Colors.orange[700]!,
    error: Colors.red[700]!,
    surface: Colors.white,
  ),
  extensions: <ThemeExtension<dynamic>>[
    DataVisualizationColors(
      trajectoryColor: Colors.blue.withValues(alpha: 0.6),
      gaugeWarning: Colors.orange[600]!,
      gaugeDanger: Colors.red[600]!,
      chartPrimary: Colors.blue[600]!,
      chartSecondary: Colors.orange[600]!,
    ),
  ],
);
