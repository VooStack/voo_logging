import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voo_logging/features/devtools_extension/data/datasources/simple_devtools_log_datasource.dart';
import 'package:voo_logging/features/devtools_extension/data/repositories/devtools_log_repository_impl.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_bloc.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_event.dart';
import 'package:voo_logging/features/devtools_extension/presentation/pages/voo_logger_page.dart';
import 'package:voo_logging/features/devtools_extension/presentation/pages/session_replay_page.dart';

Future<void> main() async {
  runApp(const VooLoggerDevToolsExtension());
}

class VooLoggerDevToolsExtension extends StatelessWidget {
  const VooLoggerDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    // Create the data source and repository
    // TEMPORARY: Using simple datasource to test if UI updates work
    final dataSource = SimpleDevToolsLogDataSource();
    // final dataSource = DevToolsLogDataSourceImpl(); // Original - not working yet
    final repository = DevToolsLogRepositoryImpl(dataSource: dataSource);

    return MaterialApp(
      title: 'Voo Logger DevTools',
      theme: ThemeData.dark(),
      home: DevToolsExtension(
        child: BlocProvider(
          create: (context) => LogBloc(repository: repository)..add(LoadLogs()),
          child: const VooLoggerTabbedPage(),
        ),
      ),
    );
  }
}

class VooLoggerTabbedPage extends StatelessWidget {
  const VooLoggerTabbedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Voo Logger'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.bug_report),
                text: 'Logs',
              ),
              Tab(
                icon: Icon(Icons.replay),
                text: 'Session Replay',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            VooLoggerPage(),
            SessionReplayPage(),
          ],
        ),
      ),
    );
  }
}
