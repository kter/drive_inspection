import 'package:flutter/material.dart';
import '../models/driving_event.dart';
import '../models/driving_session.dart';

/// Displays the current driving score and statistics
class ScoreDisplay extends StatelessWidget {
  final DrivingSession? session;

  const ScoreDisplay({super.key, this.session});

  @override
  Widget build(BuildContext context) {
    if (session == null) {
      return const SizedBox.shrink();
    }

    final score = session!.calculateScore();
    final duration = session!.duration;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score and duration row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Score
              Row(
                children: [
                  const Text(
                    'スコア: ',
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(context, score),
                    ),
                  ),
                  Text(
                    ' / 100',
                    style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.outline),
                  ),
                ],
              ),

              // Duration
              Row(
                children: [
                  Icon(Icons.timer,
                      size: 20, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.outline),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Event counts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEventCount(
                context,
                '急加速',
                session!.getEventCount(DrivingEventType.hardAcceleration),
                Icons.trending_up,
                Theme.of(context).colorScheme.error,
              ),
              _buildEventCount(
                context,
                '急減速',
                session!.getEventCount(DrivingEventType.hardBraking),
                Icons.trending_down,
                Theme.of(context).colorScheme.secondary,
              ),
              _buildEventCount(
                context,
                '急ハンドル',
                session!.getEventCount(DrivingEventType.sharpTurn),
                Icons.turn_right,
                Theme.of(context).colorScheme.primary,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Average G-force
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '平均加速度: ',
                style: TextStyle(
                    fontSize: 14, color: Theme.of(context).colorScheme.outline),
              ),
              Text(
                '${session!.averageMagnitude.toStringAsFixed(2)}G',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build event count widget
  Widget _buildEventCount(BuildContext context, String label, int count,
      IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
              fontSize: 12, color: Theme.of(context).colorScheme.outline),
        ),
      ],
    );
  }

  /// Get color based on score
  Color _getScoreColor(BuildContext context, int score) {
    if (score >= 80) return Theme.of(context).colorScheme.primary;
    if (score >= 60) return Theme.of(context).colorScheme.secondary;
    return Theme.of(context).colorScheme.error;
  }

  /// Format duration as MM:SS
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
