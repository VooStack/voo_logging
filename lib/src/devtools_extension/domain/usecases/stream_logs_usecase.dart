import "package:voo_logging/src/domain/entities/log_entry.dart";
import 'package:voo_logging/src/devtools_extension/domain/repositories/log_repository.dart';

class StreamLogsUseCase {
  final LogRepository repository;

  StreamLogsUseCase(this.repository);

  Stream<LogEntry> call() => repository.logStream;
}
