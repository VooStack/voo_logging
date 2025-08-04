import 'package:voo_logging/src/data/repositories/logger_repository_impl.dart';
import 'package:voo_logging/src/domain/repositories/logger_repository.dart';
import 'package:voo_logging/voo_logging.dart';

class VooLogger {
  bool _initialized = false;
  factory VooLogger() => _instance;
  late final LoggerRepository _repository;
  Stream<LogEntry> get stream => _repository.stream;
  LoggerRepository get repository => _repository;
  VooLogger._internal();

  static final VooLogger _instance = VooLogger._internal();

  static Future<void> initialize({
    String? appName,
    String? appVersion,
    String? userId,
    LogLevel minimumLevel = LogLevel.verbose,
  }) async {
    if (_instance._initialized) return;
    _instance._initialized = true;
    _instance._repository = LoggerRepositoryImpl();
    await _instance._repository.initialize(
      appName: appName,
      appVersion: appVersion,
      userId: userId,
      minimumLevel: minimumLevel,
    );
  }

  static Future<void> verbose(String message, {String? category, String? tag, Map<String, dynamic>? metadata}) async {
    if (!_instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    await _instance._repository.verbose(message, category: category, tag: tag, metadata: metadata);
  }

  static Future<void> debug(String message, {String? category, String? tag, Map<String, dynamic>? metadata}) async {
    if (!_instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    await _instance._repository.debug(message, category: category, tag: tag, metadata: metadata);
  }

  static Future<void> info(String message, {String? category, String? tag, Map<String, dynamic>? metadata}) async {
    if (!_instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    await _instance._repository.info(message, category: category, tag: tag, metadata: metadata);
  }

  static Future<void> warning(String message, {String? category, String? tag, Map<String, dynamic>? metadata}) async {
    if (!_instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    await _instance._repository.warning(message, category: category, tag: tag, metadata: metadata);
  }

  static Future<void> error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    await _instance._repository.error(message, error: error, stackTrace: stackTrace, category: category, tag: tag, metadata: metadata);
  }

  static Future<void> fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    await _instance._repository.fatal(message, error: error, stackTrace: stackTrace, category: category, tag: tag, metadata: metadata);
  }

  static void log(String s, {required LogLevel level, String? category, required Map<String, Object> metadata, String? tag}) {
    if (!_instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    _instance._repository.log(s, level: level, category: category, metadata: metadata, tag: tag);
  }

  static Future<void> networkRequest(String s, String t, {required Map<String, String> headers, required Map<String, String> metadata}) async {
    if (!_instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    await _instance._repository.networkRequest(s, t, headers: headers, metadata: metadata);
  }

  static void userAction(String s, {required String screen, required Map<String, Object> properties}) {
    if (!_instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    _instance._repository.userAction(s, screen: screen, properties: properties);
  }

  static Future<void> networkResponse(
    int i,
    String s,
    Duration duration, {
    required Map<String, String> headers,
    required int contentLength,
    required Map<String, Object> metadata,
  }) async {
    if (!_instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    await _instance._repository.networkResponse(i, s, duration, headers: headers, contentLength: contentLength, metadata: metadata);
  }

  static void performance(String s, Duration duration, {required Map<String, Object> metrics}) {
    if (!_instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    _instance._repository.performance(s, duration, metrics: metrics);
  }

  static Future getStatistics() async {
    if (!_instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    return _instance._repository.getStatistics();
  }

  static Future exportLogs() async {
    if (!_instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    return _instance._repository.exportLogs();
  }

  static Future<void> clearLogs() async {
    if (!_instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    await _instance._repository.clearLogs();
  }

  static void setUserId(String newUserId) {
    if (!_instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    _instance._repository.setUserId(newUserId);
  }

  static void startNewSession() {
    if (!_instance._initialized) {
      throw StateError('VooLogger must be initialized before use');
    }
    _instance._repository.startNewSession();
  }
}
