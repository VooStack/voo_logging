import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voo_logging/src/devtools_extension/di/injection_container.dart';
import 'package:voo_logging/src/devtools_extension/presentation/pages/voo_logger_page.dart';

void main() {
  runApp(const VooLoggerDevToolsExtension());
}

class VooLoggerDevToolsExtension extends StatelessWidget {
  const VooLoggerDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    final di = InjectionContainer();
    
    return MaterialApp(
      title: 'Voo Logger DevTools',
      theme: ThemeData.dark(),
      home: DevToolsExtension(
        child: BlocProvider(
          create: (_) => di.createLogBloc(),
          child: const VooLoggerPage(),
        ),
      ),
    );
  }
}
