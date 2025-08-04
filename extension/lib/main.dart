import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voo_logger_devtools/data/datasources/devtools_log_datasource.dart';
import 'package:voo_logger_devtools/data/repositories/log_repository_impl.dart';
import 'package:voo_logger_devtools/domain/repositories/log_repository.dart';
import 'package:voo_logger_devtools/domain/usecases/export_logs_usecase.dart';
import 'package:voo_logger_devtools/domain/usecases/get_logs_usecase.dart';
import 'package:voo_logger_devtools/domain/usecases/get_statistics_usecase.dart';
import 'package:voo_logger_devtools/domain/usecases/stream_logs_usecase.dart';
import 'package:voo_logger_devtools/presentation/blocs/log_bloc.dart';
import 'package:voo_logger_devtools/presentation/pages/voo_logger_page.dart';

void main() {
  runApp(const VooLoggerDevToolsExtension());
}

class VooLoggerDevToolsExtension extends StatelessWidget {
  const VooLoggerDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Voo Logger DevTools',
        theme: ThemeData.dark(),
        home: DevToolsExtension(
          child: RepositoryProvider<LogRepository>(
            create: (context) {
              final dataSource = DevToolsLogDataSourceImpl();
              return LogRepositoryImpl(dataSource);
            },
            child: BlocProvider(
              create: (context) {
                final repository = context.read<LogRepository>();
                return LogBloc(
                  repository: repository,
                  getLogsUseCase: GetLogsUseCase(repository),
                  streamLogsUseCase: StreamLogsUseCase(repository),
                  getStatisticsUseCase: GetStatisticsUseCase(repository),
                  exportLogsUseCase: ExportLogsUseCase(repository),
                );
              },
              child: const VooLoggerPage(),
            ),
          ),
        ),
      );
}
