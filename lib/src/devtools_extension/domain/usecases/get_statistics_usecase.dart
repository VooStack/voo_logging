import 'package:voo_logging/src/devtools_extension/core/usecases/usecase.dart';
import "package:voo_logging/src/domain/entities/log_filter.dart";
import "package:voo_logging/src/domain/entities/log_statistics.dart";
import 'package:voo_logging/src/devtools_extension/domain/repositories/log_repository.dart';

class GetStatisticsUseCase implements UseCase<LogStatistics, LogFilter?> {
  final LogRepository repository;

  GetStatisticsUseCase(this.repository);

  @override
  Future<LogStatistics> call(LogFilter? filter) async => repository.getStatistics(filter: filter);
}
