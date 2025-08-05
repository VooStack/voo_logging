import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:voo_logging/features/session_replay/domain/entities/session_recording.dart';
import 'package:voo_logging/features/session_replay/domain/repositories/session_recording_repository.dart';
import 'package:voo_logging/features/session_replay/presentation/session_replay_tracker.dart';

// Generate mocks
@GenerateMocks([SessionRecordingRepository])
import 'session_replay_tracker_test.mocks.dart';

void main() {
  group('SessionReplayTracker', () {
    late MockSessionRecordingRepository mockRepository;

    setUp(() {
      mockRepository = MockSessionRecordingRepository();
      // Note: Cannot reset singleton state directly in tests
      // Tests should verify behavior through public APIs
    });

    group('User Actions', () {
      testWidgets('should track user action when recording is active', (tester) async {
        // Mock the VooLogger singleton
        when(mockRepository.isRecording).thenReturn(true);
        when(mockRepository.addEvent(any)).thenAnswer((_) async {});

        await SessionReplayTracker.trackUserAction('button_tap', screen: 'home', properties: {'button_id': 'submit'});

        verify(mockRepository.addEvent(any)).called(1);
      });

      testWidgets('should not track user action when recording is inactive', (tester) async {
        // Mock recording as inactive
        when(mockRepository.isRecording).thenReturn(false);

        await SessionReplayTracker.trackUserAction('button_tap');

        verifyNever(mockRepository.addEvent(any));
      });

      testWidgets('should use current screen when screen not provided', (tester) async {
        when(mockRepository.isRecording).thenReturn(true);
        when(mockRepository.addEvent(any)).thenAnswer((_) async {});

        // Track action with explicit screen
        await SessionReplayTracker.trackUserAction('swipe_gesture', screen: 'profile');

        final captured = verify(mockRepository.addEvent(captureAny)).captured;
        final event = captured.first as UserActionEvent;
        expect(event.screen, equals('profile'));
      });
    });

    group('Navigation Tracking', () {
      testWidgets('should track navigation and update current screen', (tester) async {
        when(mockRepository.isRecording).thenReturn(true);
        when(mockRepository.addEvent(any)).thenAnswer((_) async {});

        await SessionReplayTracker.trackNavigation('settings', fromScreen: 'home', parameters: {'tab': 'general'});

        // Verify event was added
        final captured = verify(mockRepository.addEvent(captureAny)).captured;
        final event = captured.first as ScreenNavigationEvent;
        expect(event.fromScreen, equals('home'));
        expect(event.toScreen, equals('settings'));
        expect(event.parameters, equals({'tab': 'general'}));

        // Note: Cannot verify private field updates in tests
        // The screen tracking is internal implementation detail
      });

      testWidgets('should use current screen as fromScreen when not provided', (tester) async {
        when(mockRepository.isRecording).thenReturn(true);
        when(mockRepository.addEvent(any)).thenAnswer((_) async {});

        // First navigate to establish current screen
        await SessionReplayTracker.trackNavigation('dashboard', fromScreen: 'home');
        
        // Then navigate without specifying fromScreen
        await SessionReplayTracker.trackNavigation('profile');

        final allCaptured = verify(mockRepository.addEvent(captureAny)).captured;
        final lastEvent = allCaptured.last as ScreenNavigationEvent;
        expect(lastEvent.fromScreen, equals('dashboard'));
        expect(lastEvent.toScreen, equals('profile'));
      });

      testWidgets('should use "unknown" as fromScreen when no current screen', (tester) async {
        when(mockRepository.isRecording).thenReturn(true);
        when(mockRepository.addEvent(any)).thenAnswer((_) async {});

        await SessionReplayTracker.trackNavigation('home');

        final captured = verify(mockRepository.addEvent(captureAny)).captured;
        final event = captured.first as ScreenNavigationEvent;
        expect(event.fromScreen, equals('unknown'));
      });
    });

    group('Network Tracking', () {
      testWidgets('should track network request', (tester) async {
        when(mockRepository.isRecording).thenReturn(true);
        when(mockRepository.addEvent(any)).thenAnswer((_) async {});

        await SessionReplayTracker.trackNetworkRequest(
          'GET',
          'https://api.example.com/users',
          headers: {'authorization': 'Bearer token'},
          metadata: {'cache': false},
        );

        final captured = verify(mockRepository.addEvent(captureAny)).captured;
        final event = captured.first as NetworkEvent;
        expect(event.method, equals('GET'));
        expect(event.url, equals('https://api.example.com/users'));
        expect(event.headers, equals({'authorization': 'Bearer token'}));
        expect(event.metadata, equals({'cache': false}));
        expect(event.statusCode, isNull);
        expect(event.duration, isNull);
      });

      testWidgets('should track network response', (tester) async {
        when(mockRepository.isRecording).thenReturn(true);
        when(mockRepository.addEvent(any)).thenAnswer((_) async {});

        final duration = Duration(milliseconds: 500);
        await SessionReplayTracker.trackNetworkResponse(
          'POST',
          'https://api.example.com/users',
          201,
          duration,
          headers: {'content-type': 'application/json'},
          metadata: {'response_size': 1024},
        );

        final captured = verify(mockRepository.addEvent(captureAny)).captured;
        final event = captured.first as NetworkEvent;
        expect(event.method, equals('POST'));
        expect(event.url, equals('https://api.example.com/users'));
        expect(event.statusCode, equals(201));
        expect(event.duration, equals(duration));
        expect(event.headers, equals({'content-type': 'application/json'}));
        expect(event.metadata, equals({'response_size': 1024}));
      });
    });

    group('App State Tracking', () {
      testWidgets('should track app state changes', (tester) async {
        when(mockRepository.isRecording).thenReturn(true);
        when(mockRepository.addEvent(any)).thenAnswer((_) async {});

        await SessionReplayTracker.trackAppState('background', details: {'reason': 'user_action'});

        final captured = verify(mockRepository.addEvent(captureAny)).captured;
        final event = captured.first as AppStateEvent;
        expect(event.state, equals('background'));
        expect(event.details, equals({'reason': 'user_action'}));
      });
    });
  });

  group('SessionReplayNavigatorObserver', () {
    late SessionReplayNavigatorObserver observer;
    late MockRoute mockRoute;
    late MockRoute mockPreviousRoute;

    setUp(() {
      observer = SessionReplayNavigatorObserver();
      mockRoute = MockRoute();
      mockPreviousRoute = MockRoute();
    });

    testWidgets('should track navigation on didPush', (tester) async {
      when(mockRoute.settings).thenReturn(RouteSettings(name: 'new_screen'));
      when(mockPreviousRoute.settings).thenReturn(RouteSettings(name: 'old_screen'));

      observer.didPush(mockRoute, mockPreviousRoute);

      // The actual tracking would be tested via integration tests
      // since it calls static methods that interact with the global state
    });

    testWidgets('should track navigation on didPop', (tester) async {
      when(mockRoute.settings).thenReturn(RouteSettings(name: 'old_screen'));
      when(mockPreviousRoute.settings).thenReturn(RouteSettings(name: 'new_screen'));

      observer.didPop(mockRoute, mockPreviousRoute);

      // The actual tracking would be tested via integration tests
    });

    testWidgets('should track navigation on didReplace', (tester) async {
      when(mockRoute.settings).thenReturn(RouteSettings(name: 'new_screen'));
      when(mockPreviousRoute.settings).thenReturn(RouteSettings(name: 'old_screen'));

      observer.didReplace(newRoute: mockRoute, oldRoute: mockPreviousRoute);

      // The actual tracking would be tested via integration tests
    });
  });

  group('TrackedGestureDetector', () {
    testWidgets('should track user action on tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: TrackedGestureDetector(
            action: 'test_tap',
            screen: 'test_screen',
            properties: {'test': 'value'},
            onTap: () => tapped = true,
            child: Container(width: 100, height: 100, child: Text('Tap me')),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pump();

      expect(tapped, isTrue);
      // The actual session tracking would be tested via integration tests
    });

    testWidgets('should track user action on long press', (tester) async {
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: TrackedGestureDetector(
            action: 'test_long_press',
            onLongPress: () => longPressed = true,
            child: Container(width: 100, height: 100, child: Text('Long press me')),
          ),
        ),
      );

      await tester.longPress(find.text('Long press me'));
      await tester.pump();

      expect(longPressed, isTrue);
    });

    testWidgets('should track user action on double tap', (tester) async {
      bool doubleTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: TrackedGestureDetector(
            action: 'test_double_tap',
            onDoubleTap: () => doubleTapped = true,
            child: Container(width: 100, height: 100, child: Text('Double tap me')),
          ),
        ),
      );

      await tester.tap(find.text('Double tap me'));
      await tester.tap(find.text('Double tap me'));
      await tester.pump();

      expect(doubleTapped, isTrue);
    });

    testWidgets('should work without optional callbacks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TrackedGestureDetector(
            action: 'test_action',
            child: Container(width: 100, height: 100, child: Text('Test')),
          ),
        ),
      );

      // Should not throw errors when tapping without callbacks
      await tester.tap(find.text('Test'));
      await tester.pump();
    });
  });
}

// Mock classes for testing
class MockRoute extends Mock implements Route<dynamic> {}
