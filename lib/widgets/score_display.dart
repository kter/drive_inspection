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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
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
                      color: _getScoreColor(score),
                    ),
                  ),
                  const Text(
                    ' / 100',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),

              // Duration
              Row(
                children: [
                  const Icon(Icons.timer, size: 20, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                '急加速',
                session!.getEventCount(DrivingEventType.hardAcceleration),
                Icons.trending_up,
                Colors.red,
              ),
              _buildEventCount(
                '急減速',
                session!.getEventCount(DrivingEventType.hardBraking),
                Icons.trending_down,
                Colors.orange,
              ),
              _buildEventCount(
                '急ハンドル',
                session!.getEventCount(DrivingEventType.sharpTurn),
                Icons.turn_right,
                Colors.blue,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Average G-force
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '平均加速度: ',
                style: TextStyle(fontSize: 14, color: Colors.grey),
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
  Widget _buildEventCount(
      String label, int count, IconData icon, Color color) {
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
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  /// Get color based on score
  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  /// Format duration as MM:SS
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
