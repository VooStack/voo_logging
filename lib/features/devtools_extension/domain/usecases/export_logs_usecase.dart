import 'package:voo_logging/core/data/usecases/usecase.dart';
import 'package:voo_logging/features/devtools_extension/domain/repositories/log_repository.dart';
import 'package:voo_logging/features/logging/domain/entities/log_filter.dart';

class ExportLogsUseCase implements UseCase<String, ExportLogsParams> {
  final LogRepository repository;

  ExportLogsUseCase(this.repository);

  @override
  Future<String> call(ExportLogsParams params) async => repository.exportLogs(
        filter: params.filter,
        format: params.format,
      );
}

class ExportLogsParams {
  final LogFilter? filter;
  final ExportFormat format;

  const ExportLogsParams({
    this.filter,
    this.format = ExportFormat.json,
  });
}
