import 'package:flutter/material.dart';
import 'screens/acceleration_display_screen.dart';
import 'widgets/permission_gate.dart';

void main() {
  runApp(const DriveInspectionApp());
}

class DriveInspectionApp extends StatelessWidget {
  const DriveInspectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drive Inspection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PermissionGate(
        child: AccelerationDisplayScreen(),
      ),
    );
  }
}
