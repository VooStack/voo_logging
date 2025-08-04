import 'package:equatable/equatable.dart';

enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  fatal;

  int get priority {
    switch (this) {
      case LogLevel.verbose:
        return 0;
      case LogLevel.debug:
        return 1;
      case LogLevel.info:
        return 2;
      case LogLevel.warning:
        return 3;
      case LogLevel.error:
        return 4;
      case LogLevel.fatal:
        return 5;
    }
  }

  String get displayName {
    switch (this) {
      case LogLevel.verbose:
        return 'VERBOSE';
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.fatal:
        return 'FATAL';
    }
  }
}

class LogEntry extends Equatable {
  final String id;
  final DateTime timestamp;
  final String message;
  final LogLevel level;
  final String? category;
  final String? tag;
  final Map<String, dynamic>? metadata;
  final String? error;
  final String? stackTrace;
  final String? userId;
  final String? sessionId;

  const LogEntry({
    required this.id,
    required this.timestamp,
    required this.message,
    required this.level,
    this.category,
    this.tag,
    this.metadata,
    this.error,
    this.stackTrace,
    this.userId,
    this.sessionId,
  });

  @override
  List<Object?> get props => [
        id,
        timestamp,
        message,
        level,
        category,
        tag,
        metadata,
        error,
        stackTrace,
        userId,
        sessionId,
      ];
}
