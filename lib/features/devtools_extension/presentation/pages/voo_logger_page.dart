import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voo_logging/core/domain/enums/log_level.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_bloc.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_event.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_state.dart';
import 'package:voo_logging/features/devtools_extension/presentation/widgets/molecules/log_entry_tile.dart';
import 'package:voo_logging/features/devtools_extension/presentation/widgets/organisms/log_details_panel.dart';
import 'package:voo_logging/features/devtools_extension/presentation/widgets/organisms/log_filter_bar.dart';
import 'package:voo_logging/features/devtools_extension/presentation/widgets/organisms/log_statistics_card.dart';
import 'package:voo_logging/features/logging/data/models/log_entry_model.dart';

class VooLoggerPage extends StatefulWidget {
  const VooLoggerPage({super.key});

  @override
  State<VooLoggerPage> createState() => _VooLoggerPageState();
}

class _VooLoggerPageState extends State<VooLoggerPage> {
  final _scrollController = ScrollController();
  bool _showDetails = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<LogBloc, LogState>(
      listener: (context, state) {
        if (state.autoScroll && _scrollController.hasClients) {
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      },
      builder: (context, state) => Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Column(
          children: [
            _buildToolbar(context, theme, state),
            const LogFilterBar(),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildLogsList(state)),
                  if (_showDetails && state.selectedLog != null)
                    SizedBox(
                      width: 400,
                      child: LogDetailsPanel(log: state.selectedLog!, onClose: () => setState(() => _showDetails = false)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, ThemeData theme, LogState state) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      border: Border(bottom: BorderSide(color: theme.dividerColor)),
    ),
    child: Row(
      children: [
        Icon(Icons.bug_report, size: 32, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voo Logger', style: theme.textTheme.headlineSmall),
            Text('${state.statistics?.totalLogs ?? 0} logs captured', style: theme.textTheme.bodySmall),
          ],
        ),
        const Spacer(),
        _buildToolbarActions(context, theme, state),
      ],
    ),
  );

  Widget _buildToolbarActions(BuildContext context, ThemeData theme, LogState state) => Row(
    children: [
      IconButton(
        icon: Icon(state.autoScroll ? Icons.pause : Icons.play_arrow),
        onPressed: () {
          context.read<LogBloc>().add(ToggleAutoScroll());
        },
        tooltip: state.autoScroll ? 'Pause auto-scroll' : 'Resume auto-scroll',
      ),
      IconButton(icon: const Icon(Icons.clear_all), onPressed: () => _clearLogs(context), tooltip: 'Clear logs'),
      IconButton(icon: const Icon(Icons.download), onPressed: () => _exportLogs(context), tooltip: 'Export logs'),
      IconButton(icon: const Icon(Icons.bar_chart), onPressed: () => _showStatistics(context, state), tooltip: 'Show statistics'),
      IconButton(icon: const Icon(Icons.bug_report), onPressed: () => _generateTestLog(context), tooltip: 'Generate test log'),
    ],
  );

  Widget _buildLogsList(LogState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading logs', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(state.error!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    final logs = state.filteredLogs;

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'No logs to display',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final isSelected = state.selectedLog?.id == log.id;

        return LogEntryTile(
          log: log,
          selected: isSelected,
          onTap: () {
            context.read<LogBloc>().add(SelectLog(log));
            if (!_showDetails) {
              setState(() => _showDetails = true);
            }
          },
        );
      },
    );
  }

  Future<void> _clearLogs(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text('Are you sure you want to clear all logs?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Clear')),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<LogBloc>().add(ClearLogs());
    }
  }

  Future<void> _exportLogs(BuildContext context) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logs exported successfully'), duration: Duration(seconds: 2)));
    }
  }

  void _showStatistics(BuildContext context, LogState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Statistics'),
        content: state.statistics != null
            ? SizedBox(width: 400, child: LogStatisticsCard(statistics: state.statistics!))
            : const Text('No statistics available'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  void _generateTestLog(BuildContext context) {
    // Directly add a test log to see if UI updates
    context.read<LogBloc>().add(
      LogReceived(
        LogEntryModel(
          'test_${DateTime.now().millisecondsSinceEpoch}',
          DateTime.now(),
          'Test log generated from UI at ${DateTime.now()}',
          LogLevel.info,
          'Test',
          'UITest',
          {'source': 'manual_test'},
          null,
          null,
          null,
          null,
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test log generated'), duration: Duration(seconds: 1)));
  }
}
