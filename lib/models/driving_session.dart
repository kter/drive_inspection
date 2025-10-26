import 'dart:convert';
import 'driving_event.dart';

/// Represents a driving session with score calculation
class DrivingSession {
  final int? id;  // Database ID (null for unsaved sessions)
  final DateTime startTime;
  DateTime? endTime;
  final List<DrivingEvent> events;

  // Statistics
  int totalReadings = 0;
  double totalMagnitude = 0.0;

  DrivingSession({
    this.id,
    required this.startTime,
    this.endTime,
    List<DrivingEvent>? events,
    this.totalReadings = 0,
    this.totalMagnitude = 0.0,
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

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'totalReadings': totalReadings,
      'totalMagnitude': totalMagnitude,
      'events': jsonEncode(events.map((e) => e.toMap()).toList()),
      'score': calculateScore(),
    };
  }

  /// Create from Map (database row)
  factory DrivingSession.fromMap(Map<String, dynamic> map) {
    final List<dynamic> eventsJson = jsonDecode(map['events'] as String);
    final events = eventsJson
        .map((e) => DrivingEvent.fromMap(e as Map<String, dynamic>))
        .toList();

    return DrivingSession(
      id: map['id'] as int?,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] as int),
      endTime: map['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'] as int)
          : null,
      events: events,
      totalReadings: map['totalReadings'] as int,
      totalMagnitude: map['totalMagnitude'] as double,
    );
  }

  @override
  String toString() {
    return 'DrivingSession(duration: ${duration.inMinutes}min, score: ${calculateScore()}, events: ${events.length})';
  }
}
