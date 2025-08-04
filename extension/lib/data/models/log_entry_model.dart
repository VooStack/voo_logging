import 'package:voo_logger_devtools/domain/entities/log_entry.dart';

class LogEntryModel {
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

  const LogEntryModel({
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

  factory LogEntryModel.fromJson(Map<String, dynamic> json) => LogEntryModel(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        message: json['message'] as String,
        level: LogLevel.values.firstWhere(
          (e) => e.name == json['level'],
          orElse: () => LogLevel.info,
        ),
        category: json['category'] as String?,
        tag: json['tag'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
        error: json['error'] as String?,
        stackTrace: json['stackTrace'] as String?,
        userId: json['userId'] as String?,
        sessionId: json['sessionId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'message': message,
        'level': level.name,
        'category': category,
        'tag': tag,
        'metadata': metadata,
        'error': error,
        'stackTrace': stackTrace,
        'userId': userId,
        'sessionId': sessionId,
      };

  LogEntry toEntity() => LogEntry(
        id: id,
        timestamp: timestamp,
        message: message,
        level: level,
        category: category,
        tag: tag,
        metadata: metadata,
        error: error,
        stackTrace: stackTrace,
        userId: userId,
        sessionId: sessionId,
      );

  factory LogEntryModel.fromEntity(LogEntry entity) => LogEntryModel(
        id: entity.id,
        timestamp: entity.timestamp,
        message: entity.message,
        level: entity.level,
        category: entity.category,
        tag: entity.tag,
        metadata: entity.metadata,
        error: entity.error,
        stackTrace: entity.stackTrace,
        userId: entity.userId,
        sessionId: entity.sessionId,
      );
}
