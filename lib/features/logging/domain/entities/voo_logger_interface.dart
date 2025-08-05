import 'package:voo_logging/core/domain/enums/log_level.dart';
import 'package:voo_logging/features/logging/domain/entities/log_entry.dart';
import 'package:voo_logging/features/logging/domain/repositories/logger_repository.dart';
import 'package:voo_logging/features/session_replay/domain/repositories/session_recording_repository.dart';

/// Abstract interface for VooLogger to enable dependency injection and testing
abstract class VooLoggerInterface {
  Stream<LogEntry> get stream;
  LoggerRepository get repository;
  SessionRecordingRepository get sessionRecorder;
  bool get isRecordingSession;

  Future<void> initialize({
    String? appName,
    String? appVersion,
    String? userId,
    LogLevel minimumLevel = LogLevel.verbose,
  });

  Future<void> verbose(String message, {
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
  });

  Future<void> debug(String message, {
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
  });

  Future<void> info(String message, {
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
  });

  Future<void> warning(String message, {
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
  });

  Future<void> error(String message, {
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  });

  Future<void> fatal(String message, {
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  });

  Future<void> log(
    String message, {
    required LogLevel level,
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  });

  Future<void> startSessionRecording({
    required String sessionId,
    required String userId,
    Map<String, dynamic>? metadata,
  });

  Future<void> stopSessionRecording();

  Future<void> pauseSessionRecording();

  Future<void> resumeSessionRecording();

  void clearCache();

  Future<List<LogEntry>> getLogsByLevel(LogLevel level);

  Future<List<LogEntry>> getLogsByTimeRange(DateTime start, DateTime end);

  Future<List<LogEntry>> searchLogs(String query);

  Future<void> exportLogs(String filePath);

  Future<void> deleteOldLogs({Duration? olderThan});
}