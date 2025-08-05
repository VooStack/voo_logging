import 'package:voo_logging/core/domain/enums/log_level.dart';
import 'package:voo_logging/features/logging/data/repositories/logger_repository_impl.dart';
import 'package:voo_logging/features/logging/domain/entities/log_entry.dart';
import 'package:voo_logging/features/logging/domain/entities/voo_logger_interface.dart';
import 'package:voo_logging/features/logging/domain/repositories/logger_repository.dart';
import 'package:voo_logging/features/logging/presentation/voo_logger_extension_registration.dart';
import 'package:voo_logging/features/session_replay/data/repositories/session_recording_repository_impl.dart';
import 'package:voo_logging/features/session_replay/domain/repositories/session_recording_repository.dart';

/// Concrete implementation of VooLoggerInterface
class VooLoggerImpl implements VooLoggerInterface {
  bool _initialized = false;
  final LoggerRepository _repository;
  final SessionRecordingRepository _sessionRecorder;

  VooLoggerImpl({
    LoggerRepository? repository,
    SessionRecordingRepository? sessionRecorder,
  })  : _repository = repository ?? LoggerRepositoryImpl(),
        _sessionRecorder = sessionRecorder ?? SessionRecordingRepositoryImpl(
          logStream: (repository ?? LoggerRepositoryImpl()).stream,
        );

  @override
  Stream<LogEntry> get stream => _repository.stream;

  @override
  LoggerRepository get repository => _repository;

  @override
  SessionRecordingRepository get sessionRecorder => _sessionRecorder;

  @override
  bool get isRecordingSession => _sessionRecorder.isRecording;

  @override
  Future<void> initialize({
    String? appName,
    String? appVersion,
    String? userId,
    LogLevel minimumLevel = LogLevel.verbose,
  }) async {
    if (_initialized) return;

    // Register the extension for DevTools
    registerVooLoggerExtension();

    _initialized = true;

    await _repository.initialize(
      appName: appName,
      appVersion: appVersion,
      userId: userId,
      minimumLevel: minimumLevel,
    );
  }

  void _checkInitialized() {
    if (!_initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
  }

  @override
  Future<void> verbose(String message, {
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
  }) async {
    _checkInitialized();
    await _repository.verbose(message, category: category, tag: tag, metadata: metadata);
  }

  @override
  Future<void> debug(String message, {
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
  }) async {
    _checkInitialized();
    await _repository.debug(message, category: category, tag: tag, metadata: metadata);
  }

  @override
  Future<void> info(String message, {
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
  }) async {
    _checkInitialized();
    await _repository.info(message, category: category, tag: tag, metadata: metadata);
  }

  @override
  Future<void> warning(String message, {
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
  }) async {
    _checkInitialized();
    await _repository.warning(message, category: category, tag: tag, metadata: metadata);
  }

  @override
  Future<void> error(String message, {
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    _checkInitialized();
    await _repository.error(
      message,
      error: error,
      stackTrace: stackTrace,
      category: category,
      tag: tag,
      metadata: metadata,
    );
  }

  @override
  Future<void> fatal(String message, {
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    _checkInitialized();
    await _repository.fatal(
      message,
      error: error,
      stackTrace: stackTrace,
      category: category,
      tag: tag,
      metadata: metadata,
    );
  }

  @override
  Future<void> log(String message, {
    required LogLevel level,
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    _checkInitialized();
    // Convert Map<String, dynamic>? to Map<String, Object> for the repository
    final Map<String, Object> repoMetadata = metadata?.cast<String, Object>() ?? {};
    _repository.log(
      message,
      level: level,
      category: category,
      tag: tag,
      metadata: repoMetadata,
    );
  }

  @override
  Future<void> startSessionRecording({
    required String sessionId,
    required String userId,
    Map<String, dynamic>? metadata,
  }) async {
    _checkInitialized();
    await _sessionRecorder.startRecording(
      sessionId: sessionId,
      userId: userId,
      metadata: metadata,
    );
  }

  @override
  Future<void> stopSessionRecording() async {
    _checkInitialized();
    await _sessionRecorder.stopRecording();
  }

  @override
  Future<void> pauseSessionRecording() async {
    _checkInitialized();
    await _sessionRecorder.pauseRecording();
  }

  @override
  Future<void> resumeSessionRecording() async {
    _checkInitialized();
    await _sessionRecorder.resumeRecording();
  }

  @override
  void clearCache() {
    _checkInitialized();
    // Implementation depends on repository capabilities
  }

  @override
  Future<List<LogEntry>> getLogsByLevel(LogLevel level) async {
    _checkInitialized();
    // Implementation would filter logs by level
    throw UnimplementedError('getLogsByLevel not yet implemented');
  }

  @override
  Future<List<LogEntry>> getLogsByTimeRange(DateTime start, DateTime end) async {
    _checkInitialized();
    // Implementation would filter logs by time range
    throw UnimplementedError('getLogsByTimeRange not yet implemented');
  }

  @override
  Future<List<LogEntry>> searchLogs(String query) async {
    _checkInitialized();
    // Implementation would search logs
    throw UnimplementedError('searchLogs not yet implemented');
  }

  @override
  Future<void> exportLogs(String filePath) async {
    _checkInitialized();
    await _repository.exportLogs();
  }

  @override
  Future<void> deleteOldLogs({Duration? olderThan}) async {
    _checkInitialized();
    // Implementation would delete old logs
    throw UnimplementedError('deleteOldLogs not yet implemented');
  }
}