import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:voo_logging/core/domain/enums/log_level.dart';
import 'package:voo_logging/features/devtools_extension/domain/repositories/devtools_log_repository.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_bloc.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_event.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_state.dart';
import 'package:voo_logging/features/logging/data/models/log_entry_model.dart';

import 'log_bloc_test.mocks.dart';

@GenerateMocks([DevToolsLogRepository])
void main() {
  late LogBloc logBloc;
  late MockDevToolsLogRepository mockRepository;

  setUp(() {
    mockRepository = MockDevToolsLogRepository();

    // Set up default behavior
    when(mockRepository.logStream).thenAnswer((_) => const Stream.empty());
    when(mockRepository.getCachedLogs()).thenReturn([]);
    when(mockRepository.filterLogs(levels: anyNamed('levels'), searchQuery: anyNamed('searchQuery'), category: anyNamed('category'))).thenReturn([]);

    logBloc = LogBloc(repository: mockRepository);
  });

  tearDown(() {
    logBloc.close();
  });

  group('LogBloc', () {
    final testLog1 = LogEntryModel('1', DateTime(2023), 'Test log 1', LogLevel.info, 'Test', 'TestTag', null, null, null, null, null);

    final testLog2 = LogEntryModel('2', DateTime(2023, 1, 2), 'Test log 2', LogLevel.error, 'Error', 'ErrorTag', null, null, null, null, null);

    test('initial state should be correct', () {
      expect(logBloc.state, equals(const LogState()));
    });

    blocTest<LogBloc, LogState>(
      'emits [loading, loaded] when LoadLogs is added',
      build: () {
        when(mockRepository.getCachedLogs()).thenReturn([testLog1, testLog2]);
        return logBloc;
      },
      act: (bloc) => bloc.add(LoadLogs()),
      expect: () => [
        const LogState(isLoading: true),
        LogState(logs: [testLog1, testLog2], filteredLogs: [testLog1, testLog2]),
      ],
    );

    blocTest<LogBloc, LogState>(
      'emits updated state when LogReceived is added',
      build: () => logBloc,
      seed: () => const LogState(),
      act: (bloc) => bloc.add(LogReceived(testLog1)),
      expect: () => [
        LogState(logs: [testLog1], filteredLogs: [testLog1]),
      ],
    );

    blocTest<LogBloc, LogState>(
      'emits filtered state when FilterLogsChanged is added',
      build: () => logBloc,
      seed: () => LogState(logs: [testLog1, testLog2], filteredLogs: [testLog1, testLog2]),
      act: (bloc) => bloc.add(const FilterLogsChanged(levels: [LogLevel.info])),
      expect: () => [
        LogState(
          logs: [testLog1, testLog2],
          filteredLogs: [testLog1], // Only info level
          selectedLevels: const [LogLevel.info],
        ),
      ],
    );

    blocTest<LogBloc, LogState>(
      'emits state with selected log when SelectLog is added',
      build: () => logBloc,
      seed: () => LogState(logs: [testLog1], filteredLogs: [testLog1]),
      act: (bloc) => bloc.add(SelectLog(testLog1)),
      expect: () => [
        LogState(logs: [testLog1], filteredLogs: [testLog1], selectedLog: testLog1),
      ],
    );

    blocTest<LogBloc, LogState>(
      'clears selected log when SelectLog with null is added',
      build: () => logBloc,
      seed: () => LogState(logs: [testLog1], filteredLogs: [testLog1], selectedLog: testLog1),
      act: (bloc) => bloc.add(const SelectLog(null)),
      expect: () => [
        LogState(logs: [testLog1], filteredLogs: [testLog1]),
      ],
    );

    blocTest<LogBloc, LogState>(
      'emits empty state when ClearLogs is added',
      build: () => logBloc,
      seed: () => LogState(logs: [testLog1, testLog2], filteredLogs: [testLog1, testLog2]),
      act: (bloc) => bloc.add(ClearLogs()),
      expect: () => [const LogState()],
      verify: (_) {
        verify(mockRepository.clearLogs()).called(1);
      },
    );

    blocTest<LogBloc, LogState>(
      'toggles autoScroll when ToggleAutoScroll is added',
      build: () => logBloc,
      seed: () => const LogState(),
      act: (bloc) => bloc.add(ToggleAutoScroll()),
      expect: () => [const LogState(autoScroll: false)],
    );

    blocTest<LogBloc, LogState>(
      'emits filtered state when SearchQueryChanged is added',
      build: () => logBloc,
      seed: () => LogState(logs: [testLog1, testLog2], filteredLogs: [testLog1, testLog2]),
      act: (bloc) => bloc.add(const SearchQueryChanged('Test log 1')),
      expect: () => [
        LogState(
          logs: [testLog1, testLog2],
          filteredLogs: [testLog1], // Only matching log
          searchQuery: 'Test log 1',
        ),
      ],
    );

    group('filtering logic', () {
      test('filters by level correctly', () {
        logBloc = LogBloc(repository: mockRepository);

        // Add test logs
        logBloc.add(LogReceived(testLog1)); // info
        logBloc.add(LogReceived(testLog2)); // error

        // Filter by error level
        logBloc.add(const FilterLogsChanged(levels: [LogLevel.error]));

        // Wait for events to process
        expectLater(
          logBloc.stream,
          emitsInOrder([
            isA<LogState>(), // LogReceived for testLog1
            isA<LogState>(), // LogReceived for testLog2
            predicate<LogState>((state) => state.filteredLogs.length == 1 && state.filteredLogs.first.level == LogLevel.error),
          ]),
        );
      });

      test('filters by category correctly', () {
        logBloc = LogBloc(repository: mockRepository);

        // Add test logs
        logBloc.add(LogReceived(testLog1)); // category: Test
        logBloc.add(LogReceived(testLog2)); // category: Error

        // Filter by Test category
        logBloc.add(const FilterLogsChanged(category: 'Test'));

        // Wait for events to process
        expectLater(
          logBloc.stream,
          emitsInOrder([
            isA<LogState>(), // LogReceived for testLog1
            isA<LogState>(), // LogReceived for testLog2
            predicate<LogState>((state) => state.filteredLogs.length == 1 && state.filteredLogs.first.category == 'Test'),
          ]),
        );
      });
    });
  });
}
