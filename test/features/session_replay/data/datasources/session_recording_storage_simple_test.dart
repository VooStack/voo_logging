import 'package:sembast/sembast_memory.dart';
import 'package:test/test.dart';
import 'package:voo_logging/features/session_replay/data/datasources/session_recording_storage.dart';
import 'package:voo_logging/features/session_replay/domain/entities/session_recording.dart';

void main() {
  group('SessionRecordingStorage Simple Tests', () {
    test('should create storage instance', () {
      final storage = SessionRecordingStorage();
      expect(storage, isNotNull);
    });

    test('should handle session event parsing for different event types', () async {
      final db = await databaseFactoryMemory.openDatabase('test_parsing.db');
      final storage = SessionRecordingStorage();
      
      // Set test database
      SessionRecordingStorage.setDatabaseForTesting(db);

      // Create session with various event types
      final events = [
        UserActionEvent(
          timestamp: DateTime.now(),
          action: 'button_tap',
          screen: 'home',
          properties: {'button_id': 'login'},
        ),
        NetworkEvent(
          timestamp: DateTime.now(),
          method: 'GET',
          url: 'https://api.example.com/users',
          statusCode: 200,
          duration: Duration(milliseconds: 500),
        ),
        ScreenNavigationEvent(
          timestamp: DateTime.now(),
          fromScreen: 'home',
          toScreen: 'profile',
          parameters: {'user_id': '123'},
        ),
        AppStateEvent(
          timestamp: DateTime.now(),
          state: 'background',
          details: {'reason': 'phone_call'},
        ),
      ];

      final session = SessionRecording(
        id: 'test-parsing',
        sessionId: 'session-parsing',
        startTime: DateTime.now(),
        userId: 'test-user',
        metadata: {'test': 'parsing'},
        events: events,
        status: SessionStatus.completed,
        sizeInBytes: 1024,
      );

      // This should not throw any exceptions
      await storage.saveSession(session);

      final retrieved = await storage.getSession('test-parsing');
      expect(retrieved, isNotNull);
      expect(retrieved!.events.length, equals(4));

      await db.close();
    });

    test('should calculate storage sizes correctly', () async {
      final db = await databaseFactoryMemory.openDatabase('test_sizes.db');
      final storage = SessionRecordingStorage();
      
      SessionRecordingStorage.setDatabaseForTesting(db);

      final session1 = _createTestSession('session1', 1024);
      final session2 = _createTestSession('session2', 2048);

      await storage.saveSession(session1);
      await storage.saveSession(session2);

      final totalSize = await storage.getTotalStorageSize();
      // The sessions store their original sizeInBytes values
      expect(totalSize, equals(1024 + 2048));

      await db.close();
    });

    test('should export and import session data', () async {
      final db = await databaseFactoryMemory.openDatabase('test_export.db');
      final storage = SessionRecordingStorage();
      
      SessionRecordingStorage.setDatabaseForTesting(db);

      final originalSession = _createTestSessionWithEvents();
      await storage.saveSession(originalSession);

      // Export session
      final exportData = await storage.exportSession(originalSession.id);
      expect(exportData['version'], equals(1));
      expect(exportData['session'], isNotNull);

      // Delete original
      await storage.deleteSession(originalSession.id);
      final deletedSession = await storage.getSession(originalSession.id);
      expect(deletedSession, isNull);

      // Import back
      final importedSession = await storage.importSession(exportData);
      expect(importedSession.id, equals(originalSession.id));

      await db.close();
    });

    test('should query sessions with filters', () async {
      final db = await databaseFactoryMemory.openDatabase('test_query.db');
      final storage = SessionRecordingStorage();
      
      SessionRecordingStorage.setDatabaseForTesting(db);

      // Create multiple sessions
      await storage.saveSession(_createTestSession('session1', 1024, userId: 'user1'));
      await storage.saveSession(_createTestSession('session2', 2048, userId: 'user2'));
      await storage.saveSession(_createTestSession('session3', 512, userId: 'user1'));

      // Query by user
      final user1Sessions = await storage.querySessions(userId: 'user1');
      expect(user1Sessions.length, equals(2));

      // Query with limit
      final limitedSessions = await storage.querySessions(limit: 2);
      expect(limitedSessions.length, equals(2));

      await db.close();
    });

    test('should delete old sessions', () async {
      final db = await databaseFactoryMemory.openDatabase('test_cleanup.db');
      final storage = SessionRecordingStorage();
      
      SessionRecordingStorage.setDatabaseForTesting(db);

      final now = DateTime.now();
      
      // Create sessions with different ages
      final oldSession = SessionRecording(
        id: 'old-session',
        sessionId: 'old',
        startTime: now.subtract(Duration(days: 10)),
        userId: 'test-user',
        metadata: {},
        events: [],
        status: SessionStatus.completed,
        sizeInBytes: 1024,
      );

      final recentSession = SessionRecording(
        id: 'recent-session',
        sessionId: 'recent',
        startTime: now.subtract(Duration(hours: 1)),
        userId: 'test-user',
        metadata: {},
        events: [],
        status: SessionStatus.completed,
        sizeInBytes: 1024,
      );

      await storage.saveSession(oldSession);
      await storage.saveSession(recentSession);

      // Delete sessions older than 7 days
      await storage.deleteOldSessions(Duration(days: 7));

      // Check results
      final oldRetrieved = await storage.getSession('old-session');
      final recentRetrieved = await storage.getSession('recent-session');

      expect(oldRetrieved, isNull);
      expect(recentRetrieved, isNotNull);

      await db.close();
    });

    test('should handle edge cases gracefully', () async {
      final db = await databaseFactoryMemory.openDatabase('test_edge_cases.db');
      final storage = SessionRecordingStorage();
      
      SessionRecordingStorage.setDatabaseForTesting(db);

      // Test with empty session
      final emptySession = SessionRecording(
        id: 'empty',
        sessionId: 'empty-session',
        startTime: DateTime.now(),
        userId: '',
        metadata: {},
        events: [],
        status: SessionStatus.completed,
        sizeInBytes: 0,
      );

      await storage.saveSession(emptySession);
      final retrieved = await storage.getSession('empty');
      expect(retrieved, isNotNull);

      // Test querying non-existent sessions
      final nonExistent = await storage.getSession('does-not-exist');
      expect(nonExistent, isNull);

      // Test export of non-existent session
      expect(
        () => storage.exportSession('does-not-exist'),
        throwsException,
      );

      await db.close();
    });
  });
}

SessionRecording _createTestSession(String id, int sizeInBytes, {String userId = 'test-user'}) {
  // Add a small delay based on ID to ensure different timestamps
  final timestamp = DateTime.now().add(Duration(milliseconds: id.hashCode % 1000));
  return SessionRecording(
    id: id,
    sessionId: 'session-$id',
    startTime: timestamp,
    userId: userId,
    metadata: {'test': 'session'},
    events: [],
    status: SessionStatus.completed,
    sizeInBytes: sizeInBytes,
  );
}

SessionRecording _createTestSessionWithEvents() {
  final events = [
    UserActionEvent(
      timestamp: DateTime.now(),
      action: 'test_action',
      screen: 'test_screen',
    ),
    NetworkEvent(
      timestamp: DateTime.now(),
      method: 'GET',
      url: 'https://test.com',
    ),
  ];

  return SessionRecording(
    id: 'test-with-events',
    sessionId: 'session-with-events',
    startTime: DateTime.now(),
    userId: 'test-user',
    metadata: {'test': 'events'},
    events: events,
    status: SessionStatus.completed,
    sizeInBytes: 2048,
  );
}