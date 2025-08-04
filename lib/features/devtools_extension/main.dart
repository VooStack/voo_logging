import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_bloc.dart';
import 'package:voo_logging/features/devtools_extension/presentation/pages/voo_logger_page.dart';
import 'package:voo_logging/voo_logging.dart';

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
          child: BlocProvider(
            create: (context) => LogBloc(repository: VooLogger.instance.repository),
            child: const VooLoggerPage(),
          ),
        ),
      );
}
