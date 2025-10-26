import 'package:flutter/material.dart';
import '../models/acceleration_reading.dart';
import '../models/sensor_availability.dart';
import '../models/trajectory_point.dart';
import '../services/accelerometer_service.dart';
import '../services/trajectory_buffer.dart';
import '../widgets/acceleration_gauge.dart';
import '../widgets/loading_state.dart';
import '../widgets/trajectory_painter.dart';
import 'sensor_error_screen.dart';

/// Main screen displaying real-time acceleration with trajectory visualization.
///
/// Integrates AccelerationGauge for numeric display and TrajectoryPainter
/// for visual trajectory. Implements WidgetsBindingObserver for proper
/// lifecycle management (pause/resume sensors on background/foreground).
class AccelerationDisplayScreen extends StatefulWidget {
  const AccelerationDisplayScreen({super.key});

  @override
  State<AccelerationDisplayScreen> createState() =>
      _AccelerationDisplayScreenState();
}

class _AccelerationDisplayScreenState extends State<AccelerationDisplayScreen>
    with WidgetsBindingObserver {
  late AccelerometerService _service;
  late TrajectoryBuffer _buffer;
  AccelerationReading? _currentReading;
  String? _errorMessage;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = AccelerometerService();
    _buffer = TrajectoryBuffer();
    _initialize();
  }

  /// Initialize accelerometer service and set up data stream
  Future<void> _initialize() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      await _service.initialize();

      // Listen to acceleration stream
      _service.stream.listen(
        (reading) {
          if (!mounted) return;

          setState(() {
            _currentReading = reading;
            _errorMessage = null;
          });

          // Transform reading to trajectory point and add to buffer
          // Get canvas size for proper scaling
          final size = MediaQuery.of(context).size;
          final point = TrajectoryPoint.fromReading(
            reading,
            20.0, // Scale factor X (pixels per m/s²)
            20.0, // Scale factor Y (pixels per m/s²)
            size.width / 2, // Center X
            size.height / 2 - 100, // Center Y (offset for gauge above)
          );
          _buffer.addPoint(point);
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _errorMessage = error.toString();
            // Trigger UI rebuild to show error screen if sensor is malfunctioning
          });
        },
      );

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Failed to initialize accelerometer: $e';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause sensors when app goes to background (battery optimization)
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _service.pause();
    }
    // Resume sensors when app comes to foreground
    else if (state == AppLifecycleState.resumed) {
      _service.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.dispose();
    _buffer.dispose();
    super.dispose();
  }

  /// Clear trajectory history
  void _clearTrajectory() {
    _buffer.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state during initialization
    if (_isInitializing) {
      return const Scaffold(
        body: LoadingState(message: 'Initializing sensor...'),
      );
    }

    // Check sensor availability and show error screen if needed
    final sensorStatus = _service.sensorStatus;
    if (sensorStatus == SensorAvailability.unavailable ||
        sensorStatus == SensorAvailability.malfunctioning) {
      return SensorErrorScreen(
        availability: sensorStatus,
        onRetry: sensorStatus == SensorAvailability.malfunctioning
            ? () async {
                // Dispose current service and reinitialize
                _service.dispose();
                _service = AccelerometerService();
                await _initialize();
              }
            : null,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('G-Force Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearTrajectory,
            tooltip: 'Clear trajectory',
          ),
        ],
      ),
      body: Column(
        children: [
          // Error message display
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              color: Colors.red.shade100,
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 20),

          // G-force magnitude and components
          AccelerationGauge(reading: _currentReading),

          const SizedBox(height: 20),

          // Trajectory visualization label
          const Text(
            'Trajectory (10 seconds)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          // Trajectory canvas
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: TrajectoryPainter(_buffer),
                  size: Size.infinite,
                  child: Container(), // Child needed for Size.infinite to work
                ),
              ),
            ),
          ),

          // Status information
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Points: ${_buffer.length}/${TrajectoryBuffer.maxPoints}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
