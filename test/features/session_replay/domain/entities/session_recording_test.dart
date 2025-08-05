import 'package:test/test.dart';
import 'package:voo_logging/features/session_replay/domain/entities/session_recording.dart';
import 'package:voo_logging/features/logging/domain/entities/log_entry.dart';
import 'package:voo_logging/core/domain/enums/log_level.dart';

void main() {
  group('SessionRecording', () {
    test('should create a session recording with required fields', () {
      final startTime = DateTime.now();
      final recording = SessionRecording(
        id: 'test-id',
        sessionId: 'session-123',
        startTime: startTime,
        userId: 'user-456',
        metadata: {'app_version': '1.0.0'},
        events: [],
        status: SessionStatus.recording,
        sizeInBytes: 0,
      );

      expect(recording.id, equals('test-id'));
      expect(recording.sessionId, equals('session-123'));
      expect(recording.startTime, equals(startTime));
      expect(recording.userId, equals('user-456'));
      expect(recording.metadata, equals({'app_version': '1.0.0'}));
      expect(recording.events, isEmpty);
      expect(recording.status, equals(SessionStatus.recording));
      expect(recording.sizeInBytes, equals(0));
      expect(recording.endTime, isNull);
      expect(recording.deviceInfo, isNull);
    });

    test('should calculate duration correctly for ongoing recording', () {
      final startTime = DateTime.now().subtract(Duration(minutes: 5));
      final recording = SessionRecording(
        id: 'test-id',
        sessionId: 'session-123',
        startTime: startTime,
        userId: 'user-456',
        metadata: {},
        events: [],
        status: SessionStatus.recording,
        sizeInBytes: 0,
      );

      final duration = recording.duration;
      expect(duration.inMinutes, greaterThanOrEqualTo(4));
      expect(duration.inMinutes, lessThanOrEqualTo(6));
    });

    test('should calculate duration correctly for completed recording', () {
      final startTime = DateTime.now().subtract(Duration(minutes: 10));
      final endTime = DateTime.now().subtract(Duration(minutes: 5));
      final recording = SessionRecording(
        id: 'test-id',
        sessionId: 'session-123',
        startTime: startTime,
        endTime: endTime,
        userId: 'user-456',
        metadata: {},
        events: [],
        status: SessionStatus.completed,
        sizeInBytes: 0,
      );

      final duration = recording.duration;
      expect(duration.inMinutes, equals(5));
    });

    test('should create copy with updated fields', () {
      final recording = SessionRecording(
        id: 'test-id',
        sessionId: 'session-123',
        startTime: DateTime.now(),
        userId: 'user-456',
        metadata: {},
        events: [],
        status: SessionStatus.recording,
        sizeInBytes: 0,
      );

      final endTime = DateTime.now();
      final updatedRecording = recording.copyWith(
        endTime: endTime,
        status: SessionStatus.completed,
        sizeInBytes: 1024,
      );

      expect(updatedRecording.id, equals(recording.id));
      expect(updatedRecording.endTime, equals(endTime));
      expect(updatedRecording.status, equals(SessionStatus.completed));
      expect(updatedRecording.sizeInBytes, equals(1024));
    });

    test('should be equal when all properties match', () {
      final startTime = DateTime.now();
      final recording1 = SessionRecording(
        id: 'test-id',
        sessionId: 'session-123',
        startTime: startTime,
        userId: 'user-456',
        metadata: {},
        events: [],
        status: SessionStatus.recording,
        sizeInBytes: 0,
      );

      final recording2 = SessionRecording(
        id: 'test-id',
        sessionId: 'session-123',
        startTime: startTime,
        userId: 'user-456',
        metadata: {},
        events: [],
        status: SessionStatus.recording,
        sizeInBytes: 0,
      );

      expect(recording1, equals(recording2));
      expect(recording1.hashCode, equals(recording2.hashCode));
    });
  });

  group('SessionStatus', () {
    test('should have all expected status values', () {
      expect(SessionStatus.values, contains(SessionStatus.recording));
      expect(SessionStatus.values, contains(SessionStatus.paused));
      expect(SessionStatus.values, contains(SessionStatus.completed));
      expect(SessionStatus.values, contains(SessionStatus.error));
    });
  });

  group('LogEvent', () {
    test('should create log event with proper timestamp and log entry', () {
      final timestamp = DateTime.now();
      final logEntry = LogEntry(
        id: 'log-123',
        timestamp: timestamp,
        message: 'Test log message',
        level: LogLevel.info,
      );

      final event = LogEvent(
        timestamp: timestamp,
        logEntry: logEntry,
      );

      expect(event.timestamp, equals(timestamp));
      expect(event.type, equals('log'));
      expect(event.logEntry, equals(logEntry));
    });

    test('should serialize to JSON correctly', () {
      final timestamp = DateTime.now();
      final logEntry = LogEntry(
        id: 'log-123',
        timestamp: timestamp,
        message: 'Test log message',
        level: LogLevel.info,
        category: 'test',
        tag: 'unit-test',
        metadata: {'key': 'value'},
        userId: 'user-456',
        sessionId: 'session-789',
      );

      final event = LogEvent(
        timestamp: timestamp,
        logEntry: logEntry,
      );

      final json = event.toJson();

      expect(json['timestamp'], equals(timestamp.toIso8601String()));
      expect(json['type'], equals('log'));
      expect(json['logEntry']['id'], equals('log-123'));
      expect(json['logEntry']['message'], equals('Test log message'));
      expect(json['logEntry']['level'], equals('info'));
      expect(json['logEntry']['category'], equals('test'));
      expect(json['logEntry']['tag'], equals('unit-test'));
      expect(json['logEntry']['metadata'], equals({'key': 'value'}));
      expect(json['logEntry']['userId'], equals('user-456'));
      expect(json['logEntry']['sessionId'], equals('session-789'));
    });

    test('should be equal when properties match', () {
      final timestamp = DateTime.now();
      final logEntry = LogEntry(
        id: 'log-123',
        timestamp: timestamp,
        message: 'Test log message',
        level: LogLevel.info,
      );

      final event1 = LogEvent(timestamp: timestamp, logEntry: logEntry);
      final event2 = LogEvent(timestamp: timestamp, logEntry: logEntry);

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
    });
  });

  group('UserActionEvent', () {
    test('should create user action event with required fields', () {
      final timestamp = DateTime.now();
      final event = UserActionEvent(
        timestamp: timestamp,
        action: 'button_tap',
        screen: 'home_screen',
        properties: {'button_id': 'submit'},
      );

      expect(event.timestamp, equals(timestamp));
      expect(event.type, equals('user_action'));
      expect(event.action, equals('button_tap'));
      expect(event.screen, equals('home_screen'));
      expect(event.properties, equals({'button_id': 'submit'}));
    });

    test('should serialize to JSON correctly', () {
      final timestamp = DateTime.now();
      final event = UserActionEvent(
        timestamp: timestamp,
        action: 'button_tap',
        screen: 'home_screen',
        properties: {'button_id': 'submit'},
      );

      final json = event.toJson();

      expect(json['timestamp'], equals(timestamp.toIso8601String()));
      expect(json['type'], equals('user_action'));
      expect(json['action'], equals('button_tap'));
      expect(json['screen'], equals('home_screen'));
      expect(json['properties'], equals({'button_id': 'submit'}));
    });

    test('should handle null optional fields', () {
      final timestamp = DateTime.now();
      final event = UserActionEvent(
        timestamp: timestamp,
        action: 'button_tap',
      );

      expect(event.screen, isNull);
      expect(event.properties, isNull);

      final json = event.toJson();
      expect(json['screen'], isNull);
      expect(json['properties'], isNull);
    });
  });

  group('NetworkEvent', () {
    test('should create network event with required fields', () {
      final timestamp = DateTime.now();
      final event = NetworkEvent(
        timestamp: timestamp,
        method: 'GET',
        url: 'https://api.example.com/users',
        statusCode: 200,
        duration: Duration(milliseconds: 500),
        headers: {'content-type': 'application/json'},
        metadata: {'retry_count': 0},
      );

      expect(event.timestamp, equals(timestamp));
      expect(event.type, equals('network'));
      expect(event.method, equals('GET'));
      expect(event.url, equals('https://api.example.com/users'));
      expect(event.statusCode, equals(200));
      expect(event.duration, equals(Duration(milliseconds: 500)));
      expect(event.headers, equals({'content-type': 'application/json'}));
      expect(event.metadata, equals({'retry_count': 0}));
    });

    test('should serialize to JSON correctly', () {
      final timestamp = DateTime.now();
      final event = NetworkEvent(
        timestamp: timestamp,
        method: 'POST',
        url: 'https://api.example.com/users',
        statusCode: 201,
        duration: Duration(milliseconds: 750),
        headers: {'content-type': 'application/json'},
        metadata: {'payload_size': 1024},
      );

      final json = event.toJson();

      expect(json['timestamp'], equals(timestamp.toIso8601String()));
      expect(json['type'], equals('network'));
      expect(json['method'], equals('POST'));
      expect(json['url'], equals('https://api.example.com/users'));
      expect(json['statusCode'], equals(201));
      expect(json['duration'], equals(750));
      expect(json['headers'], equals({'content-type': 'application/json'}));
      expect(json['metadata'], equals({'payload_size': 1024}));
    });

    test('should handle null optional fields', () {
      final timestamp = DateTime.now();
      final event = NetworkEvent(
        timestamp: timestamp,
        method: 'GET',
        url: 'https://api.example.com/users',
      );

      expect(event.statusCode, isNull);
      expect(event.duration, isNull);
      expect(event.headers, isNull);
      expect(event.metadata, isNull);

      final json = event.toJson();
      expect(json['statusCode'], isNull);
      expect(json['duration'], isNull);
      expect(json['headers'], isNull);
      expect(json['metadata'], isNull);
    });
  });

  group('ScreenNavigationEvent', () {
    test('should create navigation event with required fields', () {
      final timestamp = DateTime.now();
      final event = ScreenNavigationEvent(
        timestamp: timestamp,
        fromScreen: 'home',
        toScreen: 'profile',
        parameters: {'user_id': '123'},
      );

      expect(event.timestamp, equals(timestamp));
      expect(event.type, equals('navigation'));
      expect(event.fromScreen, equals('home'));
      expect(event.toScreen, equals('profile'));
      expect(event.parameters, equals({'user_id': '123'}));
    });

    test('should serialize to JSON correctly', () {
      final timestamp = DateTime.now();
      final event = ScreenNavigationEvent(
        timestamp: timestamp,
        fromScreen: 'home',
        toScreen: 'profile',
        parameters: {'user_id': '123'},
      );

      final json = event.toJson();

      expect(json['timestamp'], equals(timestamp.toIso8601String()));
      expect(json['type'], equals('navigation'));
      expect(json['fromScreen'], equals('home'));
      expect(json['toScreen'], equals('profile'));
      expect(json['parameters'], equals({'user_id': '123'}));
    });

    test('should handle null parameters', () {
      final timestamp = DateTime.now();
      final event = ScreenNavigationEvent(
        timestamp: timestamp,
        fromScreen: 'home',
        toScreen: 'settings',
      );

      expect(event.parameters, isNull);

      final json = event.toJson();
      expect(json['parameters'], isNull);
    });
  });

  group('AppStateEvent', () {
    test('should create app state event with required fields', () {
      final timestamp = DateTime.now();
      final event = AppStateEvent(
        timestamp: timestamp,
        state: 'foreground',
        details: {'previous_state': 'background'},
      );

      expect(event.timestamp, equals(timestamp));
      expect(event.type, equals('app_state'));
      expect(event.state, equals('foreground'));
      expect(event.details, equals({'previous_state': 'background'}));
    });

    test('should serialize to JSON correctly', () {
      final timestamp = DateTime.now();
      final event = AppStateEvent(
        timestamp: timestamp,
        state: 'background',
        details: {'reason': 'user_switched_app'},
      );

      final json = event.toJson();

      expect(json['timestamp'], equals(timestamp.toIso8601String()));
      expect(json['type'], equals('app_state'));
      expect(json['state'], equals('background'));
      expect(json['details'], equals({'reason': 'user_switched_app'}));
    });

    test('should handle null details', () {
      final timestamp = DateTime.now();
      final event = AppStateEvent(
        timestamp: timestamp,
        state: 'inactive',
      );

      expect(event.details, isNull);

      final json = event.toJson();
      expect(json['details'], isNull);
    });
  });
}