import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/driving_session.dart';
import '../models/driving_event.dart';
import '../services/database_service.dart';

/// Screen displaying history of saved driving sessions
class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<DrivingSession> _sessions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  /// Load all sessions from database
  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sessions = await _databaseService.getAllSessions();
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load sessions: $e';
        _isLoading = false;
      });
    }
  }

  /// Delete a session with confirmation
  Future<void> _deleteSession(DrivingSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('セッション削除'),
        content: const Text('このセッションを削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true && session.id != null) {
      try {
        await _databaseService.deleteSession(session.id!);
        await _loadSessions(); // Reload list
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('削除に失敗しました: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('運転履歴'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSessions,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (_sessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '運転履歴はありません',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'セッションを開始して運転データを記録しましょう',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.builder(
        itemCount: _sessions.length,
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (context, index) {
          final session = _sessions[index];
          return _buildSessionCard(session);
        },
      ),
    );
  }

  Widget _buildSessionCard(DrivingSession session) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final score = session.calculateScore();
    final duration = session.duration;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: InkWell(
        onTap: () => _showSessionDetail(session),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and delete button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(session.startTime),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _deleteSession(session),
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Score and duration
              Row(
                children: [
                  // Score
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreColor(score).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'スコア: ',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(score),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Duration
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Event counts
              Row(
                children: [
                  _buildEventBadge(
                    '急加速',
                    session.getEventCount(DrivingEventType.hardAcceleration),
                    Colors.red,
                  ),
                  const SizedBox(width: 12),
                  _buildEventBadge(
                    '急減速',
                    session.getEventCount(DrivingEventType.hardBraking),
                    Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _buildEventBadge(
                    '急ハンドル',
                    session.getEventCount(DrivingEventType.sharpTurn),
                    Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Show detailed session information
  void _showSessionDetail(DrivingSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('セッション詳細'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                  '開始時刻', DateFormat('yyyy/MM/dd HH:mm:ss').format(session.startTime)),
              if (session.endTime != null)
                _buildDetailRow(
                    '終了時刻', DateFormat('yyyy/MM/dd HH:mm:ss').format(session.endTime!)),
              _buildDetailRow('運転時間', _formatDuration(session.duration)),
              _buildDetailRow('スコア', '${session.calculateScore()} / 100'),
              _buildDetailRow('平均加速度', '${session.averageMagnitude.toStringAsFixed(3)}G'),
              _buildDetailRow('総データ数', '${session.totalReadings}'),
              const Divider(),
              const Text(
                'イベント一覧',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (session.events.isEmpty)
                const Text('イベントなし', style: TextStyle(color: Colors.grey))
              else
                ...session.events.map((event) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        '${event.displayName}: ${event.magnitude.toStringAsFixed(2)}G (${event.penaltyPoints}pt)',
                        style: const TextStyle(fontSize: 12),
                      ),
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
