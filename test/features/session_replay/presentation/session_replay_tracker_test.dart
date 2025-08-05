// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:voo_logging/features/logging/domain/entities/voo_logger_interface.dart';
// import 'package:voo_logging/features/logging/domain/repositories/logger_repository.dart';
// import 'package:voo_logging/features/session_replay/domain/entities/session_recording.dart';
// import 'package:voo_logging/features/session_replay/domain/repositories/session_recording_repository.dart';
// import 'package:voo_logging/features/session_replay/presentation/session_replay_tracker.dart';

// // Generate mocks
// @GenerateMocks([SessionRecordingRepository, VooLoggerInterface, LoggerRepository])
// import 'session_replay_tracker_test.mocks.dart';

// void main() {
//   group('SessionReplayTracker', () {
//     late MockSessionRecordingRepository mockRepository;
//     late MockVooLoggerInterface mockLogger;

//     setUp(() {
//       mockRepository = MockSessionRecordingRepository();
//       mockLogger = MockVooLoggerInterface();

//       // Set up mock logger
//       when(mockLogger.sessionRecorder).thenReturn(mockRepository);

//       // Inject mocks
//       SessionReplayTracker.setLogger(mockLogger);
//       SessionReplayTracker.setSessionRecorder(mockRepository);
//     });

//     tearDown(() {
//       // Reset to defaults
//       SessionReplayTracker.reset();
//     });

//     group('User Actions', () {
//       testWidgets('should track user action when recording is active', (tester) async {
//         // Mock the recording state
//         when(mockLogger.isRecordingSession).thenReturn(true);
//         when(mockRepository.addEvent(any)).thenAnswer((_) async {});

//         await SessionReplayTracker.trackUserAction('button_tap', screen: 'home', properties: {'button_id': 'submit'});

//         verify(mockRepository.addEvent(any)).called(1);
//       });

//       testWidgets('should not track user action when recording is inactive', (tester) async {
//         // Mock recording as inactive
//         when(mockLogger.isRecordingSession).thenReturn(false);

//         await SessionReplayTracker.trackUserAction('button_tap');

//         verifyNever(mockRepository.addEvent(any));
//       });

//       testWidgets('should use current screen when screen not provided', (tester) async {
//         when(mockLogger.isRecordingSession).thenReturn(true);
//         when(mockRepository.addEvent(any)).thenAnswer((_) async {});

//         // Track action with explicit screen
//         await SessionReplayTracker.trackUserAction('swipe_gesture', screen: 'profile');

//         final captured = verify(mockRepository.addEvent(captureAny)).captured;
//         expect(captured.length, 1);
//         expect(captured[0], isA<UserActionEvent>());
//         final event = captured[0] as UserActionEvent;
//         expect(event.screen, 'profile');
//       });
//     });

//     group('Navigation', () {
//       testWidgets('should track navigation events', (tester) async {
//         when(mockLogger.isRecordingSession).thenReturn(true);
//         when(mockRepository.addEvent(any)).thenAnswer((_) async {});

//         await SessionReplayTracker.trackNavigation('profile', fromScreen: 'home');

//         final captured = verify(mockRepository.addEvent(captureAny)).captured;
//         expect(captured.length, 1);
//         expect(captured[0], isA<ScreenNavigationEvent>());
//         final event = captured[0] as ScreenNavigationEvent;
//         expect(event.fromScreen, 'home');
//         expect(event.toScreen, 'profile');
//       });

//       testWidgets('should update current screen on navigation', (tester) async {
//         when(mockLogger.isRecordingSession).thenReturn(true);
//         when(mockRepository.addEvent(any)).thenAnswer((_) async {});

//         // Navigate to profile
//         await SessionReplayTracker.trackNavigation('profile');

//         // Track action without explicit screen (should use current)
//         await SessionReplayTracker.trackUserAction('action_on_profile');

//         final captured = verify(mockRepository.addEvent(captureAny)).captured;
//         expect(captured.length, 2);

