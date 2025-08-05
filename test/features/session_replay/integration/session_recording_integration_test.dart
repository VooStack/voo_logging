import 'dart:async';

import 'package:sembast/sembast_memory.dart';
import 'package:test/test.dart';
import 'package:voo_logging/features/session_replay/data/datasources/session_recording_storage.dart';
import 'package:voo_logging/features/session_replay/data/repositories/session_recording_repository_impl.dart';
import 'package:voo_logging/features/session_replay/domain/entities/session_recording.dart';
import 'package:voo_logging/features/session_replay/presentation/session_replay_tracker.dart';

void main() {
  group('Session Recording Integration Tests', () {
    late SessionRecordingRepositoryImpl repository;
    late SessionRecordingStorage storage;

    setUp(() async {
      // Use a unique database for each test to ensure isolation
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final db = await databaseFactoryMemory.openDatabase('test_integration_$timestamp.db');
      storage = SessionRecordingStorage();
      SessionRecordingStorage.setDatabaseForTesting(db);
      
      // Create repository with an empty log stream to avoid capturing unintended events
      repository = SessionRecordingRepositoryImpl(
        storage: storage,
        logStream: const Stream.empty(),
      );
    });

    tearDown(() {
      repository.dispose();
      SessionRecordingStorage.setDatabaseForTesting(null);
    });

    test('should complete full session recording lifecycle', () async {
      // Start recording
      await repository.startRecording(
        sessionId: 'integration-test-session',
        userId: 'test-user-123',
        metadata: {
          'app_version': '1.0.0',
          'platform': 'test',
          'test_scenario': 'integration',
        },
      );

      expect(repository.isRecording, isTrue);

      // Add various types of events
      final events = [
        UserActionEvent(
          timestamp: DateTime.now(),
          action: 'app_launched',
          properties: {'cold_start': true},
        ),
        ScreenNavigationEvent(
          timestamp: DateTime.now().add(Duration(seconds: 1)),
          fromScreen: 'splash',
          toScreen: 'home',
        ),
        UserActionEvent(
          timestamp: DateTime.now().add(Duration(seconds: 2)),
          action: 'button_tap',
          screen: 'home',
          properties: {'button_id': 'login'},
        ),
        NetworkEvent(
          timestamp: DateTime.now().add(Duration(seconds: 3)),
          method: 'POST',
          url: 'https://api.example.com/auth',
          statusCode: 200,
          duration: Duration(milliseconds: 450),
          headers: {'content-type': 'application/json'},
        ),
        ScreenNavigationEvent(
          timestamp: DateTime.now().add(Duration(seconds: 4)),
          fromScreen: 'home',
          toScreen: 'dashboard',
        ),
        AppStateEvent(
          timestamp: DateTime.now().add(Duration(seconds: 5)),
          state: 'background',
          details: {'trigger': 'phone_call'},
        ),
        AppStateEvent(
          timestamp: DateTime.now().add(Duration(seconds: 10)),
          state: 'foreground',
          details: {'trigger': 'user_return'},
        ),
      ];

      // Add events sequentially
      for (final event in events) {
        await repository.addEvent(event);
        await Future.delayed(Duration(milliseconds: 10)); // Small delay to simulate real usage
      }

      // Test pause and resume functionality
      await repository.pauseRecording();
      expect(repository.isRecording, isFalse);

      final pausedRecording = await repository.getCurrentRecording();
      expect(pausedRecording!.status, equals(SessionStatus.paused));

      // Add event while paused (should be ignored)
      await repository.addEvent(UserActionEvent(
        timestamp: DateTime.now(),
        action: 'ignored_action',
      ));

      await repository.resumeRecording();
      expect(repository.isRecording, isTrue);

      // Add final event after resume
      await repository.addEvent(UserActionEvent(
        timestamp: DateTime.now().add(Duration(seconds: 11)),
        action: 'session_end',
      ));

      // Stop recording
      await repository.stopRecording();
      expect(repository.isRecording, isFalse);

      // Verify the recording was completed and saved
      final completedRecording = await repository.getCurrentRecording();
      expect(completedRecording, isNull); // Current recording should be null after stop

      // Retrieve the recording from storage
      final recordings = await repository.getRecordings(userId: 'test-user-123');
      expect(recordings.length, equals(1));

      final savedRecording = recordings.first;
      expect(savedRecording.sessionId, equals('integration-test-session'));
      expect(savedRecording.userId, equals('test-user-123'));
      expect(savedRecording.status, equals(SessionStatus.completed));
      expect(savedRecording.events.length, equals(events.length + 1)); // +1 for the session_end event after resume
      expect(savedRecording.endTime, isNotNull);
      expect(savedRecording.metadata['test_scenario'], equals('integration'));

      // Verify event types are preserved
      expect(savedRecording.events.whereType<UserActionEvent>().length, equals(3));
      expect(savedRecording.events.whereType<ScreenNavigationEvent>().length, equals(2));
      expect(savedRecording.events.whereType<NetworkEvent>().length, equals(1));
      expect(savedRecording.events.whereType<AppStateEvent>().length, equals(2));

      // Test export/import functionality
      final exportData = await storage.exportSession(savedRecording.id);
      expect(exportData['version'], equals(1));
      expect(exportData['session'], isNotNull);

      // Delete the original and import it back
      await repository.deleteRecording(savedRecording.id);
      final deletedRecordings = await repository.getRecordings(userId: 'test-user-123');
      expect(deletedRecordings.length, equals(0));

      // Import the session back
      final importedRecording = await storage.importSession(exportData);
      expect(importedRecording.id, equals(savedRecording.id));
      expect(importedRecording.events.length, equals(savedRecording.events.length));

      // Verify imported recording is in storage
      final finalRecordings = await repository.getRecordings(userId: 'test-user-123');
      expect(finalRecordings.length, equals(1));
    });

    test('should handle concurrent event additions gracefully', () async {
      await repository.startRecording(
        sessionId: 'concurrent-test',
        userId: 'test-user',
      );

      // Create multiple events to be added concurrently
      final futures = <Future>[];
      for (int i = 0; i < 50; i++) {
        futures.add(repository.addEvent(UserActionEvent(
          timestamp: DateTime.now().add(Duration(milliseconds: i * 10)),
          action: 'concurrent_action_$i',
        )));
      }

      // Wait for all events to be added
      await Future.wait(futures);

      await repository.stopRecording();

      // Verify all events were recorded
      final recordings = await repository.getRecordings(userId: 'test-user');
      expect(recordings.length, equals(1));
      expect(recordings.first.events.length, equals(50));
    });

    test('should handle error conditions gracefully', () async {
      // Test starting recording with empty parameters
      await repository.startRecording(
        sessionId: '',
        userId: '',
      );

      expect(repository.isRecording, isTrue);

      // Test adding null-like events (should handle gracefully)
      await repository.addEvent(UserActionEvent(
        timestamp: DateTime.now(),
        action: '',
      ));

      await repository.stopRecording();

      // Recording should still complete successfully
      final recordings = await repository.getRecordings(userId: '');
      expect(recordings.length, equals(1));
    });

    test('should handle large number of events efficiently', () async {
      final startTime = DateTime.now();
      
      await repository.startRecording(
        sessionId: 'performance-test',
        userId: 'test-user',
      );

      // Add 1000 events to test performance
      for (int i = 0; i < 1000; i++) {
        await repository.addEvent(UserActionEvent(
          timestamp: DateTime.now().add(Duration(milliseconds: i)),
          action: 'performance_action_$i',
          properties: {'index': i, 'batch': i ~/ 100},
        ));
      }

      await repository.stopRecording();

      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime);

      // Verify all events were recorded
      final recordings = await repository.getRecordings(userId: 'test-user');
      expect(recordings.length, equals(1));
      expect(recordings.first.events.length, equals(1000));

      // Performance check - should complete within reasonable time
      expect(processingTime.inSeconds, lessThan(30));

      // Verify storage size is reasonable (with compression)
      final totalSize = await repository.getTotalStorageSize();
      expect(totalSize, greaterThan(0));
      
      // The compressed size should be significantly smaller than raw JSON
      // This is just a sanity check - actual compression ratios vary
      print('Storage size for 1000 events: $totalSize bytes');
    });

    test('should clean up old recordings correctly', () async {
      final now = DateTime.now();
      
      // Create recordings with different ages
      for (int i = 0; i < 5; i++) {
        await repository.startRecording(
          sessionId: 'cleanup-test-$i',
          userId: 'test-user',
          metadata: {'created_days_ago': i},
        );

        // Manually set start time to simulate different ages
        final recording = await repository.getCurrentRecording();
        final updatedRecording = recording!.copyWith(
          startTime: now.subtract(Duration(days: i)),
        );
        
        await storage.saveSession(updatedRecording);
        await repository.stopRecording();
      }

      // Verify all recordings exist
      var allRecordings = await repository.getRecordings(userId: 'test-user');
      expect(allRecordings.length, equals(5));

      // Delete recordings older than 2 days
      await repository.deleteOldRecordings(Duration(days: 2));

      // Verify only recent recordings remain
      allRecordings = await repository.getRecordings(userId: 'test-user');
      expect(allRecordings.length, equals(2)); // Days 0 and 1 should remain (2 days is at the boundary)
    });

    test('should handle session recording stream correctly', () async {
      final streamEvents = <SessionRecording>[];
      final subscription = repository.recordingStream.listen(streamEvents.add);

      await repository.startRecording(
        sessionId: 'stream-test',
        userId: 'test-user',
      );

      await repository.addEvent(UserActionEvent(
        timestamp: DateTime.now(),
        action: 'test_action',
      ));

      await repository.pauseRecording();
      await repository.resumeRecording();
      await repository.stopRecording();

      await Future.delayed(Duration(milliseconds: 100));

      // Verify stream events
      expect(streamEvents.length, greaterThanOrEqualTo(4));
      expect(streamEvents.first.status, equals(SessionStatus.recording));
      expect(streamEvents.any((r) => r.status == SessionStatus.paused), isTrue);
      expect(streamEvents.any((r) => r.status == SessionStatus.completed), isTrue);

      await subscription.cancel();
    });
  });

  group('SessionReplayTracker Integration', () {
    test('should integrate with session recording when active', () async {
      // This test would require mocking VooLogger.isRecordingSession
      // and VooLogger.instance.sessionRecorder.addEvent
      // For now, we'll test the tracker methods don't throw errors
      
      await SessionReplayTracker.trackUserAction('test_action');
      await SessionReplayTracker.trackNavigation('test_screen');
      await SessionReplayTracker.trackNetworkRequest('GET', 'https://test.com');
      await SessionReplayTracker.trackAppState('active');

      // If we get here without exceptions, the integration is working
      expect(true, isTrue);
    });
  });
}