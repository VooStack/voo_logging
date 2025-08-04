import 'package:flutter_test/flutter_test.dart';
import 'package:voo_logging/src/data/sources/local/local_log_storage.dart';
import 'package:voo_logging/src/domain/entities/log_entry.dart';
import 'package:voo_logging/voo_logging.dart';

void main() {
  group('LocalLogStorage Tests', () {
    late LocalLogStorage storage;

    setUp(() async {
      storage = LocalLogStorage();
      // Clear any existing logs
      await storage.clearLogs();
    });

    test('should insert and retrieve a single log entry', () async {
      final logEntry = LogEntry(
        id: 'test-id-1',
        timestamp: DateTime.now(),
        message: 'Test log message',
        level: LogLevel.info,
        category: 'Test',
        tag: 'Unit',
        metadata: {'key': 'value'},
        userId: 'test-user',
        sessionId: 'test-session',
      );

      await storage.insertLog(logEntry);

      final logs = await storage.queryLogs();
      expect(logs.length, equals(1));
      expect(logs.first.message, equals('Test log message'));
      expect(logs.first.level, equals(LogLevel.info));
    });

    test('should insert multiple logs in batch', () async {
      final logs = List.generate(5, (index) => LogEntry(
        id: 'test-id-$index',
        timestamp: DateTime.now().add(Duration(milliseconds: index)),
        message: 'Log message $index',
        level: LogLevel.info,
        category: 'Test',
        userId: 'test-user',
        sessionId: 'test-session',
      ));

      await storage.insertLogs(logs);

      final retrievedLogs = await storage.queryLogs();
      expect(retrievedLogs.length, equals(5));
    });

    test('should handle logs with error and stack trace', () async {
      final error = Exception('Test exception');
      final stackTrace = StackTrace.current;

      final logEntry = LogEntry(
        id: 'error-log-1',
        timestamp: DateTime.now(),
        message: 'Error occurred',
        level: LogLevel.error,
        error: error,
        stackTrace: stackTrace.toString(),
        userId: 'test-user',
        sessionId: 'test-session',
      );

      await storage.insertLog(logEntry);

      final logs = await storage.queryLogs();
      expect(logs.length, equals(1));
      expect(logs.first.error.toString(), contains('Test exception'));
      expect(logs.first.stackTrace, isNotNull);
    });

    test('should query logs by time range', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));

      // Insert logs with different timestamps
      await storage.insertLog(LogEntry(
        id: 'past-log',
        timestamp: yesterday,
        message: 'Yesterday log',
        level: LogLevel.info,
        userId: 'test-user',
        sessionId: 'test-session',
      ));

      await storage.insertLog(LogEntry(
        id: 'current-log',
        timestamp: now,
        message: 'Current log',
        level: LogLevel.info,
        userId: 'test-user',
        sessionId: 'test-session',
      ));

      await storage.insertLog(LogEntry(
        id: 'future-log',
        timestamp: tomorrow,
        message: 'Tomorrow log',
        level: LogLevel.info,
        userId: 'test-user',
        sessionId: 'test-session',
      ));

      // Query logs from today only
      final todayLogs = await storage.queryLogs(
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 1)),
      );

      expect(todayLogs.length, equals(1));
      expect(todayLogs.first.message, equals('Current log'));
    });

    test('should handle complex metadata correctly', () async {
      final complexMetadata = {
        'string': 'value',
        'number': 42,
        'boolean': true,
        'array': [1, 2, 3],
        'nested': {
          'inner': 'value',
          'deep': {
            'level': 3,
          },
        },
      };

      final logEntry = LogEntry(
        id: 'complex-log',
        timestamp: DateTime.now(),
        message: 'Complex metadata test',
        level: LogLevel.info,
        metadata: complexMetadata,
        userId: 'test-user',
        sessionId: 'test-session',
      );

      await storage.insertLog(logEntry);

      final logs = await storage.queryLogs();
      expect(logs.first.metadata?['string'], equals('value'));
      expect(logs.first.metadata?['number'], equals(42));
      expect(logs.first.metadata?['boolean'], equals(true));
      expect(logs.first.metadata?['array'], equals([1, 2, 3]));
      expect((logs.first.metadata?['nested'] as Map)['inner'], equals('value'));
    });

    test('should clear logs older than specified date', () async {
      final now = DateTime.now();
      
      // Insert old and new logs
      await storage.insertLog(LogEntry(
        id: 'old-log',
        timestamp: now.subtract(const Duration(days: 7)),
        message: 'Old log',
        level: LogLevel.info,
        userId: 'test-user',
        sessionId: 'test-session',
      ));

      await storage.insertLog(LogEntry(
        id: 'recent-log',
        timestamp: now,
        message: 'Recent log',
        level: LogLevel.info,
        userId: 'test-user',
        sessionId: 'test-session',
      ));

      // Clear logs older than 1 day
      await storage.clearLogs(
        olderThan: now.subtract(const Duration(days: 1)),
      );

      final remainingLogs = await storage.queryLogs();
      expect(remainingLogs.length, equals(1));
      expect(remainingLogs.first.message, equals('Recent log'));
    });

    test('should get database info', () async {
      await storage.insertLog(LogEntry(
        id: 'info-test',
        timestamp: DateTime.now(),
        message: 'Test log',
        level: LogLevel.info,
        userId: 'test-user',
        sessionId: 'test-session',
      ));

      final info = await storage.getDatabaseInfo();
      expect(info['totalLogs'], equals(1));
      expect(info['platform'], isNotNull);
      expect(info['metadata'], isNotNull);
    });

    test('should handle concurrent insertions', () async {
      // Insert multiple logs concurrently
      final futures = List.generate(10, (index) async {
        return storage.insertLog(LogEntry(
          id: 'concurrent-$index',
          timestamp: DateTime.now(),
          message: 'Concurrent log $index',
          level: LogLevel.info,
          userId: 'test-user',
          sessionId: 'test-session',
        ));
      });

      await Future.wait(futures);

      final logs = await storage.queryLogs();
      expect(logs.length, equals(10));
    });

    test('should maintain order when querying logs', () async {
      final baseTime = DateTime.now();
      
      // Insert logs with specific timestamps
      for (int i = 0; i < 5; i++) {
        await storage.insertLog(LogEntry(
          id: 'ordered-$i',
          timestamp: baseTime.add(Duration(seconds: i)),
          message: 'Log $i',
          level: LogLevel.info,
          userId: 'test-user',
          sessionId: 'test-session',
        ));
      }

      // Query in ascending order
      final ascending = await storage.queryLogs(ascending: true);
      for (int i = 1; i < ascending.length; i++) {
        expect(
          ascending[i].timestamp.isAfter(ascending[i - 1].timestamp) ||
          ascending[i].timestamp.isAtSameMomentAs(ascending[i - 1].timestamp),
          isTrue,
        );
      }

      // Query in descending order
      final descending = await storage.queryLogs(ascending: false);
      for (int i = 1; i < descending.length; i++) {
        expect(
          descending[i].timestamp.isBefore(descending[i - 1].timestamp) ||
          descending[i].timestamp.isAtSameMomentAs(descending[i - 1].timestamp),
          isTrue,
        );
      }
    });
  });
}