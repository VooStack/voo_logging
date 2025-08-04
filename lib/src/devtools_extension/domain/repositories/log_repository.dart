import "package:voo_logging/src/domain/entities/log_entry.dart";
import "package:voo_logging/src/domain/entities/log_filter.dart";
import "package:voo_logging/src/domain/entities/log_statistics.dart";

abstract class LogRepository {
  Stream<LogEntry> get logStream;

  Future<List<LogEntry>> getLogs({
    LogFilter? filter,
    int limit = 1000,
    int offset = 0,
  });

  Future<LogStatistics> getStatistics({LogFilter? filter});

  Future<List<String>> getUniqueCategories();

  Future<List<String>> getUniqueTags();

  Future<List<String>> getUniqueSessions();

  Future<List<String>> getUniqueUsers();

  Future<void> clearLogs({LogFilter? filter});

  Future<String> exportLogs({
    LogFilter? filter,
    ExportFormat format = ExportFormat.json,
  });

  Future<void> importLogs(String data, ImportFormat format);
}

enum ExportFormat { json, csv, txt }

enum ImportFormat { json }
