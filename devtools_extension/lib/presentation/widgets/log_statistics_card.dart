import 'package:flutter/material.dart';

import 'package:voo_logger_devtools/domain/entities/log_entry.dart';
import 'package:voo_logger_devtools/domain/entities/log_statistics.dart';

class LogStatisticsCard extends StatelessWidget {
  final LogStatistics statistics;

  const LogStatisticsCard({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummary(theme),
        const SizedBox(height: 16),
        _buildLevelBreakdown(theme),
        if (statistics.categoryCounts.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTopCategories(theme),
        ],
        if (statistics.tagCounts.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTopTags(theme),
        ],
      ],
    );
  }

  Widget _buildSummary(ThemeData theme) {
    final duration =
        statistics.newestLog != null && statistics.oldestLog != null
            ? statistics.newestLog!.difference(statistics.oldestLog!)
            : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatRow('Total Logs', statistics.totalLogs.toString()),
            if (duration != null)
              _buildStatRow('Duration', _formatDuration(duration)),
            if (statistics.oldestLog != null)
              _buildStatRow(
                'First Log',
                _formatDateTime(statistics.oldestLog!),
              ),
            if (statistics.newestLog != null)
              _buildStatRow(
                'Last Log',
                _formatDateTime(statistics.newestLog!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBreakdown(ThemeData theme) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log Levels',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...LogLevel.values.map((level) {
                final count = statistics.levelCounts[level] ?? 0;
                if (count == 0) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getLevelColor(level),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(level.displayName),
                      ),
                      Text(
                        count.toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );

  Widget _buildTopCategories(ThemeData theme) {
    final sortedCategories = statistics.categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Categories',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...sortedCategories.take(5).map(
                (entry) => _buildStatRow(entry.key, entry.value.toString())),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTags(ThemeData theme) {
    final sortedTags = statistics.tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Tags',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...sortedTags.take(5).map(
                (entry) => _buildStatRow(entry.key, entry.value.toString())),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return Colors.grey;
      case LogLevel.debug:
        return Colors.blue;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.fatal:
        return Colors.purple;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.month}/${dateTime.day} '
      '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}';
}
