import 'dart:async';

import 'package:voo_logger_devtools/data/models/log_entry_model.dart';
import 'package:voo_logger_devtools/domain/entities/log_entry.dart';

abstract class DevToolsLogDataSource {
  Stream<LogEntryModel> get logStream;
  List<LogEntryModel> getCachedLogs();
  void clearCache();
}

class DevToolsLogDataSourceImpl implements DevToolsLogDataSource {
  final _logController = StreamController<LogEntryModel>.broadcast();
  final _cachedLogs = <LogEntryModel>[];
  final int maxCacheSize;

  StreamSubscription? _extensionEventSubscription;

  DevToolsLogDataSourceImpl({
    this.maxCacheSize = 10000,
  }) {
    _listenToExtensionEvents();
  }

  void _listenToExtensionEvents() {
    // Listen to events from the main app's VooLogger using the DevTools API
    // This would typically use the DevTools VM service connection
    // For now, we'll simulate receiving logs for testing

    // In a real implementation, you would:
    // 1. Connect to the VM service
    // 2. Listen to the 'voo_logger.log' extension events
    // 3. Parse and add the logs to the stream

    // Simulate some test logs for demonstration
    Future.delayed(const Duration(seconds: 1), () {
      _addLog(
        LogEntryModel(
          id: '1',
          timestamp: DateTime.now(),
          message: 'DevTools extension connected successfully',
          level: LogLevel.info,
          category: 'System',
          tag: 'DevTools',
        ),
      );
    });
  }

  void _addLog(LogEntryModel log) {
    _cachedLogs.add(log);

    // Maintain cache size
    if (_cachedLogs.length > maxCacheSize) {
      _cachedLogs.removeAt(0);
    }

    _logController.add(log);
  }

  @override
  Stream<LogEntryModel> get logStream => _logController.stream;

  @override
  List<LogEntryModel> getCachedLogs() => List.unmodifiable(_cachedLogs);

  @override
  void clearCache() {
    _cachedLogs.clear();
  }

  void dispose() {
    _extensionEventSubscription?.cancel();
    _logController.close();
  }
}
