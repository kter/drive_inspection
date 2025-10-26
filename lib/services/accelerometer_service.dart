import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:rxdart/rxdart.dart';
import '../models/acceleration_reading.dart';
import '../models/sensor_availability.dart';

/// Provides real-time accelerometer data stream at 30 Hz.
///
/// Manages sensor lifecycle, error handling, and stream transformation
/// from raw sensor events to domain AccelerationReading objects.
class AccelerometerService {
  StreamSubscription<AccelerationReading>? _subscription;
  final StreamController<AccelerationReading> _controller =
      StreamController<AccelerationReading>.broadcast();

  /// Real-time acceleration readings at ~30 Hz
  Stream<AccelerationReading> get stream => _controller.stream;

  bool _isInitialized = false;
  bool _isPaused = false;
  SensorAvailability _sensorStatus = SensorAvailability.unknown;

  // Debug: Track update rate
  int _eventCount = 0;
  DateTime? _lastRateCheck;

  /// Current sensor availability status
  SensorAvailability get sensorStatus => _sensorStatus;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if service is paused
  bool get isPaused => _isPaused;

  /// Initialize the service and start sensor monitoring.
  ///
  /// Configures sensor sampling rate to 30 Hz (33ms period) and sets up
  /// stream transformation pipeline with backpressure handling.
  ///
  /// Throws [Exception] if sensor cannot be initialized.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set sensor status to available (will be updated if errors occur)
      _sensorStatus = SensorAvailability.available;

      // Create sensor stream with 30 Hz sampling (33ms period)
      // Uses userAccelerometerEventStream which has gravity already filtered out
      // Apply RxDart throttling to control sampling rate at ~30 Hz
      _subscription = userAccelerometerEventStream()
          .throttleTime(const Duration(milliseconds: 33))
          .map((event) => AccelerationReading.fromEvent(event))
          .where((reading) => reading.isValid)
          .listen(
            (reading) {
              _controller.add(reading);

              // Debug: Measure actual update rate
              _eventCount++;
              final now = DateTime.now();
              _lastRateCheck ??= now;
              if (now.difference(_lastRateCheck!).inSeconds >= 1) {
                debugPrint('Accelerometer update rate: $_eventCount Hz');
                _eventCount = 0;
                _lastRateCheck = now;
              }
            },
            onError: (error) {
              _sensorStatus = SensorAvailability.malfunctioning;
              _controller.addError(
                Exception('Accelerometer error: $error'),
              );
            },
            cancelOnError: false, // Continue stream even after errors
          );

      _isInitialized = true;
    } catch (e) {
      _sensorStatus = SensorAvailability.unavailable;
      _controller.addError(
        Exception('Failed to initialize sensor: $e'),
      );
      rethrow;
    }
  }

  /// Pause sensor updates (for battery optimization).
  ///
  /// Temporarily stops sensor readings without disposing resources.
  /// Useful when app goes to background.
  void pause() {
    if (!_isPaused && _subscription != null) {
      _subscription?.pause();
      _isPaused = true;
    }
  }

  /// Resume sensor updates after pause.
  ///
  /// Restarts sensor readings after previous pause() call.
  void resume() {
    if (_isPaused && _subscription != null) {
      _subscription?.resume();
      _isPaused = false;
    }
  }

  /// Stop sensor monitoring and clean up resources.
  ///
  /// Cancels sensor stream subscriptions and releases resources.
  /// Service cannot be used again after dispose without re-initialization.
  void dispose() {
    _subscription?.cancel();
    _controller.close();
    _isInitialized = false;
    _isPaused = false;
  }
}
