/// Statistics about stored logs
/// Same as before, but now powered by Sembast
class LogStatistics {
  final int totalLogs;
  final Map<String, int> levelCounts;
  final Map<String, int> categoryCounts;
  final DateTime? earliestLog;
  final DateTime? latestLog;

  LogStatistics({required this.totalLogs, required this.levelCounts, required this.categoryCounts, this.earliestLog, this.latestLog});

  /// Duration covered by logs
  Duration? get timeSpan {
    if (earliestLog == null || latestLog == null) return null;
    return latestLog!.difference(earliestLog!);
  }

  /// Logs per day average
  double? get logsPerDay {
    final span = timeSpan;
    if (span == null || span.inDays == 0) return null;
    return totalLogs / span.inDays;
  }
}
