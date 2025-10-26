import 'driving_event.dart';

/// Represents a driving session with score calculation
class DrivingSession {
  final DateTime startTime;
  DateTime? endTime;
  final List<DrivingEvent> events;

  // Statistics
  int totalReadings = 0;
  double totalMagnitude = 0.0;

  DrivingSession({
    required this.startTime,
    this.endTime,
    List<DrivingEvent>? events,
  }) : events = events ?? [];

  /// Check if session is active
  bool get isActive => endTime == null;

  /// Get session duration
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Add a driving event
  void addEvent(DrivingEvent event) {
    events.add(event);
  }

  /// Record a reading for statistics
  void recordReading(double magnitude) {
    totalReadings++;
    totalMagnitude += magnitude;
  }

  /// Calculate average G-force
  double get averageMagnitude {
    if (totalReadings == 0) return 0.0;
    return totalMagnitude / totalReadings;
  }

  /// Calculate driving score (0-100)
  int calculateScore() {
    // Start with perfect score
    int score = 100;

    // Deduct points for each event
    for (final event in events) {
      score -= event.penaltyPoints;
    }

    // Bonus for smooth driving (average G < 0.15)
    if (averageMagnitude < 0.15 && totalReadings > 100) {
      score += 10;
    }

    // Clamp to 0-100 range
    return score.clamp(0, 100);
  }

  /// Get event count by type
  int getEventCount(DrivingEventType type) {
    return events.where((e) => e.type == type).length;
  }

  /// End the session
  void end() {
    endTime = DateTime.now();
  }

  @override
  String toString() {
    return 'DrivingSession(duration: ${duration.inMinutes}min, score: ${calculateScore()}, events: ${events.length})';
  }
}
