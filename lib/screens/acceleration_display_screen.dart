import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/acceleration_reading.dart';
import '../models/sensor_availability.dart';
import '../models/trajectory_point.dart';
import '../services/accelerometer_service.dart';
import '../services/trajectory_buffer.dart';
import '../services/session_manager.dart';
import '../widgets/acceleration_gauge.dart';
import '../widgets/acceleration_chart.dart';
import '../widgets/loading_state.dart';
import '../widgets/trajectory_painter.dart';
import '../widgets/score_display.dart';
import 'sensor_error_screen.dart';
import 'dart:collection';

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
  late SessionManager _sessionManager;
  AccelerationReading? _currentReading;
  String? _errorMessage;
  bool _isInitializing = true;

  // Buffer for chart data (30 seconds worth of data = 150 points)
  final Queue<AccelerationReading> _chartData = Queue<AccelerationReading>();
  static const int _maxChartPoints = 150;

  // Canvas size for trajectory calculation
  Size? _canvasSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = AccelerometerService();
    _buffer = TrajectoryBuffer();
    _sessionManager = SessionManager();

    // Listen to session manager changes
    _sessionManager.addListener(_onSessionChanged);

    // Enable wakelock to prevent screen sleep
    WakelockPlus.enable();

    _initialize();
  }

  /// Called when session manager state changes
  void _onSessionChanged() {
    setState(() {});
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

          // Process reading for session manager (event detection)
          _sessionManager.processReading(reading);

          // Add to chart data buffer
          _chartData.add(reading);
          if (_chartData.length > _maxChartPoints) {
            _chartData.removeFirst();
          }

          // Add trajectory point
          final point = _calculateTrajectoryPoint(reading);
          _buffer.addPoint(point);

          setState(() {
            _currentReading = reading;
            _errorMessage = null;
          });
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

  /// Calculate trajectory point from reading using canvas center
  TrajectoryPoint _calculateTrajectoryPoint(AccelerationReading reading) {
    if (_canvasSize == null) {
      // Fallback if canvas size not yet measured
      return TrajectoryPoint.fromReading(
        reading,
        20.0,
        20.0,
        200,
        200,
      );
    }

    // Calculate scale factor dynamically to match concentric circles
    const gToMetersPerSecondSquared = 9.81;
    const maxG = 0.4;
    final maxAcceleration = maxG * gToMetersPerSecondSquared;
    final maxRadius = (_canvasSize!.width < _canvasSize!.height
            ? _canvasSize!.width
            : _canvasSize!.height) /
        2 *
        0.85;
    final scaleFactor = maxRadius / maxAcceleration;

    return TrajectoryPoint.fromReading(
      reading,
      scaleFactor, // Scale factor X (pixels per m/s²)
      scaleFactor, // Scale factor Y (pixels per m/s²)
      _canvasSize!.width / 2, // Center X within canvas
      _canvasSize!.height / 2, // Center Y within canvas
    );
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
    _sessionManager.removeListener(_onSessionChanged);
    _service.dispose();
    _buffer.dispose();
    _chartData.clear();
    // Disable wakelock when screen is disposed
    WakelockPlus.disable();
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
          // Session start/stop button
          if (_sessionManager.hasActiveSession)
            IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.red),
              onPressed: () {
                _sessionManager.endSession();
              },
              tooltip: 'セッション終了',
            )
          else
            IconButton(
              icon: const Icon(Icons.play_circle, color: Colors.green),
              onPressed: () {
                _sessionManager.startSession();
              },
              tooltip: 'セッション開始',
            ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearTrajectory,
            tooltip: 'Clear trajectory',
          ),
        ],
      ),
      body: Column(
        children: [
          // Wakelock warning message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            color: Colors.amber.shade100,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  '画面のスリープを無効にしています',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),

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

          const SizedBox(height: 12),

          // Score display (only when session active or just ended)
          if (_sessionManager.currentSession != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ScoreDisplay(session: _sessionManager.currentSession),
            ),

          if (_sessionManager.currentSession != null)
            const SizedBox(height: 12),

          // G-force magnitude and components
          AccelerationGauge(reading: _currentReading),

          const SizedBox(height: 12),

          // Trajectory canvas with LayoutBuilder to measure size
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Update canvas size for trajectory calculation
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_canvasSize == null ||
                        _canvasSize!.width != constraints.maxWidth ||
                        _canvasSize!.height != constraints.maxHeight) {
                      setState(() {
                        _canvasSize = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                      });
                    }
                  });

                  return RepaintBoundary(
                    child: CustomPaint(
                      painter: TrajectoryPainter(_buffer),
                      size: Size.infinite,
                      child: Container(),
                    ),
                  );
                },
              ),
            ),
          ),

          // Acceleration chart
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: AccelerationChart(
              readings: _chartData.toList(),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
