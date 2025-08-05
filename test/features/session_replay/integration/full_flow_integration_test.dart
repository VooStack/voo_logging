import 'dart:convert';

import 'package:sembast/sembast_memory.dart';
import 'package:test/test.dart';
import 'package:voo_logging/core/domain/enums/log_level.dart';
import 'package:voo_logging/features/logging/domain/entities/log_entry.dart';
import 'package:voo_logging/features/session_replay/data/datasources/session_recording_storage.dart';
import 'package:voo_logging/features/session_replay/data/repositories/session_recording_repository_impl.dart';
import 'package:voo_logging/features/session_replay/domain/entities/session_recording.dart';

void main() {
  group('Session Recording Full Flow Integration Test', () {
    late SessionRecordingRepositoryImpl repository;
    late SessionRecordingStorage storage;

    setUp(() async {
      // Use in-memory database for testing
      final db = await databaseFactoryMemory.openDatabase('integration_test.db');
      SessionRecordingStorage.setDatabaseForTesting(db);
      
      storage = SessionRecordingStorage();
      repository = SessionRecordingRepositoryImpl(storage: storage);
    });

    tearDown(() {
      repository.dispose();
      SessionRecordingStorage.setDatabaseForTesting(null);
    });

    test('Complete session recording flow with various event types', () async {
      // Start recording
      await repository.startRecording(
        sessionId: 'integration-test-session',
        userId: 'test-user@example.com',
        metadata: {
          'app_version': '1.0.0',
          'platform': 'test',
          'feature_flags': ['replay_enabled', 'debug_mode'],
        },
      );

      expect(repository.isRecording, isTrue);

      // Add various types of events
      
      // 1. User action events
      await repository.addEvent(UserActionEvent(
        timestamp: DateTime.now(),
        action: 'button_tap',
        screen: 'login',
        properties: {
          'button_id': 'submit_login',
          'form_valid': true,
        },
      ));

      // 2. Navigation event
      await repository.addEvent(ScreenNavigationEvent(
        timestamp: DateTime.now(),
        fromScreen: 'login',
        toScreen: 'dashboard',
        parameters: {
          'user_role': 'admin',
          'first_login': false,
        },
      ));

      // 3. Network events
      await repository.addEvent(NetworkEvent(
        timestamp: DateTime.now(),
        method: 'GET',
        url: 'https://api.example.com/user/profile',
        headers: {
          'Authorization': 'Bearer [REDACTED]',
          'User-Agent': 'VooLogger/1.0',
        },
      ));

      await repository.addEvent(NetworkEvent(
        timestamp: DateTime.now(),
        method: 'GET',
        url: 'https://api.example.com/user/profile',
        statusCode: 200,
        duration: Duration(milliseconds: 245),
        metadata: {
          'response_size': 1024,
          'cache_hit': false,
        },
      ));

      // 4. Log events
      await repository.addEvent(LogEvent(
        timestamp: DateTime.now(),
        logEntry: LogEntry(
          id: 'log-1',
          timestamp: DateTime.now(),
          message: 'User successfully logged in',
          level: LogLevel.info,
          category: 'auth',
          tag: 'login',
          metadata: {
            'user_id': 'test-user@example.com',
            'login_method': 'email',
          },
          userId: 'test-user@example.com',
          sessionId: 'integration-test-session',
        ),
      ));

      // 5. App state event
      await repository.addEvent(AppStateEvent(
        timestamp: DateTime.now(),
        state: 'foreground',
        details: {
          'previous_state': 'background',
          'duration_in_background': 30000,
        },
      ));

      // Pause and resume recording
      await repository.pauseRecording();
      final pausedRecording = await repository.getCurrentRecording();
      expect(pausedRecording!.status, equals(SessionStatus.paused));

      await repository.resumeRecording();
      final resumedRecording = await repository.getCurrentRecording();
      expect(resumedRecording!.status, equals(SessionStatus.recording));

      // Add more events after resume
      await repository.addEvent(UserActionEvent(
        timestamp: DateTime.now(),
        action: 'logout_tap',
        screen: 'settings',
      ));

      // Stop recording
      await repository.stopRecording();
      expect(repository.isRecording, isFalse);

      // Verify the session was saved correctly
      final recordings = await repository.getRecordings();
      expect(recordings.length, equals(1));

      final savedSession = recordings.first;
      expect(savedSession.sessionId, equals('integration-test-session'));
      expect(savedSession.userId, equals('test-user@example.com'));
      expect(savedSession.status, equals(SessionStatus.completed));
      // Should have at least 7 events (may have more from VooLogger stream)
      expect(savedSession.events.length, greaterThanOrEqualTo(7));
      expect(savedSession.metadata['app_version'], equals('1.0.0'));

      // Verify event types
      final eventTypes = savedSession.events.map((e) => e.type).toSet();
      expect(eventTypes, containsAll(['user_action', 'navigation', 'network', 'log', 'app_state']));

      // Test export functionality
      final exportData = await storage.exportSession(savedSession.id);
      expect(exportData['session']['id'], equals(savedSession.id));
      expect(exportData['session']['events'], isA<List>());
      expect((exportData['session']['events'] as List).length, greaterThanOrEqualTo(7));

      // Test import functionality
      final importedSession = await storage.importSession(exportData);
      expect(importedSession.id, equals(savedSession.id));
      expect(importedSession.events.length, equals(savedSession.events.length));

      // Test querying
      final queriedSessions = await repository.getRecordings(
        userId: 'test-user@example.com',
      );
      expect(queriedSessions.length, equals(1));

      // Test storage size calculation
      final totalSize = await repository.getTotalStorageSize();
      expect(totalSize, greaterThan(0));

      // Test deletion
      await repository.deleteRecording(savedSession.id);
      final remainingSessions = await repository.getRecordings();
      expect(remainingSessions.length, equals(0));
    });

    test('Handle large number of events efficiently', () async {
      final stopwatch = Stopwatch()..start();

      await repository.startRecording(
        sessionId: 'performance-test',
        userId: 'perf-user',
      );

      // Add 1000 events
      for (int i = 0; i < 1000; i++) {
        await repository.addEvent(UserActionEvent(
          timestamp: DateTime.now().add(Duration(milliseconds: i)),
          action: 'action_$i',
          screen: 'screen_${i % 10}',
          properties: {
            'index': i,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ));
      }

      await repository.stopRecording();
      stopwatch.stop();

      // Should complete in reasonable time (less than 5 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));

      final recordings = await repository.getRecordings();
      // Should have at least 1000 events (may have more from VooLogger stream)
      expect(recordings.first.events.length, greaterThanOrEqualTo(1000));

      // Verify compression is working
      final exportData = await storage.exportSession(recordings.first.id);
      final jsonString = jsonEncode(exportData);
      final uncompressedSize = utf8.encode(jsonString).length;
      expect(recordings.first.sizeInBytes, lessThan(uncompressedSize));
    });

    test('Handle concurrent operations safely', () async {
      await repository.startRecording(
        sessionId: 'concurrent-test',
        userId: 'concurrent-user',
      );

      // Add events concurrently
      final futures = List.generate(100, (i) {
        return repository.addEvent(UserActionEvent(
          timestamp: DateTime.now().add(Duration(milliseconds: i)),
          action: 'concurrent_action_$i',
        ));
      });

      await Future.wait(futures);

      await repository.stopRecording();

      final recordings = await repository.getRecordings();
      // Should have at least 100 events (may have more from VooLogger stream)
      expect(recordings.first.events.length, greaterThanOrEqualTo(100));
    });
  });
}