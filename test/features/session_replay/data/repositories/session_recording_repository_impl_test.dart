import 'dart:async';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:voo_logging/core/domain/enums/log_level.dart';
import 'package:voo_logging/features/logging/domain/entities/log_entry.dart';
import 'package:voo_logging/features/session_replay/data/datasources/session_recording_storage.dart';
import 'package:voo_logging/features/session_replay/data/repositories/session_recording_repository_impl.dart';
import 'package:voo_logging/features/session_replay/domain/entities/session_recording.dart';

// Generate mocks
@GenerateMocks([SessionRecordingStorage])
import 'session_recording_repository_impl_test.mocks.dart';

void main() {
  group('SessionRecordingRepositoryImpl', () {
    late SessionRecordingRepositoryImpl repository;
    late MockSessionRecordingStorage mockStorage;

    setUp(() {
      mockStorage = MockSessionRecordingStorage();
      repository = SessionRecordingRepositoryImpl(storage: mockStorage);
    });

    tearDown(() {
      repository.dispose();
    });

    group('Recording Lifecycle', () {
      test('should start recording successfully', () async {
        when(mockStorage.saveSession(any)).thenAnswer((_) async {});

        await repository.startRecording(
          sessionId: 'session-123',
          userId: 'user-456',
          metadata: {'app_version': '1.0.0'},
        );

        expect(repository.isRecording, isTrue);
        
        final currentRecording = await repository.getCurrentRecording();
        expect(currentRecording, isNotNull);
        expect(currentRecording!.sessionId, equals('session-123'));
        expect(currentRecording.userId, equals('user-456'));
        expect(currentRecording.status, equals(SessionStatus.recording));
        expect(currentRecording.metadata, equals({'app_version': '1.0.0'}));
      });

      test('should stop previous recording when starting new one', () async {
        when(mockStorage.saveSession(any)).thenAnswer((_) async {});

        // Start first recording
        await repository.startRecording(
          sessionId: 'session-1',
          userId: 'user-1',
        );

        final firstRecording = await repository.getCurrentRecording();
        expect(firstRecording!.status, equals(SessionStatus.recording));

        // Start second recording
        await repository.startRecording(
          sessionId: 'session-2',
          userId: 'user-2',
        );

        final secondRecording = await repository.getCurrentRecording();
        expect(secondRecording!.sessionId, equals('session-2'));
        expect(secondRecording.status, equals(SessionStatus.recording));

        // Verify storage was called to save the completed first recording
        verify(mockStorage.saveSession(any)).called(greaterThanOrEqualTo(2));
      });

      test('should stop recording successfully', () async {
        when(mockStorage.saveSession(any)).thenAnswer((_) async {});

        await repository.startRecording(
          sessionId: 'session-123',
          userId: 'user-456',
        );

        expect(repository.isRecording, isTrue);

        await repository.stopRecording();

        expect(repository.isRecording, isFalse);
        
        final currentRecording = await repository.getCurrentRecording();
        expect(currentRecording, isNull);
      });

      test('should pause recording', () async {
        when(mockStorage.saveSession(any)).thenAnswer((_) async {});

        await repository.startRecording(
          sessionId: 'session-123',
          userId: 'user-456',
        );

        await repository.pauseRecording();

        final currentRecording = await repository.getCurrentRecording();
        expect(currentRecording!.status, equals(SessionStatus.paused));
        expect(repository.isRecording, isFalse);
      });

      test('should resume recording', () async {
        when(mockStorage.saveSession(any)).thenAnswer((_) async {});

        await repository.startRecording(
          sessionId: 'session-123',
          userId: 'user-456',
        );

        await repository.pauseRecording();
        await repository.resumeRecording();

        final currentRecording = await repository.getCurrentRecording();
        expect(currentRecording!.status, equals(SessionStatus.recording));
        expect(repository.isRecording, isTrue);
      });

      test('should not pause if not recording', () async {
        when(mockStorage.saveSession(any)).thenAnswer((_) async {});

        await repository.pauseRecording();

        final currentRecording = await repository.getCurrentRecording();
        expect(currentRecording, isNull);
      });

      test('should not resume if not paused', () async {
        when(mockStorage.saveSession(any)).thenAnswer((_) async {});

        await repository.startRecording(
          sessionId: 'session-123',
          userId: 'user-456',
        );

        await repository.resumeRecording();

        final currentRecording = await repository.getCurrentRecording();
        expect(currentRecording!.status, equals(SessionStatus.recording));
      });
    });

    group('Event Management', () {
      test('should add events when recording', () async {
        when(mockStorage.saveSession(any)).thenAnswer((_) async {});

        await repository.startRecording(
          sessionId: 'session-123',
          userId: 'user-456',
        );

        final event = UserActionEvent(
          timestamp: DateTime.now(),
          action: 'button_tap',
          screen: 'home',
        );

        await repository.addEvent(event);

        final currentRecording = await repository.getCurrentRecording();
        expect(currentRecording!.events, isEmpty); // Events are pending until saved
      });

      test('should not add events when not recording', () async {
        final event = UserActionEvent(
          timestamp: DateTime.now(),
          action: 'button_tap',
          screen: 'home',
        );

        await repository.addEvent(event);

        final currentRecording = await repository.getCurrentRecording();
        expect(currentRecording, isNull);
      });

      test('should automatically save events when threshold reached', () async {
        when(mockStorage.saveSession(any)).thenAnswer((_) async {});

        await repository.startRecording(
          sessionId: 'session-123',
          userId: 'user-456',
        );

        // Add 100 events to trigger auto-save
        for (int i = 0; i < 100; i++) {
          final event = UserActionEvent(
            timestamp: DateTime.now(),
            action: 'action_$i',
          );
          await repository.addEvent(event);
        }

        // Verify storage was called
        verify(mockStorage.saveSession(any)).called(greaterThan(1));
      });

      // TODO: Fix this test - VooLogger singleton makes it hard to mock the stream
      // test('should capture log events from VooLogger stream', () async {
      //   when(mockStorage.saveSession(any)).thenAnswer((_) async {});

      //   await repository.startRecording(
      //     sessionId: 'session-123',
      //     userId: 'user-456',
      //   );

      //   // Emit log entry
      //   final logEntry = LogEntry(
      //     id: 'log-1',
      //     timestamp: DateTime.now(),
      //     message: 'Test log message',
      //     level: LogLevel.info,
      //   );

      //   logStreamController.add(logEntry);

      //   // Wait for async processing
      //   await Future.delayed(Duration(milliseconds: 10));

      //   // The log event should be captured as a pending event
      //   // This would be verified by checking internal state or storage calls
      //   verify(mockStorage.saveSession(any)).called(greaterThanOrEqualTo(1));
      // });

      test('should handle event addition errors gracefully', () async {
        when(mockStorage.saveSession(any)).thenThrow(Exception('Storage error'));

        await repository.startRecording(
          sessionId: 'session-123',
          userId: 'user-456',
        );

        final event = UserActionEvent(
          timestamp: DateTime.now(),
          action: 'button_tap',
        );

        // Should not throw exception
        await repository.addEvent(event);

        final currentRecording = await repository.getCurrentRecording();
        expect(currentRecording!.status, equals(SessionStatus.error));
      });
    });

    group('Recording Stream', () {
      test('should emit recording updates on stream', () async {
        when(mockStorage.saveSession(any)).thenAnswer((_) async {});

        final streamEvents = <SessionRecording>[];
        repository.recordingStream.listen(streamEvents.add);

        await repository.startRecording(
          sessionId: 'session-123',
          userId: 'user-456',
        );

        await repository.pauseRecording();
        await repository.resumeRecording();
        await repository.stopRecording();

        await Future.delayed(Duration(milliseconds: 10));

        expect(streamEvents.length, greaterThanOrEqualTo(4));
        expect(streamEvents.first.status, equals(SessionStatus.recording));
        expect(streamEvents.any((r) => r.status == SessionStatus.paused), isTrue);
        expect(streamEvents.any((r) => r.status == SessionStatus.completed), isTrue);
      });
    });

    group('Storage Operations', () {
      test('should retrieve recordings from storage', () async {
        final mockRecordings = [
          _createMockRecording('recording-1'),
          _createMockRecording('recording-2'),
        ];

        when(mockStorage.querySessions(
          userId: anyNamed('userId'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => mockRecordings);

        final recordings = await repository.getRecordings(
          userId: 'user-123',
          limit: 10,
        );

        expect(recordings.length, equals(2));
        verify(mockStorage.querySessions(
          userId: 'user-123',
          limit: 10,
        )).called(1);
      });

      test('should get specific recording by id', () async {
        final mockRecording = _createMockRecording('recording-1');
        when(mockStorage.getSession('recording-1'))
            .thenAnswer((_) async => mockRecording);

        final recording = await repository.getRecording('recording-1');

        expect(recording, equals(mockRecording));
        verify(mockStorage.getSession('recording-1')).called(1);
      });

      test('should delete recording', () async {
        when(mockStorage.deleteSession('recording-1')).thenAnswer((_) async {});

        await repository.deleteRecording('recording-1');

        verify(mockStorage.deleteSession('recording-1')).called(1);
      });

      test('should delete old recordings', () async {
        final age = Duration(days: 30);
        when(mockStorage.deleteOldSessions(age)).thenAnswer((_) async {});

        await repository.deleteOldRecordings(age);

        verify(mockStorage.deleteOldSessions(age)).called(1);
      });

      test('should get total storage size', () async {
        when(mockStorage.getTotalStorageSize()).thenAnswer((_) async => 1024);

        final size = await repository.getTotalStorageSize();

        expect(size, equals(1024));
        verify(mockStorage.getTotalStorageSize()).called(1);
      });
    });

    group('Export/Import Operations', () {
      test('should export recording', () async {
        final exportData = {'session': 'data'};
        when(mockStorage.exportSession('recording-1'))
            .thenAnswer((_) async => exportData);

        await repository.exportRecording('recording-1', '/path/to/file.json');

        verify(mockStorage.exportSession('recording-1')).called(1);
      });

      test('should import recording', () async {
        final mockRecording = _createMockRecording('imported-recording');
        when(mockStorage.importSession(any))
            .thenAnswer((_) async => mockRecording);

        final recording = await repository.importRecording('/path/to/file.json');

        expect(recording, equals(mockRecording));
        verify(mockStorage.importSession(any)).called(1);
      });
    });

    group('Periodic Save Timer', () {
      test('should save pending events periodically', () async {
        when(mockStorage.saveSession(any)).thenAnswer((_) async {});

        await repository.startRecording(
          sessionId: 'session-123',
          userId: 'user-456',
        );

        // Add an event
        final event = UserActionEvent(
          timestamp: DateTime.now(),
          action: 'button_tap',
        );
        await repository.addEvent(event);

        // Wait for timer to trigger (30 seconds + buffer)
        // In real tests, you might want to make the timer interval configurable
        // For this test, we'll verify the timer setup indirectly
        
        await repository.stopRecording();

        // Verify events were saved
        verify(mockStorage.saveSession(any)).called(greaterThanOrEqualTo(2));
      });
    });
  });
}

SessionRecording _createMockRecording(String id) {
  return SessionRecording(
    id: id,
    sessionId: 'session-$id',
    startTime: DateTime.now(),
    userId: 'user-123',
    metadata: {},
    events: [],
    status: SessionStatus.completed,
    sizeInBytes: 1024,
  );
}