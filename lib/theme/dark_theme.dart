import 'package:flutter/material.dart';
import 'data_visualization_colors.dart';

/// Dark theme configuration using Material Design 3
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: Colors.blue[200]!,
    secondary: Colors.orange[200]!,
    error: Colors.red[300]!,
    surface: Colors.grey[900]!,
  ),
  extensions: <ThemeExtension<dynamic>>[
    DataVisualizationColors(
      trajectoryColor: Colors.blue[200]!.withValues(alpha: 0.7),
      gaugeWarning: Colors.orange[300]!,
      gaugeDanger: Colors.red[300]!,
      chartPrimary: Colors.blue[300]!,
      chartSecondary: Colors.orange[300]!,
    ),
  ],
);
