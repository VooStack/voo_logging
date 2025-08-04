import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voo_logger_devtools/domain/entities/log_entry.dart';
import 'package:voo_logger_devtools/domain/entities/log_filter.dart';
import 'package:voo_logger_devtools/domain/entities/log_statistics.dart';
import 'package:voo_logger_devtools/domain/repositories/log_repository.dart';
import 'package:voo_logger_devtools/domain/usecases/export_logs_usecase.dart';
import 'package:voo_logger_devtools/domain/usecases/get_logs_usecase.dart';
import 'package:voo_logger_devtools/domain/usecases/get_statistics_usecase.dart';
import 'package:voo_logger_devtools/domain/usecases/stream_logs_usecase.dart';
import 'package:voo_logger_devtools/presentation/blocs/log_bloc.dart';
import 'package:voo_logger_devtools/presentation/blocs/log_event.dart';
import 'package:voo_logger_devtools/presentation/blocs/log_state.dart';

// Mock classes
class MockLogRepository extends Mock implements LogRepository {}

class MockGetLogsUseCase extends Mock implements GetLogsUseCase {}

class MockStreamLogsUseCase extends Mock implements StreamLogsUseCase {}

class MockGetStatisticsUseCase extends Mock implements GetStatisticsUseCase {}

class MockExportLogsUseCase extends Mock implements ExportLogsUseCase {}

// Fake classes for fallback values
class FakeGetLogsParams extends Fake implements GetLogsParams {
  @override
  LogFilter? get filter => null;

  @override
  int get limit => 1000;

  @override
  int get offset => 0;
}

class FakeLogFilter extends Fake implements LogFilter {}

class FakeExportLogsParams extends Fake implements ExportLogsParams {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGetLogsParams());
    registerFallbackValue(FakeLogFilter());
    registerFallbackValue(FakeExportLogsParams());
  });
  group('LogBloc', () {
    late MockLogRepository mockRepository;
    late MockGetLogsUseCase mockGetLogsUseCase;
    late MockStreamLogsUseCase mockStreamLogsUseCase;
    late MockGetStatisticsUseCase mockGetStatisticsUseCase;
    late MockExportLogsUseCase mockExportLogsUseCase;
    late LogBloc logBloc;

    setUp(() {
      mockRepository = MockLogRepository();
      mockGetLogsUseCase = MockGetLogsUseCase();
      mockStreamLogsUseCase = MockStreamLogsUseCase();
      mockGetStatisticsUseCase = MockGetStatisticsUseCase();
      mockExportLogsUseCase = MockExportLogsUseCase();

      // Setup default mocks
      when(() => mockGetLogsUseCase(any())).thenAnswer((_) async => <LogEntry>[]);
      when(() => mockRepository.getUniqueCategories()).thenAnswer((_) async => <String>[]);
      when(() => mockRepository.getUniqueTags()).thenAnswer((_) async => <String>[]);
      when(() => mockRepository.getUniqueSessions()).thenAnswer((_) async => <String>[]);
      when(() => mockGetStatisticsUseCase(any())).thenAnswer((_) async => LogStatistics.empty());
      when(() => mockStreamLogsUseCase()).thenAnswer((_) => const Stream<LogEntry>.empty());

      logBloc = LogBloc(
        repository: mockRepository,
        getLogsUseCase: mockGetLogsUseCase,
        streamLogsUseCase: mockStreamLogsUseCase,
        getStatisticsUseCase: mockGetStatisticsUseCase,
        exportLogsUseCase: mockExportLogsUseCase,
      );
    });

    tearDown(() {
      logBloc.close();
    });

    test('initial state should be correct', () {
      expect(logBloc.state, equals(const LogState()));
    });

    blocTest<LogBloc, LogState>(
      'emits initial loading and loaded state automatically',
      build: () => logBloc,
      wait: const Duration(milliseconds: 100), // Give time for async operations
      expect: () => [
        // The bloc automatically loads on initialization
        LogState(
          statistics: LogStatistics.empty(),
        ),
      ],
    );

    blocTest<LogBloc, LogState>(
      'handles errors when loading fails',
      setUp: () {
        when(() => mockGetLogsUseCase(any())).thenThrow(Exception('Failed to load logs'));
      },
      build: () => LogBloc(
        repository: mockRepository,
        getLogsUseCase: mockGetLogsUseCase,
        streamLogsUseCase: mockStreamLogsUseCase,
        getStatisticsUseCase: mockGetStatisticsUseCase,
        exportLogsUseCase: mockExportLogsUseCase,
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const LogState(isLoading: true),
        const LogState(
          error: 'Exception: Failed to load logs',
        ),
      ],
    );

    blocTest<LogBloc, LogState>(
      'emits updated state when ClearLogs is added',
      build: () {
        when(() => mockRepository.clearLogs()).thenAnswer((_) async {});
        return logBloc;
      },
      act: (bloc) => bloc.add(ClearLogs()),
      skip: 1, // Skip the initial loading state
      expect: () => [
        LogState(
          statistics: LogStatistics.empty(),
        ),
      ],
    );

    blocTest<LogBloc, LogState>(
      'emits toggled autoScroll when ToggleAutoScroll is added',
      build: () => logBloc,
      act: (bloc) => bloc.add(ToggleAutoScroll()),
      skip: 1, // Skip the initial loading state
      expect: () => [
        predicate<LogState>((state) => state.autoScroll == false), // Toggled from true to false
      ],
    );
  });

  group('LogFilter', () {
    test('should match log entry correctly', () {
      const filter = LogFilter();
      final logEntry = LogEntry(
        id: '1',
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'Test message',
        category: 'Test',
        tag: 'tag1',
        sessionId: 'session1',
        userId: 'user1',
      );

      expect(filter.matches(logEntry), isTrue);
    });
  });

  group('LogStatistics', () {
    test('should create empty statistics', () {
      final stats = LogStatistics.empty();
      expect(stats.totalLogs, equals(0));
    });
  });
}
