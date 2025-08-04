import 'package:voo_logging/src/devtools_extension/data/datasources/devtools_log_datasource.dart';
import 'package:voo_logging/src/devtools_extension/data/repositories/log_repository_impl.dart';
import 'package:voo_logging/src/devtools_extension/domain/repositories/log_repository.dart';
import 'package:voo_logging/src/devtools_extension/domain/usecases/export_logs_usecase.dart';
import 'package:voo_logging/src/devtools_extension/domain/usecases/get_logs_usecase.dart';
import 'package:voo_logging/src/devtools_extension/domain/usecases/get_statistics_usecase.dart';
import 'package:voo_logging/src/devtools_extension/domain/usecases/stream_logs_usecase.dart';
import 'package:voo_logging/src/devtools_extension/presentation/blocs/log_bloc.dart';

/// Simple dependency injection container
class InjectionContainer {
  static final InjectionContainer _instance = InjectionContainer._internal();
  factory InjectionContainer() => _instance;
  InjectionContainer._internal();

  // Lazy initialization
  late final DevToolsLogDataSource _dataSource = DevToolsLogDataSourceImpl();
  late final LogRepository _repository = LogRepositoryImpl(_dataSource);
  
  // Use cases
  late final GetLogsUseCase getLogsUseCase = GetLogsUseCase(_repository);
  late final StreamLogsUseCase streamLogsUseCase = StreamLogsUseCase(_repository);
  late final GetStatisticsUseCase getStatisticsUseCase = GetStatisticsUseCase(_repository);
  late final ExportLogsUseCase exportLogsUseCase = ExportLogsUseCase(_repository);

  // Factory methods
  LogBloc createLogBloc() => LogBloc(
    repository: _repository,
    getLogsUseCase: getLogsUseCase,
    streamLogsUseCase: streamLogsUseCase,
    getStatisticsUseCase: getStatisticsUseCase,
    exportLogsUseCase: exportLogsUseCase,
  );

  // Cleanup
  void dispose() {
    if (_dataSource is DevToolsLogDataSourceImpl) {
      (_dataSource as DevToolsLogDataSourceImpl).dispose();
    }
  }
}