//         // Second event should have profile as screen
//         expect(captured[1], isA<UserActionEvent>());
//         final actionEvent = captured[1] as UserActionEvent;
//         expect(actionEvent.screen, 'profile');
//       });
//     });

//     group('Network Tracking', () {
//       testWidgets('should track network requests', (tester) async {
//         when(mockLogger.isRecordingSession).thenReturn(true);
//         when(mockRepository.addEvent(any)).thenAnswer((_) async {});

//         await SessionReplayTracker.trackNetworkRequest('GET', 'https://api.example.com/users', headers: {'Authorization': 'Bearer token'});

//         final captured = verify(mockRepository.addEvent(captureAny)).captured;
//         expect(captured.length, 1);
//         expect(captured[0], isA<NetworkEvent>());
//         final event = captured[0] as NetworkEvent;
//         expect(event.method, 'GET');
//         expect(event.url, 'https://api.example.com/users');
//         expect(event.headers?['Authorization'], 'Bearer token');
//       });

//       testWidgets('should track network responses', (tester) async {
//         when(mockLogger.isRecordingSession).thenReturn(true);
//         when(mockRepository.addEvent(any)).thenAnswer((_) async {});

//         await SessionReplayTracker.trackNetworkResponse('GET', 'https://api.example.com/users', 200, const Duration(milliseconds: 150));

//         final captured = verify(mockRepository.addEvent(captureAny)).captured;
//         expect(captured.length, 1);
//         expect(captured[0], isA<NetworkEvent>());
//         final event = captured[0] as NetworkEvent;
//         expect(event.statusCode, 200);
//         expect(event.duration, const Duration(milliseconds: 150));
//       });
//     });

//     group('Error Tracking', () {
//       testWidgets('should track errors', (tester) async {
//         when(mockLogger.isRecordingSession).thenReturn(true);
//         when(mockRepository.addEvent(any)).thenAnswer((_) async {});

//         final error = Exception('Test error');
//         const stackTrace = StackTrace.empty;

//         await SessionReplayTracker.trackError(error, stackTrace, context: 'Loading user data');

//         final captured = verify(mockRepository.addEvent(captureAny)).captured;
//         expect(captured.length, 1);
//         expect(captured[0], isA<ErrorEvent>());
//         final event = captured[0] as ErrorEvent;
//         expect(event.error.toString(), contains('Test error'));
//         expect(event.context, 'Loading user data');
//       });
//     });

//     group('Performance Tracking', () {
//       testWidgets('should track performance metrics', (tester) async {
//         when(mockLogger.isRecordingSession).thenReturn(true);
//         when(mockRepository.addEvent(any)).thenAnswer((_) async {});

//         await SessionReplayTracker.trackPerformance('image_load', const Duration(milliseconds: 250), metadata: {'image_url': 'https://example.com/image.png'});

//         final captured = verify(mockRepository.addEvent(captureAny)).captured;
//         expect(captured.length, 1);
//         expect(captured[0], isA<PerformanceEvent>());
//         final event = captured[0] as PerformanceEvent;
//         expect(event.operation, 'image_load');
//         expect(event.duration, const Duration(milliseconds: 250));
//         expect(event.metadata?['image_url'], 'https://example.com/image.png');
//       });
//     });

//     group('Custom Events', () {
//       testWidgets('should track custom events', (tester) async {
//         when(mockLogger.isRecordingSession).thenReturn(true);
//         when(mockRepository.addEvent(any)).thenAnswer((_) async {});

//         await SessionReplayTracker.trackCustomEvent('purchase_completed', data: {'product_id': '123', 'amount': 99.99});

//         final captured = verify(mockRepository.addEvent(captureAny)).captured;
//         expect(captured.length, 1);
//         expect(captured[0], isA<CustomEvent>());
//         final event = captured[0] as CustomEvent;
//         expect(event.name, 'purchase_completed');
//         expect(event.data?['product_id'], '123');
//         expect(event.data?['amount'], 99.99);
//       });
//     });
//   });
// }

// // Mock classes for testing
// class MockRoute extends Mock implements Route<dynamic> {}
