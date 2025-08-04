import 'package:voo_logging/src/devtools_extension/core/usecases/usecase.dart';
import "package:voo_logging/src/domain/entities/log_entry.dart";
import "package:voo_logging/src/domain/entities/log_filter.dart";
import 'package:voo_logging/src/devtools_extension/domain/repositories/log_repository.dart';

class GetLogsUseCase implements UseCase<List<LogEntry>, GetLogsParams> {
  final LogRepository repository;

  GetLogsUseCase(this.repository);

  @override
  Future<List<LogEntry>> call(GetLogsParams params) async => repository.getLogs(
        filter: params.filter,
        limit: params.limit,
        offset: params.offset,
      );
}

class GetLogsParams {
  final LogFilter? filter;
  final int limit;
  final int offset;

  const GetLogsParams({
    this.filter,
    this.limit = 1000,
    this.offset = 0,
  });
}
