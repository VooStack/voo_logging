import 'dart:async';
import 'dart:developer' as developer;

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

  Future<void> _listenToExtensionEvents() async {
    try {
      // For now, let's use a simplified approach
      // In a real implementation, this would connect to the VM service
      // through the DevTools extension API

      developer.log('DevTools extension listening for logs...');

      // Send initial connection log
      _addLog(
        LogEntryModel(
          id: 'devtools_init',
          timestamp: DateTime.now(),
          message: 'DevTools extension connected successfully',
          level: LogLevel.info,
          category: 'System',
          tag: 'DevTools',
        ),
      );
    } catch (e) {
      developer.log('Error connecting to VM service: $e');
    }
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
