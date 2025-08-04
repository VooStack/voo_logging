import 'package:voo_logging/src/data/models/log_entry_model.dart';
import 'package:voo_logging/src/domain/entities/log_entry.dart';

extension LogEntryModelExtensions on LogEntryModel {
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
}
