import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:voo_logging/core/domain/enums/log_level.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_bloc.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_event.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_state.dart';
import 'package:voo_logging/features/devtools_extension/presentation/pages/voo_logger_page.dart';
import 'package:voo_logging/features/logging/data/models/log_entry_model.dart';

import 'voo_logger_page_test.mocks.dart';

@GenerateMocks([LogBloc])
void main() {
  late MockLogBloc mockLogBloc;

  setUp(() {
    mockLogBloc = MockLogBloc();
    when(mockLogBloc.state).thenReturn(const LogState());
    when(mockLogBloc.stream).thenAnswer((_) => const Stream.empty());
    // Stub the add method to accept any event
    when(mockLogBloc.add(any)).thenReturn(null);
  });

  Widget createWidgetUnderTest() => MaterialApp(
    home: BlocProvider<LogBloc>.value(value: mockLogBloc, child: const VooLoggerPage()),
  );

  group('VooLoggerPage', () {
    testWidgets('displays loading indicator when loading', (tester) async {
      when(mockLogBloc.state).thenReturn(const LogState(isLoading: true));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when error occurs', (tester) async {
      when(mockLogBloc.state).thenReturn(const LogState(error: 'Test error message'));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Error loading logs'), findsOneWidget);
      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('displays "No logs" message when empty', (tester) async {
      when(mockLogBloc.state).thenReturn(const LogState());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('No logs to display'), findsOneWidget);
    });

    testWidgets('displays logs when available', (tester) async {
      final testLog = LogEntryModel('1', DateTime(2023), 'Test log message', LogLevel.info, 'TestCategory', 'TestTag', null, null, null, null, null);

      when(mockLogBloc.state).thenReturn(LogState(logs: [testLog], filteredLogs: [testLog]));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Test log message'), findsOneWidget);
    });

    testWidgets('shows filter bar', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Show Filters'), findsOneWidget);
    });

    testWidgets('clear button triggers ClearLogs event', (tester) async {
      final testLog = LogEntryModel('1', DateTime.now(), 'Test', LogLevel.info, null, null, null, null, null, null, null);

      when(mockLogBloc.state).thenReturn(LogState(filteredLogs: [testLog]));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Ensure the toolbar is visible
      final clearButton = find.byTooltip('Clear logs');
      await tester.ensureVisible(clearButton);
      await tester.pumpAndSettle();

      // Tap the clear button
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Confirm in the dialog
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      verify(mockLogBloc.add(argThat(isA<ClearLogs>()))).called(1);
    });

    testWidgets('auto-scroll toggle triggers ToggleAutoScroll event', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final autoScrollButton = find.byTooltip('Pause auto-scroll');
      await tester.ensureVisible(autoScrollButton);
      await tester.pumpAndSettle();

      await tester.tap(autoScrollButton);
      await tester.pump();

      verify(mockLogBloc.add(argThat(isA<ToggleAutoScroll>()))).called(1);
    });

    testWidgets('search field triggers SearchQueryChanged event', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'test query');
      await tester.pump();

      verify(mockLogBloc.add(argThat(isA<SearchQueryChanged>().having((e) => e.query, 'query', 'test query')))).called(1);
    });

    testWidgets('log tile tap triggers SelectLog event', (tester) async {
      final testLog = LogEntryModel('1', DateTime(2023), 'Test log message', LogLevel.info, 'TestCategory', 'TestTag', null, null, null, null, null);

      when(mockLogBloc.state).thenReturn(LogState(logs: [testLog], filteredLogs: [testLog]));

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Test log message'));
      await tester.pump();

      verify(mockLogBloc.add(argThat(isA<SelectLog>().having((e) => e.log?.id, 'log.id', '1')))).called(1);
    });

    testWidgets('test log button generates test log', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find the test log button by tooltip
      final testLogButton = find.byTooltip('Generate test log');
      expect(testLogButton, findsOneWidget);

      // Ensure the button is visible
      await tester.ensureVisible(testLogButton);
      await tester.pumpAndSettle();

      await tester.tap(testLogButton);
      await tester.pumpAndSettle();

      verify(mockLogBloc.add(argThat(isA<LogReceived>().having((e) => e.log.message, 'message', contains('Test log generated from UI'))))).called(1);

      expect(find.text('Test log generated'), findsOneWidget);
    });
  });
}
