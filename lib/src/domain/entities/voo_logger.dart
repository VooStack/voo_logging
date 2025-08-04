// lib/src/logger.dart

import 'dart:developer' as developer;
import 'dart:math';

import 'package:voo_logging/src/data/enums/log_level.dart';
import 'package:voo_logging/src/data/sources/local/local_log_storage.dart';
import 'package:voo_logging/src/domain/entities/Log_statistics.dart';
import 'package:voo_logging/src/domain/entities/log_entry.dart';

/// The main logger class that provides the public API
///
/// Design principles:
/// 1. Simple to use - developers shouldn't need to think about storage
/// 2. Non-blocking - logging never slows down the app
/// 3. Context-aware - automatically tracks user/session info
/// 4. DevTools friendly - integrates seamlessly with Flutter debugging
class VooLogger {
  static LocalLogStorage? _storage;
  static String? _currentUserId;
  static String? _currentSessionId;
  static LogLevel _minimumLevel = LogLevel.debug;
  static bool _enabled = true;
  static String? _appName;
  static String? _appVersion;

  // For generating unique log IDs
  static final _random = Random();
  static int _logCounter = 0;

  /// Initialize the logger
  /// Call this once in your main() function
  ///
  /// Why initialize?
  /// - Sets up database connection
  /// - Configures global settings
  /// - Establishes session tracking
  static Future<void> initialize({
    LogLevel minimumLevel = LogLevel.debug,
    String? userId,
    String? sessionId,
    String? appName,
    String? appVersion,
    bool enabled = true,
  }) async {
    _minimumLevel = minimumLevel;
    _currentUserId = userId;
    _currentSessionId = sessionId ?? _generateSessionId();
    _appName = appName;
    _appVersion = appVersion;
    _enabled = enabled;

    // Initialize storage
    _storage = LocalLogStorage();

    // Log initialization
    await _logInternal(
      'VooLogger initialized',
      category: 'System',
      tag: 'Init',
      metadata: {'minimumLevel': minimumLevel.name, 'userId': userId, 'sessionId': _currentSessionId, 'appName': appName, 'appVersion': appVersion},
    );
  }

