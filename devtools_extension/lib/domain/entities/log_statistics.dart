import 'package:equatable/equatable.dart';

import 'package:voo_logger_devtools/domain/entities/log_entry.dart';

class LogStatistics extends Equatable {
  final int totalLogs;
  final Map<LogLevel, int> levelCounts;
  final Map<String, int> categoryCounts;
  final Map<String, int> tagCounts;
  final DateTime? oldestLog;
  final DateTime? newestLog;

  const LogStatistics({
    required this.totalLogs,
    required this.levelCounts,
    required this.categoryCounts,
    required this.tagCounts,
    this.oldestLog,
    this.newestLog,
  });

  factory LogStatistics.empty() => const LogStatistics(
        totalLogs: 0,
        levelCounts: {},
        categoryCounts: {},
        tagCounts: {},
      );

  factory LogStatistics.fromLogs(List<LogEntry> logs) {
    if (logs.isEmpty) return LogStatistics.empty();

    final levelCounts = <LogLevel, int>{};
    final categoryCounts = <String, int>{};
    final tagCounts = <String, int>{};

    DateTime? oldestLog;
    DateTime? newestLog;

    for (final log in logs) {
      levelCounts[log.level] = (levelCounts[log.level] ?? 0) + 1;

      if (log.category != null) {
        categoryCounts[log.category!] =
            (categoryCounts[log.category!] ?? 0) + 1;
      }

      if (log.tag != null) {
        tagCounts[log.tag!] = (tagCounts[log.tag!] ?? 0) + 1;
      }

      if (oldestLog == null || log.timestamp.isBefore(oldestLog)) {
        oldestLog = log.timestamp;
      }

      if (newestLog == null || log.timestamp.isAfter(newestLog)) {
        newestLog = log.timestamp;
      }
    }

    return LogStatistics(
      totalLogs: logs.length,
      levelCounts: levelCounts,
      categoryCounts: categoryCounts,
      tagCounts: tagCounts,
      oldestLog: oldestLog,
      newestLog: newestLog,
    );
  }

  @override
  List<Object?> get props => [
        totalLogs,
        levelCounts,
        categoryCounts,
        tagCounts,
        oldestLog,
        newestLog,
      ];
}
