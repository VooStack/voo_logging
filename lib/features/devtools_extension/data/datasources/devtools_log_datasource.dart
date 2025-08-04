import 'dart:async';
import 'dart:developer' as developer;

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:voo_logging/core/domain/enums/log_level.dart';
import 'package:voo_logging/features/logging/data/models/log_entry_model.dart';

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
      developer.log('DevTools extension listening for logs...');

      // Listen to extension events from the VM service
      final stream = serviceManager.service?.onExtensionEvent;
      
      _extensionEventSubscription = stream?.listen((event) {
        if (event.extensionKind == 'voo_logger.log') {
          try {
            final data = event.extensionData?.data;
            if (data != null && data['entry'] != null) {
              final entry = data['entry'] as Map<String, dynamic>;
              
              // Convert the event data to LogEntryModel
              final logEntry = LogEntryModel(
                entry['id'] as String,
                DateTime.parse(entry['timestamp'] as String),
                entry['message'] as String,
                _parseLogLevel(entry['level'] as String),
                entry['category'] as String?,
                entry['tag'] as String?,
                entry['metadata'] as Map<String, dynamic>?,
                entry['error'],
                entry['stackTrace'] as String?,
                entry['userId'] as String?,
                entry['sessionId'] as String?,
              );
              
              _addLog(logEntry);
            }
          } catch (e) {
            developer.log('Error parsing log event: $e');
          }
        }
      });

      // Send initial connection log
      _addLog(
        LogEntryModel(
          'devtools_init',
          DateTime.now(),
          'DevTools extension connected successfully',
          LogLevel.info,
          'System',
          'DevTools',
          null, // metadata
          null, // error
          null, // stackTrace
          null, // userId
          null, // sessionId
        ),
      );
    } catch (e) {
      developer.log('Error connecting to VM service: $e');
    }
  }
  
  LogLevel _parseLogLevel(String levelName) {
    switch (levelName) {
      case 'verbose':
        return LogLevel.verbose;
      case 'debug':
        return LogLevel.debug;
      case 'info':
        return LogLevel.info;
      case 'warning':
        return LogLevel.warning;
      case 'error':
        return LogLevel.error;
      case 'fatal':
        return LogLevel.fatal;
      default:
        return LogLevel.info;
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
