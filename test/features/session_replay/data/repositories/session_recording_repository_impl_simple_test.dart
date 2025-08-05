import 'dart:async';

import 'package:sembast/sembast_memory.dart';
import 'package:test/test.dart';
import 'package:voo_logging/features/session_replay/data/datasources/session_recording_storage.dart';
import 'package:voo_logging/features/session_replay/data/repositories/session_recording_repository_impl.dart';
import 'package:voo_logging/features/session_replay/domain/entities/session_recording.dart';

void main() {
  group('SessionRecordingRepositoryImpl Simple Tests', () {
    late SessionRecordingRepositoryImpl repository;
    late SessionRecordingStorage storage;

    setUp(() async {
      // Use a unique database for each test to ensure isolation
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final db = await databaseFactoryMemory.openDatabase('test_repo_$timestamp.db');
      SessionRecordingStorage.setDatabaseForTesting(db);
      
      storage = SessionRecordingStorage();
      repository = SessionRecordingRepositoryImpl(storage: storage);
    });

    tearDown(() {
      repository.dispose();
      SessionRecordingStorage.setDatabaseForTesting(null);
    });

    test('should start recording successfully', () async {
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
    });

    test('should stop recording', () async {
      await repository.startRecording(
        sessionId: 'session-123',
        userId: 'user-456',
      );

      await repository.stopRecording();

      expect(repository.isRecording, isFalse);
      
      final recordings = await repository.getRecordings();
      expect(recordings.length, equals(1));
      expect(recordings.first.status, equals(SessionStatus.completed));
    });

    test('should add events during recording', () async {
      await repository.startRecording(
        sessionId: 'session-123',
        userId: 'user-456',
      );

      final event = UserActionEvent(
        timestamp: DateTime.now(),
        action: 'button_click',
        screen: 'home',
      );

      await repository.addEvent(event);

      // Force save
      await repository.stopRecording();

      final recordings = await repository.getRecordings();
      expect(recordings.first.events.length, equals(1));
      expect(recordings.first.events.first, isA<UserActionEvent>());
    });

    test('should handle pause and resume', () async {
      await repository.startRecording(
        sessionId: 'session-123',
        userId: 'user-456',
      );

      await repository.pauseRecording();
      
      final currentRecording = await repository.getCurrentRecording();
      expect(currentRecording!.status, equals(SessionStatus.paused));

      await repository.resumeRecording();
      
      final resumedRecording = await repository.getCurrentRecording();
      expect(resumedRecording!.status, equals(SessionStatus.recording));
    });

    test('should batch events when threshold is reached', () async {
      await repository.startRecording(
        sessionId: 'session-123',
        userId: 'user-456',
      );

      // Add 100 events to trigger batch save
      for (int i = 0; i < 100; i++) {
        await repository.addEvent(
          UserActionEvent(
            timestamp: DateTime.now().add(Duration(milliseconds: i)),
            action: 'action_$i',
          ),
        );
      }

      await repository.stopRecording();

      final recordings = await repository.getRecordings();
      expect(recordings.first.events.length, equals(100));
    });

    test('should query recordings with filters', () async {
      // Create multiple recordings
      await repository.startRecording(
        sessionId: 'session-1',
        userId: 'user-1',
      );
      await repository.stopRecording();

      await Future.delayed(Duration(milliseconds: 10));

      await repository.startRecording(
        sessionId: 'session-2',
        userId: 'user-2',
      );
      await repository.stopRecording();

      // Query by user ID
      final user1Recordings = await repository.getRecordings(userId: 'user-1');
      expect(user1Recordings.length, equals(1));
      expect(user1Recordings.first.userId, equals('user-1'));

      // Query all
      final allRecordings = await repository.getRecordings();
      expect(allRecordings.length, equals(2));
    });

    test('should delete old recordings', () async {
      // Create old recording
      await repository.startRecording(
        sessionId: 'old-session',
        userId: 'user-123',
      );
      await repository.stopRecording();

      await Future.delayed(Duration(milliseconds: 10));

      // Create new recording
      await repository.startRecording(
        sessionId: 'new-session',
        userId: 'user-123',
      );
      await repository.stopRecording();

      // Delete recordings older than 5 milliseconds
      await repository.deleteOldRecordings(Duration(milliseconds: 5));

      final remainingRecordings = await repository.getRecordings();
      expect(remainingRecordings.length, equals(1));
      expect(remainingRecordings.first.sessionId, equals('new-session'));
    });

    test('should track recording state in stream', () async {
      final states = <SessionRecording>[];
      repository.recordingStream.listen(states.add);

      await repository.startRecording(
        sessionId: 'session-123',
        userId: 'user-456',
      );

      await repository.pauseRecording();
      await repository.resumeRecording();
      await repository.stopRecording();

      // Allow stream events to propagate
      await Future.delayed(Duration(milliseconds: 100));

      expect(states.length, greaterThanOrEqualTo(4));
      expect(states.first.status, equals(SessionStatus.recording));
      expect(states.last.status, equals(SessionStatus.completed));
    });

    test('should ignore events when not recording', () async {
      // Don't start recording
      final event = UserActionEvent(
        timestamp: DateTime.now(),
        action: 'button_click',
      );

      await repository.addEvent(event);

      // This should not throw
      expect(repository.isRecording, isFalse);
    });

    test('should handle errors gracefully', () async {
      await repository.startRecording(
        sessionId: 'session-123',
        userId: 'user-456',
      );

      // Add a large number of events to test error handling
      for (int i = 0; i < 1000; i++) {
        await repository.addEvent(
          UserActionEvent(
            timestamp: DateTime.now(),
            action: 'action_$i',
            properties: {'index': i, 'data': 'x' * 1000},
          ),
        );
      }

      await repository.stopRecording();

      // Should complete without throwing
      final recordings = await repository.getRecordings();
      expect(recordings.first.events.length, greaterThan(0));
    });
  });
}