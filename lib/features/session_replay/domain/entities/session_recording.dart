import 'package:equatable/equatable.dart';
import 'package:voo_logging/features/logging/domain/entities/log_entry.dart';

class SessionRecording extends Equatable {
  final String id;
  final String sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final String userId;
  final String? deviceInfo;
  final Map<String, dynamic> metadata;
  final List<SessionEvent> events;
  final SessionStatus status;
  final int sizeInBytes;

  const SessionRecording({
    required this.id,
    required this.sessionId,
    required this.startTime,
    this.endTime,
    required this.userId,
    this.deviceInfo,
    required this.metadata,
    required this.events,
    required this.status,
    required this.sizeInBytes,
  });

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  SessionRecording copyWith({
    String? id,
    String? sessionId,
    DateTime? startTime,
    DateTime? endTime,
    String? userId,
    String? deviceInfo,
    Map<String, dynamic>? metadata,
    List<SessionEvent>? events,
    SessionStatus? status,
    int? sizeInBytes,
  }) {
    return SessionRecording(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      userId: userId ?? this.userId,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      metadata: metadata ?? this.metadata,
      events: events ?? this.events,
      status: status ?? this.status,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        startTime,
        endTime,
        userId,
        deviceInfo,
        metadata,
        events,
        status,
        sizeInBytes,
      ];
}

enum SessionStatus {
  recording,
  paused,
  completed,
  error,
}

abstract class SessionEvent extends Equatable {
  final DateTime timestamp;
  final String type;

  const SessionEvent({
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toJson();

  @override
  List<Object?> get props => [timestamp, type];
}

class LogEvent extends SessionEvent {
  final LogEntry logEntry;

  const LogEvent({
    required super.timestamp,
    required this.logEntry,
  }) : super(type: 'log');

  @override
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'logEntry': {
          'id': logEntry.id,
          'timestamp': logEntry.timestamp.toIso8601String(),
          'message': logEntry.message,
          'level': logEntry.level.name,
          'category': logEntry.category,
          'tag': logEntry.tag,
          'metadata': logEntry.metadata,
          'error': logEntry.error?.toString(),
          'stackTrace': logEntry.stackTrace,
          'userId': logEntry.userId,
          'sessionId': logEntry.sessionId,
        },
      };

  @override
  List<Object?> get props => [...super.props, logEntry];
}

class UserActionEvent extends SessionEvent {
  final String action;
  final String? screen;
  final Map<String, dynamic>? properties;

  const UserActionEvent({
    required super.timestamp,
    required this.action,
    this.screen,
    this.properties,
  }) : super(type: 'user_action');

  @override
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'action': action,
        'screen': screen,
        'properties': properties,
      };

  @override
  List<Object?> get props => [...super.props, action, screen, properties];
}

class NetworkEvent extends SessionEvent {
  final String method;
  final String url;
  final int? statusCode;
  final Duration? duration;
  final Map<String, String>? headers;
  final Map<String, dynamic>? metadata;

  const NetworkEvent({
    required super.timestamp,
    required this.method,
    required this.url,
    this.statusCode,
    this.duration,
    this.headers,
    this.metadata,
  }) : super(type: 'network');

  @override
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'method': method,
        'url': url,
        'statusCode': statusCode,
        'duration': duration?.inMilliseconds,
        'headers': headers,
        'metadata': metadata,
      };

  @override
  List<Object?> get props => [...super.props, method, url, statusCode, duration, headers, metadata];
}

class ScreenNavigationEvent extends SessionEvent {
  final String fromScreen;
  final String toScreen;
  final Map<String, dynamic>? parameters;

  const ScreenNavigationEvent({
    required super.timestamp,
    required this.fromScreen,
    required this.toScreen,
    this.parameters,
  }) : super(type: 'navigation');

  @override
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'fromScreen': fromScreen,
        'toScreen': toScreen,
        'parameters': parameters,
      };

  @override
  List<Object?> get props => [...super.props, fromScreen, toScreen, parameters];
}

class AppStateEvent extends SessionEvent {
  final String state;
  final Map<String, dynamic>? details;

  const AppStateEvent({
    required super.timestamp,
    required this.state,
    this.details,
  }) : super(type: 'app_state');

  @override
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'state': state,
        'details': details,
      };

  @override
  List<Object?> get props => [...super.props, state, details];
}