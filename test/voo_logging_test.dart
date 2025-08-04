import 'package:flutter_test/flutter_test.dart';
import 'package:voo_logging/voo_logging.dart';

void main() {
  group('VooLogger Initialization Tests', () {
    test('should initialize with default values', () async {
      await VooLogger.initialize();

      // Test that we can log after initialization
      expect(() async => VooLogger.info('Test message'), returnsNormally);
    });

    test('should initialize with custom values', () async {
      await VooLogger.initialize(minimumLevel: LogLevel.warning, userId: 'test_user_123', appName: 'Test App', appVersion: '1.0.0');

      // Verify initialization was successful
      expect(() async => VooLogger.info('Test message'), returnsNormally);
    });

    test('should respect minimum log level', () async {
      await VooLogger.initialize(minimumLevel: LogLevel.warning);

      // These should be filtered out (below minimum level)
      await VooLogger.verbose('This should be filtered');
      await VooLogger.debug('This should be filtered');
      await VooLogger.info('This should be filtered');

      // These should pass through
      await VooLogger.warning('This should be logged');
      await VooLogger.error('This should be logged');
      await VooLogger.fatal('This should be logged');

      // Query logs to verify
      final logs = await VooLogger.queryLogs();
      expect(logs.where((log) => log.level.priority < LogLevel.warning.priority), isEmpty);
    });
  });

  group('VooLogger Logging Tests', () {
    setUp(() async {
      await VooLogger.initialize(minimumLevel: LogLevel.verbose, appName: 'Test App', userId: 'test_user');
      await VooLogger.clearLogs();
    });

    test('should log verbose messages', () async {
      const message = 'Verbose test message';
      await VooLogger.verbose(message, category: 'Test', tag: 'Unit');

      final logs = await VooLogger.queryLogs();
      expect(logs.any((log) => log.message == message && log.level == LogLevel.verbose), isTrue);
    });

    test('should log debug messages', () async {
      const message = 'Debug test message';
      await VooLogger.debug(message, category: 'Test', tag: 'Unit');

      final logs = await VooLogger.queryLogs();
      expect(logs.any((log) => log.message == message && log.level == LogLevel.debug), isTrue);
    });

    test('should log info messages', () async {
      const message = 'Info test message';
      await VooLogger.info(message, category: 'Test', tag: 'Unit');

      final logs = await VooLogger.queryLogs();
      expect(logs.any((log) => log.message == message && log.level == LogLevel.info), isTrue);
    });

    test('should log warning messages', () async {
      const message = 'Warning test message';
      await VooLogger.warning(message, category: 'Test', tag: 'Unit');

      final logs = await VooLogger.queryLogs();
      expect(logs.any((log) => log.message == message && log.level == LogLevel.warning), isTrue);
    });

    test('should log error messages with stack trace', () async {
      const message = 'Error test message';
      final error = Exception('Test exception');
      final stackTrace = StackTrace.current;

      await VooLogger.error(message, error: error, stackTrace: stackTrace, category: 'Test', tag: 'Unit');

      final logs = await VooLogger.queryLogs();
      final errorLog = logs.firstWhere((log) => log.message == message);

      expect(errorLog.level, equals(LogLevel.error));
      expect(errorLog.error, equals(error));
      expect(errorLog.stackTrace, isNotNull);
    });

    test('should log fatal messages', () async {
      const message = 'Fatal test message';
      await VooLogger.fatal(message, category: 'Test', tag: 'Unit');

      final logs = await VooLogger.queryLogs();
      expect(logs.any((log) => log.message == message && log.level == LogLevel.fatal), isTrue);
    });

    test('should include metadata in logs', () async {
      const message = 'Message with metadata';
      final metadata = {
        'key1': 'value1',
        'key2': 123,
        'key3': true,
        'nested': {'inner': 'value'},
      };

      await VooLogger.info(message, metadata: metadata);

      final logs = await VooLogger.queryLogs();
      final log = logs.firstWhere((log) => log.message == message);

      expect(log.metadata?['key1'], equals('value1'));
      expect(log.metadata?['key2'], equals(123));
      expect(log.metadata?['key3'], equals(true));
      expect(log.metadata?['nested'], equals({'inner': 'value'}));
    });
  });

  group('VooLogger Query Tests', () {
    setUp(() async {
      await VooLogger.initialize(minimumLevel: LogLevel.verbose);
      await VooLogger.clearLogs();

      // Add test data
      await VooLogger.verbose('Verbose message', category: 'Network', tag: 'Request');
      await VooLogger.debug('Debug message', category: 'Database', tag: 'Query');
      await VooLogger.info('Info message', category: 'UI', tag: 'Button');
      await VooLogger.warning('Warning message', category: 'Network', tag: 'Response');
      await VooLogger.error('Error message', category: 'Database', tag: 'Connection');
      await VooLogger.fatal('Fatal message', category: 'System', tag: 'Crash');

      // Add some delay to ensure different timestamps
      await Future.delayed(const Duration(milliseconds: 10));
    });

    test('should filter by log level', () async {
      final errorAndAbove = await VooLogger.queryLogs(levels: [LogLevel.error, LogLevel.fatal]);

      expect(errorAndAbove.length, equals(2));
      expect(errorAndAbove.every((log) => log.level == LogLevel.error || log.level == LogLevel.fatal), isTrue);
    });

    test('should filter by category', () async {
      final networkLogs = await VooLogger.queryLogs(categories: ['Network']);

      expect(networkLogs.length, equals(2));
      expect(networkLogs.every((log) => log.category == 'Network'), isTrue);
    });

    test('should filter by tag', () async {
      final queryLogs = await VooLogger.queryLogs(tags: ['Query']);

      expect(queryLogs.length, equals(1));
      expect(queryLogs.first.tag, equals('Query'));
    });

    test('should filter by message pattern', () async {
      final errorLogs = await VooLogger.queryLogs(messagePattern: 'Error');

      expect(errorLogs.length, equals(1));
      expect(errorLogs.first.message.contains('Error'), isTrue);
    });

    test('should support pagination', () async {
      // Add more logs
      for (int i = 0; i < 10; i++) {
        await VooLogger.info('Log message $i');
      }

      final firstPage = await VooLogger.queryLogs(limit: 5, offset: 0);
      final secondPage = await VooLogger.queryLogs(limit: 5, offset: 5);

      expect(firstPage.length, equals(5));
      expect(secondPage.length, equals(5));

      // Verify no overlap
      final firstPageIds = firstPage.map((log) => log.id).toSet();
      final secondPageIds = secondPage.map((log) => log.id).toSet();
      expect(firstPageIds.intersection(secondPageIds), isEmpty);
    });

    test('should sort by timestamp', () async {
      final ascending = await VooLogger.queryLogs(ascending: true);
      final descending = await VooLogger.queryLogs(ascending: false);

      // Verify ascending order
      for (int i = 1; i < ascending.length; i++) {
        expect(ascending[i].timestamp.isAfter(ascending[i - 1].timestamp) || ascending[i].timestamp.isAtSameMomentAs(ascending[i - 1].timestamp), isTrue);
      }

      // Verify descending order
      for (int i = 1; i < descending.length; i++) {
        expect(descending[i].timestamp.isBefore(descending[i - 1].timestamp) || descending[i].timestamp.isAtSameMomentAs(descending[i - 1].timestamp), isTrue);
      }
    });
  });

  group('VooLogger Statistics Tests', () {
    setUp(() async {
      await VooLogger.initialize(minimumLevel: LogLevel.verbose);
      await VooLogger.clearLogs();
    });

    test('should calculate log statistics correctly', () async {
      // Add specific number of logs for each level
      await VooLogger.verbose('V1', category: 'Cat1');
      await VooLogger.verbose('V2', category: 'Cat1');
      await VooLogger.debug('D1', category: 'Cat2');
      await VooLogger.info('I1', category: 'Cat2');
      await VooLogger.info('I2', category: 'Cat3');
      await VooLogger.warning('W1', category: 'Cat3');
      await VooLogger.error('E1', category: 'Cat3');
      await VooLogger.fatal('F1', category: 'Cat3');

      final stats = await VooLogger.getStatistics();

      expect(stats.totalLogs, equals(8));
      expect(stats.levelCounts['verbose'], equals(2));
      expect(stats.levelCounts['debug'], equals(1));
      expect(stats.levelCounts['info'], equals(2));
      expect(stats.levelCounts['warning'], equals(1));
      expect(stats.levelCounts['error'], equals(1));
      expect(stats.levelCounts['fatal'], equals(1));

      expect(stats.categoryCounts['Cat1'], equals(2));
      expect(stats.categoryCounts['Cat2'], equals(2));
      expect(stats.categoryCounts['Cat3'], equals(4));
    });

    test('should get unique categories', () async {
      await VooLogger.info('Message 1', category: 'Network');
      await VooLogger.info('Message 2', category: 'Database');
      await VooLogger.info('Message 3', category: 'Network');
      await VooLogger.info('Message 4', category: 'UI');

      final categories = await VooLogger.getCategories();

      expect(categories.toSet(), equals({'Network', 'Database', 'UI'}));
    });

    test('should get unique tags', () async {
      await VooLogger.info('Message 1', tag: 'Request');
      await VooLogger.info('Message 2', tag: 'Response');
      await VooLogger.info('Message 3', tag: 'Request');
      await VooLogger.info('Message 4', tag: 'Error');

      final tags = await VooLogger.getTags();

      expect(tags.toSet(), equals({'Request', 'Response', 'Error'}));
    });
  });

  group('VooLogger Utility Methods Tests', () {
    setUp(() async {
      await VooLogger.initialize(minimumLevel: LogLevel.verbose);
      await VooLogger.clearLogs();
    });

    test('should log network requests', () async {
      await VooLogger.networkRequest('GET', 'https://api.example.com/users', headers: {'Authorization': 'Bearer token'}, metadata: {'userId': '123'});

      final logs = await VooLogger.queryLogs(categories: ['Network']);
      expect(logs.length, equals(1));

      final log = logs.first;
      expect(log.category, equals('Network'));
      expect(log.tag, equals('Request'));
      expect(log.metadata?['method'], equals('GET'));
      expect(log.metadata?['url'], equals('https://api.example.com/users'));
      expect(log.metadata?['headers'], isNotNull);
      expect(log.metadata?['userId'], equals('123'));
    });

    test('should log network responses', () async {
      await VooLogger.networkResponse(200, 'https://api.example.com/users', const Duration(milliseconds: 250), contentLength: 1024);

      final logs = await VooLogger.queryLogs(categories: ['Network']);
      expect(logs.length, equals(1));

      final log = logs.first;
      expect(log.level, equals(LogLevel.info));
      expect(log.category, equals('Network'));
      expect(log.tag, equals('Response'));
      expect(log.metadata?['statusCode'], equals(200));
      expect(log.metadata?['duration'], equals(250));
      expect(log.metadata?['contentLength'], equals(1024));
    });

    test('should log error responses with error level', () async {
      await VooLogger.networkResponse(404, 'https://api.example.com/users/999', const Duration(milliseconds: 100));

      final logs = await VooLogger.queryLogs();
      expect(logs.first.level, equals(LogLevel.error));
    });

    test('should log user actions', () async {
      await VooLogger.userAction('button_click', screen: 'HomeScreen', properties: {'buttonId': 'submit', 'timestamp': 123456});

      final logs = await VooLogger.queryLogs(categories: ['Analytics']);
      expect(logs.length, equals(1));

      final log = logs.first;
      expect(log.category, equals('Analytics'));
      expect(log.tag, equals('UserAction'));
      expect(log.metadata?['action'], equals('button_click'));
      expect(log.metadata?['screen'], equals('HomeScreen'));
      expect(log.metadata?['properties'], isNotNull);
    });

    test('should log performance metrics', () async {
      await VooLogger.performance('DatabaseQuery', const Duration(milliseconds: 750), metrics: {'rowCount': 100, 'cached': false});

      final logs = await VooLogger.queryLogs(categories: ['Performance']);
      expect(logs.length, equals(1));

      final log = logs.first;
      expect(log.level, equals(LogLevel.info)); // Under 1 second
      expect(log.category, equals('Performance'));
      expect(log.tag, equals('DatabaseQuery'));
      expect(log.metadata?['duration'], equals(750));
      expect(log.metadata?['metrics'], isNotNull);
    });

    test('should log slow operations with warning level', () async {
      await VooLogger.performance('SlowOperation', const Duration(milliseconds: 1500));

      final logs = await VooLogger.queryLogs();
      expect(logs.first.level, equals(LogLevel.warning)); // Over 1 second
    });
  });

  group('VooLogger Configuration Tests', () {
    test('should update user ID', () async {
      await VooLogger.initialize(userId: 'user1');
      await VooLogger.info('Message 1');

      await VooLogger.setUserId('user2');
      await VooLogger.info('Message 2');

      final logs = await VooLogger.queryLogs();
      expect(logs.any((log) => log.userId == 'user1'), isTrue);
      expect(logs.any((log) => log.userId == 'user2'), isTrue);
    });

    test('should start new session', () async {
      await VooLogger.initialize();
      await VooLogger.info('Message 1');

      final firstSessionLogs = await VooLogger.queryLogs();
      final firstSessionId = firstSessionLogs.first.sessionId;

      VooLogger.startNewSession();
      await VooLogger.info('Message 2');

      final allLogs = await VooLogger.queryLogs();
      final sessionIds = allLogs.map((log) => log.sessionId).toSet();

      expect(sessionIds.length, equals(3)); // Initial + system log + new session
    });

    test('should disable and enable logging', () async {
      await VooLogger.initialize();
      await VooLogger.clearLogs();

      await VooLogger.info('Message 1');
      await VooLogger.setEnabled(false);
      await VooLogger.info('Message 2'); // Should not be logged
      await VooLogger.setEnabled(true);
      await VooLogger.info('Message 3');

      final logs = await VooLogger.queryLogs();
      expect(logs.length, equals(2));
      expect(logs.any((log) => log.message == 'Message 2'), isFalse);
    });
  });

  group('VooLogger Export Tests', () {
    setUp(() async {
      await VooLogger.initialize(minimumLevel: LogLevel.verbose);
      await VooLogger.clearLogs();
    });

    test('should export logs as JSON', () async {
      await VooLogger.info('Test message 1', category: 'Test');
      await VooLogger.error('Test message 2', category: 'Test');

      final json = await VooLogger.exportLogs();

      expect(json, isNotEmpty);
      expect(json.contains('exportDate'), isTrue);
      expect(json.contains('totalLogs'), isTrue);
      expect(json.contains('logs'), isTrue);
    });

    test('should clear logs with filters', () async {
      await VooLogger.verbose('Verbose');
      await VooLogger.debug('Debug');
      await VooLogger.info('Info');
      await VooLogger.warning('Warning');
      await VooLogger.error('Error');

      // Clear only verbose and debug
      await VooLogger.clearLogs(levels: [LogLevel.verbose, LogLevel.debug]);

      final remainingLogs = await VooLogger.queryLogs();
      expect(remainingLogs.length, equals(3));
      expect(remainingLogs.any((log) => log.level == LogLevel.verbose || log.level == LogLevel.debug), isFalse);
    });

    test('should clear logs by category', () async {
      await VooLogger.info('Message 1', category: 'Network');
      await VooLogger.info('Message 2', category: 'Database');
      await VooLogger.info('Message 3', category: 'Network');

      await VooLogger.clearLogs(categories: ['Network']);

      final remainingLogs = await VooLogger.queryLogs();
      expect(remainingLogs.length, equals(1));
      expect(remainingLogs.first.category, equals('Database'));
    });
  });
}
