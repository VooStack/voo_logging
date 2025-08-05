import 'package:flutter/material.dart';
import 'package:voo_logging/features/session_replay/domain/entities/session_recording.dart';
import 'package:voo_logging/features/logging/domain/entities/voo_logger.dart';
import 'package:intl/intl.dart';

class SessionListView extends StatefulWidget {
  final void Function(SessionRecording) onSessionSelected;

  const SessionListView({
    super.key,
    required this.onSessionSelected,
  });

  @override
  State<SessionListView> createState() => _SessionListViewState();
}

class _SessionListViewState extends State<SessionListView> {
  List<SessionRecording> _sessions = [];
  bool _isLoading = true;
  String? _selectedSessionId;
  final _dateFormat = DateFormat('MMM d, yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    
    try {
      final sessions = await VooLogger.instance.sessionRecorder.getRecordings(
        limit: 50,
      );
      
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sessions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          _buildHeader(theme),
          _buildStorageInfo(theme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildSessionList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Text(
            'Sessions',
            style: theme.textTheme.titleMedium,
          ),
          const Spacer(),
          Text(
            '${_sessions.length} sessions',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStorageInfo(ThemeData theme) {
    return FutureBuilder<int>(
      future: VooLogger.instance.sessionRecorder.getTotalStorageSize(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final sizeInMB = snapshot.data! / (1024 * 1024);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          child: Row(
            children: [
              Icon(
                Icons.storage,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Storage: ${sizeInMB.toStringAsFixed(2)} MB',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _cleanupOldSessions,
                child: const Text('Cleanup'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionList(ThemeData theme) {
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No sessions recorded',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final isSelected = session.id == _selectedSessionId;
        
        return _buildSessionTile(session, isSelected, theme);
      },
    );
  }

  Widget _buildSessionTile(SessionRecording session, bool isSelected, ThemeData theme) {
    final statusColor = _getStatusColor(session.status);
    final duration = session.duration;
    
    return InkWell(
      onTap: () {
        setState(() => _selectedSessionId = session.id);
        widget.onSessionSelected(session);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
          border: Border(
            left: BorderSide(
              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
              width: 3,
            ),
            bottom: BorderSide(color: theme.dividerColor),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _dateFormat.format(session.startTime),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'User: ${session.userId}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '${session.events.length} events',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _formatDuration(duration),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (session.metadata.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: session.metadata.entries.take(2).map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.recording:
        return Colors.red;
      case SessionStatus.paused:
        return Colors.orange;
      case SessionStatus.completed:
        return Colors.green;
      case SessionStatus.error:
        return Colors.red.shade900;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  Future<void> _cleanupOldSessions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cleanup Old Sessions'),
        content: const Text(
          'This will delete all sessions older than 7 days. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await VooLogger.instance.sessionRecorder.deleteOldRecordings(
        const Duration(days: 7),
      );
      _loadSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Old sessions deleted')),
        );
      }
    }
  }
}