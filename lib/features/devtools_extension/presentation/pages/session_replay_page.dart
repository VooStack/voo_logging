import 'package:flutter/material.dart';
import 'package:voo_logging/features/session_replay/domain/entities/session_recording.dart';
import 'package:voo_logging/features/devtools_extension/presentation/widgets/organisms/session_list_view.dart';
import 'package:voo_logging/features/devtools_extension/presentation/widgets/organisms/session_replay_view.dart';
import 'package:voo_logging/features/logging/domain/entities/voo_logger.dart';

class SessionReplayPage extends StatefulWidget {
  const SessionReplayPage({super.key});

  @override
  State<SessionReplayPage> createState() => _SessionReplayPageState();
}

class _SessionReplayPageState extends State<SessionReplayPage> {
  SessionRecording? _selectedSession;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _checkRecordingStatus();
  }

  void _checkRecordingStatus() {
    setState(() {
      _isRecording = VooLogger.isRecordingSession;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          _buildToolbar(context, theme),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 350,
                  child: SessionListView(
                    onSessionSelected: (session) {
                      setState(() {
                        _selectedSession = session;
                      });
                    },
                  ),
                ),
                Container(
                  width: 1,
                  color: theme.dividerColor,
                ),
                Expanded(
                  child: _selectedSession != null
                      ? SessionReplayView(session: _selectedSession!)
                      : _buildEmptyState(theme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Icon(Icons.replay, size: 32, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Session Replay', style: theme.textTheme.headlineSmall),
              Text(
                _isRecording ? 'Recording session...' : 'Select a session to replay',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const Spacer(),
          _buildRecordingControls(context, theme),
        ],
      ),
    );
  }

  Widget _buildRecordingControls(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        if (!_isRecording)
          ElevatedButton.icon(
            onPressed: () async {
              await VooLogger.startSessionRecording(
                metadata: {
                  'source': 'devtools',
                  'timestamp': DateTime.now().toIso8601String(),
                },
              );
              _checkRecordingStatus();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Session recording started')),
              );
            },
            icon: const Icon(Icons.fiber_manual_record, color: Colors.red),
            label: const Text('Start Recording'),
          )
        else ...[
          OutlinedButton.icon(
            onPressed: () async {
              await VooLogger.pauseSessionRecording();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Session recording paused')),
              );
            },
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              await VooLogger.stopSessionRecording();
              _checkRecordingStatus();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Session recording stopped')),
              );
            },
            icon: const Icon(Icons.stop),
            label: const Text('Stop Recording'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            setState(() {
              // Trigger rebuild to refresh session list
            });
          },
          tooltip: 'Refresh sessions',
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a session to replay',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a session from the list to view its timeline',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}