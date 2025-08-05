import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:test/test.dart';
import 'package:voo_logging/core/domain/enums/log_level.dart';
import 'package:voo_logging/features/logging/domain/entities/log_entry.dart';
import 'package:voo_logging/features/session_replay/data/datasources/session_recording_storage.dart';
import 'package:voo_logging/features/session_replay/domain/entities/session_recording.dart';

void main() {
  group('SessionRecordingStorage', () {
    late SessionRecordingStorage storage;
    late Database testDb;

    setUp(() async {
      // Create unique database for each test
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      testDb = await databaseFactoryMemory.openDatabase('test_storage_$timestamp.db');
      SessionRecordingStorage.setDatabaseForTesting(testDb);
      storage = SessionRecordingStorage();
    });

    tearDown(() async {
      await testDb.close();
      SessionRecordingStorage.setDatabaseForTesting(null);
    });

    group('Session Recording CRUD Operations', () {
      test('should save and retrieve a session recording', () async {
        // Create test session
        final session = _createTestSession();

        // Save session
        await storage.saveSession(session);

        // Retrieve session
        final retrievedSession = await storage.getSession(session.id);

        expect(retrievedSession, isNotNull);
        expect(retrievedSession!.id, equals(session.id));
        expect(retrievedSession.sessionId, equals(session.sessionId));
        expect(retrievedSession.userId, equals(session.userId));
        expect(retrievedSession.status, equals(session.status));
        expect(retrievedSession.events.length, equals(session.events.length));
      });

      test('should return null for non-existent session', () async {
        final result = await storage.getSession('non-existent-id');

        expect(result, isNull);
      });

      test('should delete a session successfully', () async {
        final session = _createTestSession();
        await storage.saveSession(session);

        // Verify session exists
        var retrievedSession = await storage.getSession(session.id);
        expect(retrievedSession, isNotNull);

        // Delete session
        await storage.deleteSession(session.id);

        // Verify session is deleted
        retrievedSession = await storage.getSession(session.id);
        expect(retrievedSession, isNull);
      });

      test('should query sessions with filters', () async {
        // Create multiple test sessions
        final session1 = _createTestSession(id: 'session1', userId: 'user1');
        final session2 = _createTestSession(id: 'session2', userId: 'user2');
        final session3 = _createTestSession(id: 'session3', userId: 'user1');

        await storage.saveSession(session1);
        await storage.saveSession(session2);
        await storage.saveSession(session3);

        // Query by user ID
        final userSessions = await storage.querySessions(userId: 'user1');
        expect(userSessions.length, equals(2));
        expect(userSessions.map((s) => s.id), containsAll(['session1', 'session3']));

        // Query with limit
        final limitedSessions = await storage.querySessions(limit: 2);
        expect(limitedSessions.length, equals(2));
      });

      test('should delete old sessions', () async {
        // Create sessions with different ages
        final oldSession = _createTestSession(
          id: 'old',
          startTime: DateTime.now().subtract(Duration(days: 10)),
        );
        final recentSession = _createTestSession(
          id: 'recent',
          startTime: DateTime.now().subtract(Duration(hours: 1)),
        );

        await storage.saveSession(oldSession);
        await storage.saveSession(recentSession);

        // Delete sessions older than 7 days
        await storage.deleteOldSessions(Duration(days: 7));

        // Verify old session is deleted, recent session remains
        final oldRetrieved = await storage.getSession('old');
        final recentRetrieved = await storage.getSession('recent');

        expect(oldRetrieved, isNull);
        expect(recentRetrieved, isNotNull);
      });
    });

    group('Event Compression and Parsing', () {
      test('should compress and decompress events correctly', () async {
        final session = _createTestSessionWithEvents();
        await storage.saveSession(session);

        final retrievedSession = await storage.getSession(session.id);

        expect(retrievedSession, isNotNull);
        expect(retrievedSession!.events.length, equals(session.events.length));

        // Check that events are correctly parsed
        final logEvent = retrievedSession.events
            .whereType<LogEvent>()
            .first;
        expect(logEvent.logEntry.message, equals('Test log message'));
        expect(logEvent.logEntry.level, equals(LogLevel.info));

        final userActionEvent = retrievedSession.events
            .whereType<UserActionEvent>()
            .first;
        expect(userActionEvent.action, equals('button_tap'));
        expect(userActionEvent.screen, equals('home'));
      });

      test('should handle different event types correctly', () async {
        final events = [
          LogEvent(
            timestamp: DateTime.now(),
            logEntry: LogEntry(
              id: 'log-1',
              timestamp: DateTime.now(),
              message: 'Test message',
              level: LogLevel.error,
            ),
          ),
          UserActionEvent(
            timestamp: DateTime.now(),
            action: 'swipe',
            screen: 'gallery',
            properties: {'direction': 'left'},
          ),
          NetworkEvent(
            timestamp: DateTime.now(),
            method: 'POST',
            url: 'https://api.test.com/data',
            statusCode: 201,
            duration: Duration(milliseconds: 300),
          ),
          ScreenNavigationEvent(
            timestamp: DateTime.now(),
            fromScreen: 'home',
            toScreen: 'settings',
            parameters: {'tab': 'privacy'},
          ),
          AppStateEvent(
            timestamp: DateTime.now(),
            state: 'paused',
            details: {'reason': 'incoming_call'},
          ),
        ];

        final session = SessionRecording(
          id: 'test-events',
          sessionId: 'session-events',
          startTime: DateTime.now(),
          userId: 'user-test',
          metadata: {},
          events: events,
          status: SessionStatus.recording,
          sizeInBytes: 0,
        );

        await storage.saveSession(session);
        final retrieved = await storage.getSession(session.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.events.length, equals(5));

        // Verify each event type
        expect(retrieved.events.whereType<LogEvent>().length, equals(1));
        expect(retrieved.events.whereType<UserActionEvent>().length, equals(1));
        expect(retrieved.events.whereType<NetworkEvent>().length, equals(1));
        expect(retrieved.events.whereType<ScreenNavigationEvent>().length, equals(1));
        expect(retrieved.events.whereType<AppStateEvent>().length, equals(1));
      });
    });

    group('Export and Import', () {
      test('should export session correctly', () async {
        final session = _createTestSessionWithEvents();
        await storage.saveSession(session);

        final exportData = await storage.exportSession(session.id);

        expect(exportData['version'], equals(1));
        expect(exportData['exportDate'], isNotNull);
        expect(exportData['session'], isNotNull);
        
        final sessionData = exportData['session'] as Map<String, dynamic>;
        expect(sessionData['id'], equals(session.id));
        expect(sessionData['events'], isA<List>());
      });

      test('should import session correctly', () async {
        final originalSession = _createTestSessionWithEvents();
        final exportData = {
          'version': 1,
          'exportDate': DateTime.now().toIso8601String(),
          'session': {
            'id': originalSession.id,
            'sessionId': originalSession.sessionId,
            'startTime': originalSession.startTime.toIso8601String(),
            'endTime': originalSession.endTime?.toIso8601String(),
            'userId': originalSession.userId,
            'deviceInfo': originalSession.deviceInfo,
            'metadata': originalSession.metadata,
            'status': originalSession.status.name,
            'events': originalSession.events.map((e) => e.toJson()).toList(),
          },
        };

        final importedSession = await storage.importSession(exportData);

        expect(importedSession.id, equals(originalSession.id));
        expect(importedSession.sessionId, equals(originalSession.sessionId));
        expect(importedSession.events.length, equals(originalSession.events.length));

        // Verify session was saved
        final retrievedSession = await storage.getSession(importedSession.id);
        expect(retrievedSession, isNotNull);
      });

      test('should throw exception when exporting non-existent session', () async {
        expect(
          () => storage.exportSession('non-existent'),
          throwsException,
        );
      });
    });

    group('Storage Management', () {
      test('should calculate total storage size', () async {
        final session1 = _createTestSession(sizeInBytes: 1024);
        final session2 = _createTestSession(id: 'session2', sizeInBytes: 2048);

        await storage.saveSession(session1);
        await storage.saveSession(session2);

        final totalSize = await storage.getTotalStorageSize();

        expect(totalSize, equals(3072));
      });
    });
  });
}

SessionRecording _createTestSession({
  String id = 'test-session',
  String userId = 'test-user',
  DateTime? startTime,
  int sizeInBytes = 0,
}) {
  return SessionRecording(
    id: id,
    sessionId: 'session-123',
    startTime: startTime ?? DateTime.now(),
    userId: userId,
    metadata: {'app_version': '1.0.0'},
    events: [],
    status: SessionStatus.recording,
    sizeInBytes: sizeInBytes,
  );
}

SessionRecording _createTestSessionWithEvents() {
  final events = [
    LogEvent(
      timestamp: DateTime.now(),
      logEntry: LogEntry(
        id: 'log-1',
        timestamp: DateTime.now(),
        message: 'Test log message',
        level: LogLevel.info,
        category: 'test',
      ),
    ),
    UserActionEvent(
      timestamp: DateTime.now(),
      action: 'button_tap',
      screen: 'home',
      properties: {'button_id': 'submit'},
    ),
  ];

  return SessionRecording(
    id: 'test-with-events',
    sessionId: 'session-456',
    startTime: DateTime.now(),
    userId: 'test-user',
    metadata: {'app_version': '1.0.0'},
    events: events,
    status: SessionStatus.recording,
    sizeInBytes: 1024,
  );
}