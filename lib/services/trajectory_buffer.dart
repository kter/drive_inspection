import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/trajectory_point.dart';

/// Manages the sliding window of trajectory points for visualization.
///
/// Maintains a fixed-size FIFO buffer of recent trajectory points,
/// automatically removing old data. Extends ChangeNotifier for reactive UI updates.
class TrajectoryBuffer extends ChangeNotifier {
  /// Maximum buffer size: 300 points for 10 seconds at 30 Hz
  static const int maxPoints = 300;

  final Queue<TrajectoryPoint> _points = Queue<TrajectoryPoint>();

  /// Current trajectory points (read-only)
  List<TrajectoryPoint> get points => _points.toList();

  /// Current number of points in buffer
  int get length => _points.length;

  /// Check if buffer is empty
  bool get isEmpty => _points.isEmpty;

  /// Check if buffer is at capacity
  bool get isFull => _points.length >= maxPoints;

  /// Add new point, remove oldest if at capacity (FIFO)
  void addPoint(TrajectoryPoint point) {
    _points.add(point);

    // Remove oldest point if exceeded capacity
    if (_points.length > maxPoints) {
      _points.removeFirst();
    }

    // Notify listeners for UI update
    notifyListeners();
  }

  /// Remove all points
  void clear() {
    if (_points.isNotEmpty) {
      _points.clear();
      notifyListeners();
    }
  }

  /// Get points within a specific time range
  ///
  /// Returns points with timestamps between [start] and [end] (inclusive).
  List<TrajectoryPoint> getPointsInRange(DateTime start, DateTime end) {
    return _points
        .where((point) =>
            !point.timestamp.isBefore(start) &&
            !point.timestamp.isAfter(end))
        .toList();
  }

  /// Get the most recent point, or null if buffer is empty
  TrajectoryPoint? get latestPoint => _points.isEmpty ? null : _points.last;

  /// Get the oldest point, or null if buffer is empty
  TrajectoryPoint? get oldestPoint => _points.isEmpty ? null : _points.first;

  @override
  void dispose() {
    _points.clear();
    super.dispose();
  }
}
