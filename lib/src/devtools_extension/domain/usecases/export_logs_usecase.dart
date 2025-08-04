import 'package:voo_logging/src/devtools_extension/core/usecases/usecase.dart';
import "package:voo_logging/src/domain/entities/log_filter.dart";
import 'package:voo_logging/src/devtools_extension/domain/repositories/log_repository.dart';

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
