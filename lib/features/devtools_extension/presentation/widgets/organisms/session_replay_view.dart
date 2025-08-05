import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voo_logging/features/devtools_extension/presentation/widgets/molecules/session_event_tile.dart';
import 'package:voo_logging/features/devtools_extension/presentation/widgets/molecules/session_timeline.dart';
import 'package:voo_logging/features/logging/domain/entities/voo_logger.dart';
import 'package:voo_logging/features/session_replay/domain/entities/session_recording.dart';
import 'package:voo_logging/features/session_replay/presentation/export/session_exporter.dart';

class SessionReplayView extends StatefulWidget {
  final SessionRecording session;

  const SessionReplayView({super.key, required this.session});

  @override
  State<SessionReplayView> createState() => _SessionReplayViewState();
}

class _SessionReplayViewState extends State<SessionReplayView> {
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  int _currentEventIndex = 0;
  final _scrollController = ScrollController();
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildHeader(theme),
        _buildPlaybackControls(theme),
        SessionTimeline(
          events: widget.session.events,
          currentIndex: _currentEventIndex,
          onSeek: (index) {
            setState(() => _currentEventIndex = index);
            _scrollToEvent(index);
          },
        ),
        Expanded(child: _buildEventsList(theme)),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle_outline, size: 32, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Session: ${widget.session.sessionId}', style: theme.textTheme.titleMedium),
                    Text('Started: ${_dateFormat.format(widget.session.startTime)}', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              _buildExportButton(theme),
            ],
          ),
          const SizedBox(height: 12),
          _buildSessionInfo(theme),
        ],
      ),
    );
  }

  Widget _buildSessionInfo(ThemeData theme) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildInfoChip(theme, Icons.person, 'User: ${widget.session.userId}'),
        _buildInfoChip(theme, Icons.timer, 'Duration: ${_formatDuration(widget.session.duration)}'),
        _buildInfoChip(theme, Icons.event_note, 'Events: ${widget.session.events.length}'),
        if (widget.session.deviceInfo != null) _buildInfoChip(theme, Icons.devices, 'Device: ${widget.session.deviceInfo}'),
      ],
    );
  }

  Widget _buildInfoChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: _currentEventIndex > 0 ? () => _jumpToEvent(_currentEventIndex - 1) : null,
            tooltip: 'Previous event',
          ),
          IconButton(icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow), onPressed: _togglePlayback, tooltip: _isPlaying ? 'Pause' : 'Play'),
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: _currentEventIndex < widget.session.events.length - 1 ? () => _jumpToEvent(_currentEventIndex + 1) : null,
            tooltip: 'Next event',
          ),
          const SizedBox(width: 16),
          Text('Event ${_currentEventIndex + 1} of ${widget.session.events.length}', style: theme.textTheme.bodySmall),
          const Spacer(),
          Text('Speed:', style: theme.textTheme.bodySmall),
          const SizedBox(width: 8),
          DropdownButton<double>(
            value: _playbackSpeed,
            items: const [
              DropdownMenuItem(value: 0.5, child: Text('0.5x')),
              DropdownMenuItem(value: 1.0, child: Text('1x')),
              DropdownMenuItem(value: 2.0, child: Text('2x')),
              DropdownMenuItem(value: 5.0, child: Text('5x')),
            ],
            onChanged: (value) {
              setState(() => _playbackSpeed = value!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.session.events.length,
      itemBuilder: (context, index) {
        final event = widget.session.events[index];
        final isActive = index == _currentEventIndex;

        return SessionEventTile(event: event, index: index, isActive: isActive, onTap: () => _jumpToEvent(index));
      },
    );
  }

  Widget _buildExportButton(ThemeData theme) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'export':
            _exportSession();
            break;
          case 'delete':
            _deleteSession();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'export',
          child: Row(children: [Icon(Icons.download), SizedBox(width: 8), Text('Export Session')]),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Session', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _togglePlayback() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _startPlayback();
    }
  }

  void _startPlayback() async {
    while (_isPlaying && _currentEventIndex < widget.session.events.length - 1) {
      await Future.delayed(Duration(milliseconds: (1000 / _playbackSpeed).round()));

      if (!_isPlaying) break;

      setState(() {
        _currentEventIndex++;
      });
      _scrollToEvent(_currentEventIndex);
    }

    setState(() => _isPlaying = false);
  }

  void _jumpToEvent(int index) {
    setState(() {
      _currentEventIndex = index;
      _isPlaying = false;
    });
    _scrollToEvent(index);
  }

  void _scrollToEvent(int index) {
    if (_scrollController.hasClients) {
      final position = index * 80.0; // Approximate height of each tile
      _scrollController.animateTo(position, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Future<void> _exportSession() async {
    try {
      // Get the session data for export
      final exportData = await VooLogger.instance.sessionRecorder.getRecording(widget.session.id).then((session) async {
        if (session == null) throw Exception('Session not found');

        final storage = (VooLogger.instance.sessionRecorder as dynamic)._storage;
        return await storage.exportSession(session.id);
      });

      // Use the cross-platform exporter
      await SessionExporter.exportSession(
        exportData: exportData as Map<String, dynamic>,
        sessionId: widget.session.sessionId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session exported successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting session: $e')));
      }
    }
  }

  Future<void> _deleteSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text('Are you sure you want to delete this session?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await VooLogger.instance.sessionRecorder.deleteRecording(widget.session.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session deleted')));
          // Notify parent to refresh the list
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting session: $e')));
        }
      }
    }
  }
}
