import 'package:voo_logging/features/logging/data/repositories/logger_repository_impl.dart';
import 'package:voo_logging/features/logging/domain/entities/voo_logger_impl.dart';
import 'package:voo_logging/features/logging/domain/entities/voo_logger_interface.dart';
import 'package:voo_logging/features/logging/presentation/voo_logger_extension_registration.dart';
import 'package:voo_logging/features/session_replay/data/repositories/session_recording_repository_impl.dart';
import 'package:voo_logging/features/session_replay/domain/repositories/session_recording_repository.dart';
import 'package:voo_logging/voo_logging.dart';

class VooLogger {
  bool _initialized = false;
  factory VooLogger() => instance;
  
  // Internal logger implementation - can be overridden for testing
  static VooLoggerInterface? _loggerInstance;
  
  // Default implementation
  static final VooLoggerImpl _defaultLogger = VooLoggerImpl();
  
  // Get the current logger instance (either injected or default)
  static VooLoggerInterface get _logger => _loggerInstance ?? _defaultLogger;
  
  // Public getter for accessing the logger (for SessionReplayTracker)
  static VooLoggerInterface get logger => _logger;
  
  final LoggerRepository _repository = LoggerRepositoryImpl();
  final SessionRecordingRepository _sessionRecorder = SessionRecordingRepositoryImpl();
  
  Stream<LogEntry> get stream => _logger.stream;
  LoggerRepository get repository => _logger.repository;
  SessionRecordingRepository get sessionRecorder => _logger.sessionRecorder;
  
  VooLogger._internal();

  static final VooLogger instance = VooLogger._internal();
  
  /// Set a custom logger implementation (useful for testing)
  static void setLogger(VooLoggerInterface logger) {
    _loggerInstance = logger;
  }
  
  /// Reset to default logger implementation
  static void resetLogger() {
    _loggerInstance = null;
  }

  static Future<void> initialize({String? appName, String? appVersion, String? userId, LogLevel minimumLevel = LogLevel.verbose}) async {
    await _logger.initialize(appName: appName, appVersion: appVersion, userId: userId, minimumLevel: minimumLevel);
    instance._initialized = true;
  }

  static Future<void> verbose(String message, {String? category, String? tag, Map<String, dynamic>? metadata}) async {
    await _logger.verbose(message, category: category, tag: tag, metadata: metadata);
  }

  static Future<void> debug(String message, {String? category, String? tag, Map<String, dynamic>? metadata}) async {
    await _logger.debug(message, category: category, tag: tag, metadata: metadata);
  }

  static Future<void> info(String message, {String? category, String? tag, Map<String, dynamic>? metadata}) async {
    await _logger.info(message, category: category, tag: tag, metadata: metadata);
  }

  static Future<void> warning(String message, {String? category, String? tag, Map<String, dynamic>? metadata}) async {
    await _logger.warning(message, category: category, tag: tag, metadata: metadata);
  }

  static Future<void> error(String message, {Object? error, StackTrace? stackTrace, String? category, String? tag, Map<String, dynamic>? metadata}) async {
    await _logger.error(message, error: error, stackTrace: stackTrace, category: category, tag: tag, metadata: metadata);
  }

  static Future<void> fatal(String message, {Object? error, StackTrace? stackTrace, String? category, String? tag, Map<String, dynamic>? metadata}) async {
    await _logger.fatal(message, error: error, stackTrace: stackTrace, category: category, tag: tag, metadata: metadata);
  }

  static Future<void> log(String s, {required LogLevel level, String? category, Map<String, dynamic>? metadata, String? tag}) async {
    await _logger.log(s, level: level, category: category, metadata: metadata, tag: tag);
  }

  static Future<void> networkRequest(String s, String t, {required Map<String, String> headers, required Map<String, String> metadata}) async {
    if (!instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    await instance._repository.networkRequest(s, t, headers: headers, metadata: metadata);
  }

  static void userAction(String s, {required String screen, required Map<String, Object> properties}) {
    if (!instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    instance._repository.userAction(s, screen: screen, properties: properties);
  }

  static Future<void> networkResponse(
    int i,
    String s,
    Duration duration, {
    required Map<String, String> headers,
    required int contentLength,
    required Map<String, Object> metadata,
  }) async {
    if (!instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    await instance._repository.networkResponse(i, s, duration, headers: headers, contentLength: contentLength, metadata: metadata);
  }

  static void performance(String s, Duration duration, {required Map<String, Object> metrics}) {
    if (!instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    instance._repository.performance(s, duration, metrics: metrics);
  }

  static Future getStatistics() async {
    if (!instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    return instance._repository.getStatistics();
  }

  static Future exportLogs() async {
    if (!instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    return instance._repository.exportLogs();
  }

  static Future<void> clearLogs() async {
    if (!instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    await instance._repository.clearLogs();
  }

  static void setUserId(String newUserId) {
    if (!instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    instance._repository.setUserId(newUserId);
  }

  static void startNewSession() {
    if (!instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    instance._repository.startNewSession();
  }

  // Session Recording Methods
  static Future<void> startSessionRecording({Map<String, dynamic>? metadata}) async {
    if (!instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    
    final sessionId = instance._repository.sessionId;
    final userId = instance._repository.userId ?? 'anonymous';
    
    await instance._sessionRecorder.startRecording(
      sessionId: sessionId,
      userId: userId,
      metadata: metadata,
    );
  }

  static Future<void> stopSessionRecording() async {
    if (!instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    await instance._sessionRecorder.stopRecording();
  }

  static Future<void> pauseSessionRecording() async {
    if (!instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    await instance._sessionRecorder.pauseRecording();
  }

  static Future<void> resumeSessionRecording() async {
    if (!instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    await instance._sessionRecorder.resumeRecording();
  }

  static bool get isRecordingSession => _logger.isRecordingSession;

  static Stream<dynamic> get sessionRecordingStream => _logger.sessionRecorder.recordingStream;
}
