/// Types of driving events that affect the driving score
enum DrivingEventType {
  hardAcceleration,  // 急加速
  hardBraking,       // 急減速
  sharpTurn,         // 急ハンドル
}

/// Represents a single driving event with its severity
class DrivingEvent {
  final DrivingEventType type;
  final DateTime timestamp;
  final double magnitude; // G-force magnitude

  DrivingEvent({
    required this.type,
    required this.timestamp,
    required this.magnitude,
  });

  /// Get display name in Japanese
  String get displayName {
    switch (type) {
      case DrivingEventType.hardAcceleration:
        return '急加速';
      case DrivingEventType.hardBraking:
        return '急減速';
      case DrivingEventType.sharpTurn:
        return '急ハンドル';
    }
  }

  /// Calculate penalty points for this event
  int get penaltyPoints {
    // Base penalty: 5 points
    // Additional penalty based on severity
    final basePenalty = 5;
    final severityPenalty = ((magnitude - 0.3) / 0.1 * 2).round().clamp(0, 10);
    return basePenalty + severityPenalty;
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'magnitude': magnitude,
    };
  }

  /// Create from Map (database row or JSON)
  factory DrivingEvent.fromMap(Map<String, dynamic> map) {
    return DrivingEvent(
      type: DrivingEventType.values.firstWhere(
        (e) => e.name == map['type'],
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      magnitude: map['magnitude'] as double,
    );
  }

  @override
  String toString() {
    return 'DrivingEvent(type: $displayName, magnitude: ${magnitude.toStringAsFixed(2)}G, penalty: ${penaltyPoints}pt)';
  }
}
