import 'package:voo_logging/core/data/usecases/usecase.dart';
import 'package:voo_logging/features/devtools_extension/domain/repositories/log_repository.dart';
import 'package:voo_logging/features/logging/domain/entities/log_filter.dart';
import 'package:voo_logging/features/logging/domain/entities/log_statistics.dart';

class GetStatisticsUseCase implements UseCase<LogStatistics, LogFilter?> {
  final LogRepository repository;

  GetStatisticsUseCase(this.repository);

  @override
  Future<LogStatistics> call(LogFilter? filter) async => repository.getStatistics(filter: filter);
}