  /// Generate a unique session ID
  /// Why? Helps group logs from the same app session for debugging
  static String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = _random.nextInt(1000);
    return '${timestamp}_$randomPart';
  }

  /// Generate a unique log ID
  /// Why? Ensures each log entry can be uniquely identified
  static String _generateLogId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final counter = ++_logCounter;
    final randomPart = _random.nextInt(1000);
    return '${timestamp}_${counter}_$randomPart';
  }

  /// Internal logging method that does the actual work
  /// Why separate? Keeps the public API clean while handling complexity here
  static Future<void> _logInternal(
    String message, {
    LogLevel level = LogLevel.info,
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
    String? userId,
    String? sessionId,
  }) async {
    // Early return if logging is disabled or below minimum level
    if (!_enabled || level.priority < _minimumLevel.priority) return;

    // Create log entry
    final entry = LogEntry(
      id: _generateLogId(),
      timestamp: DateTime.now(),
      message: message,
      level: level,
      category: category,
      tag: tag,
      metadata: _enrichMetadata(metadata),
      error: error,
      stackTrace: stackTrace?.toString(),
      userId: userId ?? _currentUserId,
      sessionId: sessionId ?? _currentSessionId,
    );

    // Log to DevTools console (synchronous for immediate visibility)
    _logToDevTools(entry);

    // Store in database (asynchronous to avoid blocking)
    // Why unawaited? We don't want to block the calling code
    await _storage?.insertLog(entry).catchError((Object error) {
      developer.log(
        'Failed to store log: $error',
        name: 'AwesomeLogger',
        level: 1000, // Error level
      );
      return <String, Object?>{};
    });

    // Send to DevTools extension if available
    _sendToDevToolsExtension(entry);
  }

  /// Enrich metadata with system information
  /// Why? Provides valuable context for debugging
  static Map<String, dynamic>? _enrichMetadata(Map<String, dynamic>? userMetadata) {
    final enriched = <String, dynamic>{};

    // Add system info
    if (_appName != null) enriched['appName'] = _appName;
    if (_appVersion != null) enriched['appVersion'] = _appVersion;
    enriched['timestamp'] = DateTime.now().toIso8601String();

    // Add user metadata last so it can override system info if needed
    if (userMetadata != null) {
      enriched.addAll(userMetadata);
    }

    return enriched.isEmpty ? null : enriched;
  }

  /// Log to DevTools console
  /// Why separate method? Different formatting and error handling
  static void _logToDevTools(LogEntry entry) {
    try {
      // Format message for DevTools
      var formattedMessage = entry.message;
      if (entry.tag != null) {
        formattedMessage = '[${entry.tag}] $formattedMessage';
      }

      developer.log(
        formattedMessage,
        name: entry.category ?? 'AwesomeLogger',
        level: _getDevToolsLevel(entry.level),
        error: entry.error,
        stackTrace: entry.stackTrace != null ? StackTrace.fromString(entry.stackTrace!) : null,
        sequenceNumber: entry.timestamp.millisecondsSinceEpoch,
      );
    } catch (e) {
      // If DevTools logging fails, fail silently
      // We don't want logging to crash the app
    }
  }

  /// Convert our log levels to DevTools levels
  /// Why? DevTools expects specific numeric ranges
  static int _getDevToolsLevel(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return 500; // FINE
      case LogLevel.debug:
        return 700; // CONFIG
      case LogLevel.info:
        return 800; // INFO
      case LogLevel.warning:
        return 900; // WARNING
      case LogLevel.error:
        return 1000; // SEVERE
      case LogLevel.fatal:
        return 1200; // SHOUT
    }
  }

  /// Send log entry to DevTools extension
  /// Why? Enables our custom DevTools UI to receive real-time logs
  static void _sendToDevToolsExtension(LogEntry entry) {
    try {
      // Send event that the DevTools extension can listen to
      developer.postEvent('voo_logger.log', {
        'entry': {
          'id': entry.id,
          'timestamp': entry.timestamp.toIso8601String(),
          'message': entry.message,
          'level': entry.level.name,
          'category': entry.category,
          'tag': entry.tag,
          'metadata': entry.metadata,
          'error': entry.error,
          'stackTrace': entry.stackTrace,
          'userId': entry.userId,
          'sessionId': entry.sessionId,
        },
        'timestamp': entry.timestamp.millisecondsSinceEpoch,
      });
    } catch (e) {
      // Fail silently if extension isn't available
    }
  }

  // Public API methods - these are what developers actually use

  /// Log a verbose message
  /// Use for: Very detailed debugging info (usually disabled in production)
  static Future<void> verbose(String message, {String? category, String? tag, Map<String, dynamic>? metadata}) async {
    await _logInternal(message, level: LogLevel.verbose, category: category, tag: tag, metadata: metadata);
  }

  /// Log a debug message
  /// Use for: Development debugging information
  static Future<void> debug(String message, {String? category, String? tag, Map<String, dynamic>? metadata}) async {
    await _logInternal(message, level: LogLevel.debug, category: category, tag: tag, metadata: metadata);
  }

  /// Log an info message
  /// Use for: General application flow information
  static Future<void> info(String message, {String? category, String? tag, Map<String, dynamic>? metadata}) async {
    await _logInternal(message, category: category, tag: tag, metadata: metadata);
  }

  /// Log a warning message
  /// Use for: Unexpected but non-breaking situations
  static Future<void> warning(String message, {String? category, String? tag, Map<String, dynamic>? metadata}) async {
    await _logInternal(message, level: LogLevel.warning, category: category, tag: tag, metadata: metadata);
  }

  /// Log an error message
  /// Use for: Errors that don't crash the app
  static Future<void> error(String message, {Object? error, StackTrace? stackTrace, String? category, String? tag, Map<String, dynamic>? metadata}) async {
    await _logInternal(message, level: LogLevel.error, category: category, tag: tag, metadata: metadata, error: error, stackTrace: stackTrace);
  }

  /// Log a fatal error message
  /// Use for: Critical errors that might crash the app
  static Future<void> fatal(String message, {Object? error, StackTrace? stackTrace, String? category, String? tag, Map<String, dynamic>? metadata}) async {
    await _logInternal(message, level: LogLevel.fatal, category: category, tag: tag, metadata: metadata, error: error, stackTrace: stackTrace);
  }

  /// Generic log method for custom levels
  /// Use when: You need more control over the logging process
  static Future<void> log(
    String message, {
    LogLevel level = LogLevel.info,
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    await _logInternal(message, level: level, category: category, tag: tag, metadata: metadata, error: error, stackTrace: stackTrace);
  }

  // Configuration methods

  /// Update the current user ID
  /// Why? User context is crucial for debugging user-specific issues
  static Future<void> setUserId(String? userId) async => _currentUserId = userId;

  /// Start a new session
  /// Why? Helps group logs when debugging specific user sessions
  static void startNewSession([String? sessionId]) {
    _currentSessionId = sessionId ?? _generateSessionId();
    info('New session started', category: 'System', tag: 'Session', metadata: {'sessionId': _currentSessionId});
  }

  /// Set minimum log level
  /// Why? Control verbosity in different environments (dev vs prod)
  static Future<void> setMinimumLevel(LogLevel level) async => _minimumLevel = level;

  /// Enable/disable logging
  /// Why? Quick way to turn off all logging if needed
  static Future<void> setEnabled(bool enabled) async => _enabled = enabled;

  // Query methods - delegate to storage

  /// Query stored logs
  /// This is where the real power comes in - searchable log history!
  static Future<List<LogEntry>> queryLogs({
    List<LogLevel>? levels,
    List<String>? categories,
    List<String>? tags,
    String? messagePattern,
    DateTime? startTime,
    DateTime? endTime,
    String? userId,
    String? sessionId,
    int limit = 1000,
    int offset = 0,
    bool ascending = false,
  }) async =>
      await _storage?.queryLogs(
        levels: levels,
        categories: categories,
        tags: tags,
        messagePattern: messagePattern,
        startTime: startTime,
        endTime: endTime,
        userId: userId,
        sessionId: sessionId,
        limit: limit,
        offset: offset,
        ascending: ascending,
      ) ??
      [];

  /// Get statistics about stored logs
  static Future<LogStatistics> getStatistics() async => await _storage?.getLogStatistics() ?? LogStatistics(totalLogs: 0, levelCounts: {}, categoryCounts: {});

  /// Get unique categories for filtering UI
  static Future<List<String>> getCategories() async => await _storage?.getUniqueCategories() ?? [];

  /// Get unique tags for filtering UI
  static Future<List<String>> getTags() async => await _storage?.getUniqueTags() ?? [];

  /// Get unique session IDs for filtering UI
  static Future<List<String>> getSessions() async => await _storage?.getUniqueSessions() ?? [];

  /// Clear stored logs
  static Future<void> clearLogs({DateTime? olderThan, List<LogLevel>? levels, List<String>? categories}) async {
    await _storage?.clearLogs(olderThan: olderThan, levels: levels, categories: categories);
  }

  /// Export logs as JSON
  static Future<String> exportLogs({List<LogLevel>? levels, DateTime? startTime, DateTime? endTime}) async =>
      await _storage?.exportLogs(levels: levels, startTime: startTime, endTime: endTime) ?? '{"logs": [], "totalLogs": 0}';

  // Utility methods for common logging patterns

  /// Log a network request
  /// Why a helper? Network logging is very common and has a standard pattern
  static Future<void> networkRequest(String method, String url, {Map<String, String>? headers, dynamic body, Map<String, dynamic>? metadata}) async {
    await info(
      '$method $url',
      category: 'Network',
      tag: 'Request',
      metadata: {'method': method, 'url': url, 'headers': headers, 'hasBody': body != null, ...?metadata},
    );
  }

  /// Log a network response
  static Future<void> networkResponse(
    int statusCode,
    String url,
    Duration duration, {
    Map<String, String>? headers,
    int? contentLength,
    Map<String, dynamic>? metadata,
  }) async {
    final level = statusCode >= 400 ? LogLevel.error : LogLevel.info;

    await log(
      'Response $statusCode for $url (${duration.inMilliseconds}ms)',
      level: level,
      category: 'Network',
      tag: 'Response',
      metadata: {'statusCode': statusCode, 'url': url, 'duration': duration.inMilliseconds, 'headers': headers, 'contentLength': contentLength, ...?metadata},
    );
  }

  /// Log user actions for analytics
  static Future<void> userAction(String action, {String? screen, Map<String, dynamic>? properties}) async {
    await info(
      'User action: $action',
      category: 'Analytics',
      tag: 'UserAction',
      metadata: {'action': action, 'screen': screen, 'properties': properties, 'userId': _currentUserId},
    );
  }

  /// Log performance metrics
  static Future<void> performance(String operation, Duration duration, {Map<String, dynamic>? metrics}) async {
    final level = duration.inMilliseconds > 1000 ? LogLevel.warning : LogLevel.info;

    await log(
      '$operation completed in ${duration.inMilliseconds}ms',
      level: level,
      category: 'Performance',
      tag: operation,
      metadata: {'operation': operation, 'duration': duration.inMilliseconds, 'metrics': metrics},
    );
  }
}
