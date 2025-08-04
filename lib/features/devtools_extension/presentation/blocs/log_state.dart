import 'package:equatable/equatable.dart';
import 'package:voo_logging/features/logging/domain/entities/log_entry.dart';
import 'package:voo_logging/features/logging/domain/entities/log_filter.dart';
import 'package:voo_logging/features/logging/domain/entities/log_statistics.dart';

class LogState extends Equatable {
  final List<LogEntry> logs;
  final List<LogEntry> filteredLogs;
  final LogEntry? selectedLog;
  final LogFilter filter;
  final bool isLoading;
  final String? error;
  final bool autoScroll;
  final LogStatistics? statistics;
  final List<String> categories;
  final List<String> tags;
  final List<String> sessions;
  final String searchQuery;

  const LogState({
    this.logs = const [],
    this.filteredLogs = const [],
    this.selectedLog,
    this.filter = const LogFilter(),
    this.isLoading = false,
    this.error,
    this.autoScroll = true,
    this.statistics,
    this.categories = const [],
    this.tags = const [],
    this.sessions = const [],
    this.searchQuery = '',
  });

  LogState copyWith({
    List<LogEntry>? logs,
    List<LogEntry>? filteredLogs,
    LogEntry? selectedLog,
    bool clearSelectedLog = false,
    LogFilter? filter,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? autoScroll,
    LogStatistics? statistics,
    List<String>? categories,
    List<String>? tags,
    List<String>? sessions,
    String? searchQuery,
  }) =>
      LogState(
        logs: logs ?? this.logs,
        filteredLogs: filteredLogs ?? this.filteredLogs,
        selectedLog: clearSelectedLog ? null : (selectedLog ?? this.selectedLog),
        filter: filter ?? this.filter,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        autoScroll: autoScroll ?? this.autoScroll,
        statistics: statistics ?? this.statistics,
        categories: categories ?? this.categories,
        tags: tags ?? this.tags,
        sessions: sessions ?? this.sessions,
        searchQuery: searchQuery ?? this.searchQuery,
      );

  @override
  List<Object?> get props => [logs, filteredLogs, selectedLog, filter, isLoading, error, autoScroll, statistics, categories, tags, sessions, searchQuery];
}
