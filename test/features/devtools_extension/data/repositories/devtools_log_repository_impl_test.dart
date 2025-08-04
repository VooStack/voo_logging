import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:voo_logging/core/domain/enums/log_level.dart';
import 'package:voo_logging/features/devtools_extension/data/datasources/devtools_log_datasource.dart';
import 'package:voo_logging/features/devtools_extension/data/repositories/devtools_log_repository_impl.dart';
import 'package:voo_logging/features/logging/data/models/log_entry_model.dart';

import 'devtools_log_repository_impl_test.mocks.dart';

@GenerateMocks([DevToolsLogDataSource])
void main() {
  late DevToolsLogRepositoryImpl repository;
  late MockDevToolsLogDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockDevToolsLogDataSource();
    repository = DevToolsLogRepositoryImpl(dataSource: mockDataSource);
  });

  group('DevToolsLogRepositoryImpl', () {
    final testLog1 = LogEntryModel('1', DateTime(2023), 'Test log message', LogLevel.info, 'TestCategory', 'TestTag', {'key': 'value'}, null, null, null, null);

    final testLog2 = LogEntryModel(
      '2',
      DateTime(2023, 1, 2),
      'Error log message',
      LogLevel.error,
      'ErrorCategory',
      'ErrorTag',
      null,
      'Test error',
      null,
      null,
      null,
    );

    final testLog3 = LogEntryModel('3', DateTime(2023, 1, 3), 'Another test log', LogLevel.debug, 'TestCategory', 'DebugTag', null, null, null, null, null);

    test('logStream returns stream from datasource', () {
      when(mockDataSource.logStream).thenAnswer((_) => Stream.value(testLog1));

      expect(repository.logStream, emits(testLog1));
    });

    test('getCachedLogs returns logs from datasource', () {
      when(mockDataSource.getCachedLogs()).thenReturn([testLog1, testLog2]);

      final logs = repository.getCachedLogs();

      expect(logs.length, 2);
      expect(logs[0], equals(testLog1));
      expect(logs[1], equals(testLog2));
    });

    test('clearLogs calls datasource clearCache', () {
      repository.clearLogs();

      verify(mockDataSource.clearCache()).called(1);
    });

    group('filterLogs', () {
      setUp(() {
        when(mockDataSource.getCachedLogs()).thenReturn([testLog1, testLog2, testLog3]);
      });

      test('filters by log level', () {
        final filtered = repository.filterLogs(levels: [LogLevel.info]);

        expect(filtered.length, 1);
        expect(filtered[0].level, LogLevel.info);
        expect(filtered[0].id, '1');
      });

      test('filters by multiple log levels', () {
        final filtered = repository.filterLogs(levels: [LogLevel.info, LogLevel.error]);

        expect(filtered.length, 2);
        expect(filtered.map((log) => log.level), containsAll([LogLevel.info, LogLevel.error]));
      });

      test('filters by category', () {
        final filtered = repository.filterLogs(category: 'TestCategory');

        expect(filtered.length, 2);
        expect(filtered.every((log) => log.category == 'TestCategory'), true);
      });

      test('filters by search query in message', () {
        final filtered = repository.filterLogs(searchQuery: 'Error');

        expect(filtered.length, 1);
        expect(filtered[0].id, '2');
      });

      test('filters by search query in category', () {
        final filtered = repository.filterLogs(searchQuery: 'error');

        expect(filtered.length, 1);
        expect(filtered[0].category, 'ErrorCategory');
      });

      test('filters by search query in tag', () {
        final filtered = repository.filterLogs(searchQuery: 'debug');

        expect(filtered.length, 1);
        expect(filtered[0].tag, 'DebugTag');
      });

      test('applies multiple filters', () {
        final filtered = repository.filterLogs(levels: [LogLevel.info, LogLevel.debug], category: 'TestCategory');

        expect(filtered.length, 2);
        expect(filtered.every((log) => log.category == 'TestCategory'), true);
        expect(filtered.every((log) => log.level == LogLevel.info || log.level == LogLevel.debug), true);
      });

      test('search query is case insensitive', () {
        final filtered = repository.filterLogs(searchQuery: 'ERROR');

        expect(filtered.length, 1);
        expect(filtered[0].id, '2');
      });

      test('returns all logs when no filters applied', () {
        final filtered = repository.filterLogs();

        expect(filtered.length, 3);
      });

      test('returns empty list when no logs match filters', () {
        final filtered = repository.filterLogs(levels: [LogLevel.fatal]);

        expect(filtered.isEmpty, true);
      });
    });
  });
}
