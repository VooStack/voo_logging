import 'package:voo_logging/features/devtools_extension/domain/repositories/log_repository.dart';
import 'package:voo_logging/features/logging/domain/entities/log_entry.dart';

class StreamLogsUseCase {
  final LogRepository repository;

  StreamLogsUseCase(this.repository);

  Stream<LogEntry> call() => repository.logStream;
}
