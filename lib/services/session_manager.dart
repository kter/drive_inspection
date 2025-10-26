import 'package:flutter/foundation.dart';
import '../models/acceleration_reading.dart';
import '../models/driving_event.dart';
import '../models/driving_session.dart';
import 'database_service.dart';

/// Manages driving sessions and detects driving events
class SessionManager extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  DrivingSession? _currentSession;

  // Thresholds for event detection
  static const double hardAccelerationThreshold = 0.3; // G
  static const double hardBrakingThreshold = -0.3; // G (negative)
  static const double sharpTurnThreshold = 0.3; // G

  // Cooldown to prevent multiple events for same maneuver
  DateTime? _lastEventTime;
  static const Duration eventCooldown = Duration(seconds: 2);

  /// Get current session
  DrivingSession? get currentSession => _currentSession;

  /// Check if session is active
  bool get hasActiveSession => _currentSession?.isActive ?? false;

  /// Start a new driving session
  void startSession() {
    if (hasActiveSession) {
      throw StateError('Session already active');
    }

    _currentSession = DrivingSession(startTime: DateTime.now());
    notifyListeners();
  }

  /// End current driving session and save to database
  Future<void> endSession() async {
    if (!hasActiveSession) {
      throw StateError('No active session');
    }

    _currentSession!.end();

    // Save to database
    try {
      await _databaseService.saveSession(_currentSession!);
    } catch (e) {
      // Log error but don't throw - session is still ended in memory
      debugPrint('Failed to save session to database: $e');
    }

    notifyListeners();
  }

  /// Process acceleration reading and detect events
  void processReading(AccelerationReading reading) {
    if (!hasActiveSession) return;

    // Record for statistics
    _currentSession!.recordReading(reading.magnitude);

    // Check cooldown
    if (_lastEventTime != null) {
      final elapsed = DateTime.now().difference(_lastEventTime!);
      if (elapsed < eventCooldown) {
        return; // Still in cooldown
      }
    }

    // Detect events
    _detectHardAcceleration(reading);
    _detectHardBraking(reading);
    _detectSharpTurn(reading);
  }

  /// Detect hard acceleration (forward)
  void _detectHardAcceleration(AccelerationReading reading) {
    if (reading.longitudinalG > hardAccelerationThreshold) {
      final event = DrivingEvent(
        type: DrivingEventType.hardAcceleration,
        timestamp: reading.timestamp,
        magnitude: reading.longitudinalG,
      );
      _addEvent(event);
    }
  }

  /// Detect hard braking (backward)
  void _detectHardBraking(AccelerationReading reading) {
    if (reading.longitudinalG < hardBrakingThreshold) {
      final event = DrivingEvent(
        type: DrivingEventType.hardBraking,
        timestamp: reading.timestamp,
        magnitude: reading.longitudinalG.abs(),
      );
      _addEvent(event);
    }
  }

  /// Detect sharp turn (lateral)
  void _detectSharpTurn(AccelerationReading reading) {
    if (reading.lateralG.abs() > sharpTurnThreshold) {
      final event = DrivingEvent(
        type: DrivingEventType.sharpTurn,
        timestamp: reading.timestamp,
        magnitude: reading.lateralG.abs(),
      );
      _addEvent(event);
    }
  }

  /// Add event to current session
  void _addEvent(DrivingEvent event) {
    _currentSession!.addEvent(event);
    _lastEventTime = event.timestamp;
    notifyListeners();
  }

  /// Clear current session (for testing)
  void clearSession() {
    _currentSession = null;
    _lastEventTime = null;
    notifyListeners();
  }
}
