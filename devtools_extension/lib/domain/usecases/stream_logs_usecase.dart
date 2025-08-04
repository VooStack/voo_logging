import 'package:voo_logger_devtools/domain/entities/log_entry.dart';
import 'package:voo_logger_devtools/domain/repositories/log_repository.dart';

class StreamLogsUseCase {
  final LogRepository repository;

  StreamLogsUseCase(this.repository);

  Stream<LogEntry> call() => repository.logStream;
}
