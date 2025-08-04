import 'dart:async';
import 'dart:convert';

import 'package:voo_logging/core/domain/extensions/log_level_extensions.dart';
import 'package:voo_logging/features/devtools_extension/data/datasources/devtools_log_datasource.dart';
import 'package:voo_logging/features/devtools_extension/domain/repositories/log_repository.dart';
import 'package:voo_logging/features/logging/data/models/log_entry_model_extensions.dart';
import 'package:voo_logging/features/logging/domain/entities/log_entry.dart';
import 'package:voo_logging/features/logging/domain/entities/log_filter.dart';
import 'package:voo_logging/features/logging/domain/entities/log_filter_extensions.dart';
import 'package:voo_logging/features/logging/domain/entities/log_statistics.dart';
import 'package:voo_logging/features/logging/domain/entities/log_statistics_extensions.dart';

class LogRepositoryImpl implements LogRepository {
  final DevToolsLogDataSource dataSource;

  LogRepositoryImpl(this.dataSource);

  @override
  Stream<LogEntry> get logStream => dataSource.logStream.map((model) => model.toEntity());

  @override
  Future<List<LogEntry>> getLogs({
    LogFilter? filter,
    int limit = 1000,
    int offset = 0,
  }) async {
    final allLogs = dataSource.getCachedLogs().map((model) => model.toEntity()).toList();

    // Apply filter
    var filteredLogs = allLogs;
    if (filter != null) {
      filteredLogs = allLogs.where((log) => filter.matches(log)).toList();
    }

    // Sort by timestamp descending
    filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Apply pagination
    final startIndex = offset;
    final endIndex = (startIndex + limit).clamp(0, filteredLogs.length);

    if (startIndex >= filteredLogs.length) {
      return [];
    }

    return filteredLogs.sublist(startIndex, endIndex);
  }

  @override
  Future<LogStatistics> getStatistics({LogFilter? filter}) async {
    final logs = await getLogs(filter: filter, limit: 999999);
    return LogStatisticsExtensions.fromLogs(logs);
  }

  @override
  Future<List<String>> getUniqueCategories() async {
    final logs = dataSource.getCachedLogs();
    final categories = <String>{};

    for (final log in logs) {
      if (log.category != null) {
        categories.add(log.category!);
      }
    }

    return categories.toList()..sort();
  }

  @override
  Future<List<String>> getUniqueTags() async {
    final logs = dataSource.getCachedLogs();
    final tags = <String>{};

    for (final log in logs) {
      if (log.tag != null) {
        tags.add(log.tag!);
      }
    }

    return tags.toList()..sort();
  }

  @override
  Future<List<String>> getUniqueSessions() async {
    final logs = dataSource.getCachedLogs();
    final sessions = <String>{};

    for (final log in logs) {
      if (log.sessionId != null) {
        sessions.add(log.sessionId!);
      }
    }

    return sessions.toList()..sort();
  }

  @override
  Future<List<String>> getUniqueUsers() async {
    final logs = dataSource.getCachedLogs();
    final users = <String>{};

    for (final log in logs) {
      if (log.userId != null) {
        users.add(log.userId!);
      }
    }

    return users.toList()..sort();
  }

  @override
  Future<void> clearLogs({LogFilter? filter}) async {
    if (filter == null) {
      dataSource.clearCache();
    } else {
      // For filtered clearing, we'd need to implement selective removal
      // For now, this is not supported in the cache
      throw UnimplementedError('Filtered log clearing is not yet implemented');
    }
  }

  @override
  Future<String> exportLogs({
    LogFilter? filter,
    ExportFormat format = ExportFormat.json,
  }) async {
    final logs = await getLogs(filter: filter, limit: 999999);

    switch (format) {
      case ExportFormat.json:
        return _exportAsJson(logs);
      case ExportFormat.csv:
        return _exportAsCsv(logs);
      case ExportFormat.txt:
        return _exportAsText(logs);
    }
  }

  String _exportAsJson(List<LogEntry> logs) {
    final exportData = {
      'logs': logs
          .map(
            (log) => {
              'id': log.id,
              'timestamp': log.timestamp.toIso8601String(),
              'level': log.level.name,
              'message': log.message,
              'category': log.category,
              'tag': log.tag,
              'metadata': log.metadata,
              'error': log.error?.toString(),
              'stackTrace': log.stackTrace,
              'userId': log.userId,
              'sessionId': log.sessionId,
            },
          )
          .toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'totalLogs': logs.length,
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  String _exportAsCsv(List<LogEntry> logs) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln(
      'Timestamp,Level,Category,Tag,Message,Error,User ID,Session ID',
    );

    // Data
    for (final log in logs) {
      final timestamp = log.timestamp.toIso8601String();
      final level = log.level.displayName;
      final category = _escapeCsv(log.category ?? '');
      final tag = _escapeCsv(log.tag ?? '');
      final message = _escapeCsv(log.message);
      final error = _escapeCsv(log.error?.toString() ?? '');
      final userId = _escapeCsv(log.userId ?? '');
      final sessionId = _escapeCsv(log.sessionId ?? '');

      buffer.writeln(
        '$timestamp,$level,$category,$tag,$message,$error,$userId,$sessionId',
      );
    }

    return buffer.toString();
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _exportAsText(List<LogEntry> logs) {
    final buffer = StringBuffer();

    for (final log in logs) {
      buffer.writeln('=' * 80);
      buffer.writeln('Timestamp: ${log.timestamp.toIso8601String()}');
      buffer.writeln('Level: ${log.level.displayName}');
      if (log.category != null) buffer.writeln('Category: ${log.category}');
      if (log.tag != null) buffer.writeln('Tag: ${log.tag}');
      buffer.writeln('Message: ${log.message}');
      if (log.error != null) buffer.writeln('Error: ${log.error}');
      if (log.stackTrace != null) {
        buffer.writeln('Stack Trace:');
        buffer.writeln(log.stackTrace);
      }
      if (log.metadata != null && log.metadata!.isNotEmpty) {
        buffer.writeln('Metadata: ${json.encode(log.metadata)}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  @override
  Future<void> importLogs(String data, ImportFormat format) async {
    // Not implemented for DevTools extension
    throw UnimplementedError(
      'Log import is not supported in DevTools extension',
    );
  }
}
