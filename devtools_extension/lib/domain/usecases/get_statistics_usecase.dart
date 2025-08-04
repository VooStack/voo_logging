import 'package:voo_logger_devtools/core/usecases/usecase.dart';
import 'package:voo_logger_devtools/domain/entities/log_filter.dart';
import 'package:voo_logger_devtools/domain/entities/log_statistics.dart';
import 'package:voo_logger_devtools/domain/repositories/log_repository.dart';

class GetStatisticsUseCase implements UseCase<LogStatistics, LogFilter?> {
  final LogRepository repository;

  GetStatisticsUseCase(this.repository);

  @override
  Future<LogStatistics> call(LogFilter? filter) async =>
      repository.getStatistics(filter: filter);
}
