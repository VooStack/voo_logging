import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:voo_logging/features/session_replay/domain/entities/session_recording.dart';
import 'package:voo_logging/features/logging/domain/entities/log_entry.dart';
import 'package:voo_logging/core/domain/enums/log_level.dart';
import 'package:archive/archive.dart';

class SessionRecordingStorage {
  static SessionRecordingStorage? _instance;
  static Database? _database;
  
  // For testing - allows injection of custom database
  static void setDatabaseForTesting(Database? database) {
    _database = database;
  }

  static final _sessionsStore = intMapStoreFactory.store('session_recordings');
  static final _eventsStore = intMapStoreFactory.store('session_events');
  static final _metadataStore = stringMapStoreFactory.store('session_metadata');

  factory SessionRecordingStorage() {
    _instance ??= SessionRecordingStorage._internal();
    return _instance!;
  }

  SessionRecordingStorage._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    DatabaseFactory dbFactory;
    String dbPath;

    if (kIsWeb) {
      dbFactory = databaseFactoryWeb;
      dbPath = 'voo_session_recordings.db';
    } else {
      dbFactory = databaseFactoryIo;

      final appDocDir = await getApplicationDocumentsDirectory();
      final dbDirectory = Directory(path.join(appDocDir.path, 'voo_logging', 'sessions'));

      if (!dbDirectory.existsSync()) {
        dbDirectory.createSync(recursive: true);
      }

      dbPath = path.join(dbDirectory.path, 'session_recordings.db');
    }

    final db = await dbFactory.openDatabase(dbPath);
    await _initializeMetadata(db);

    return db;
  }

  Future<void> _initializeMetadata(Database db) async {
    final existingVersion = await _metadataStore.record('schema_version').get(db);

    if (existingVersion == null) {
      await _metadataStore.record('schema_version').put(db, {'version': 1});
      await _metadataStore.record('created_at').put(db, {'timestamp': DateTime.now().toIso8601String()});
    }
  }

  Future<void> saveSession(SessionRecording session) async {
    final db = await database;

    await db.transaction((txn) async {
      // Save session metadata
      final sessionData = {
        'id': session.id,
        'sessionId': session.sessionId,
        'startTime': session.startTime.toIso8601String(),
        'endTime': session.endTime?.toIso8601String(),
        'userId': session.userId,
        'deviceInfo': session.deviceInfo,
        'metadata': session.metadata,
        'status': session.status.name,
        'sizeInBytes': session.sizeInBytes,
        'eventCount': session.events.length,
      };

      final sessionKey = session.startTime.millisecondsSinceEpoch;
      await _sessionsStore.record(sessionKey).put(txn, sessionData);

      // Save events in batches to optimize storage
      final compressedEvents = await _compressEvents(session.events);
      await _eventsStore.record(sessionKey).put(txn, {
        'sessionId': session.id,
        'compressed': true,
        'data': compressedEvents,
      });
    });
  }

  Future<Uint8List> _compressEvents(List<SessionEvent> events) async {
    final eventsJson = events.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(eventsJson);
    final bytes = utf8.encode(jsonString);
    
    // Use gzip compression to reduce storage size
    final compressed = GZipEncoder().encode(bytes);
    return Uint8List.fromList(compressed!);
  }

  Future<List<SessionEvent>> _decompressEvents(Uint8List compressed) async {
    final decompressed = GZipDecoder().decodeBytes(compressed);
    final jsonString = utf8.decode(decompressed);
    final eventsJson = jsonDecode(jsonString) as List;
    
    return eventsJson.map((json) => _parseSessionEvent(json as Map<String, dynamic>)).toList();
  }

  SessionEvent _parseSessionEvent(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final timestamp = DateTime.parse(json['timestamp'] as String);

    switch (type) {
      case 'log':
        // Parse LogEvent
        final logData = json['logEntry'] as Map<String, dynamic>;
        final logEntry = LogEntry(
          id: logData['id'] as String,
          timestamp: DateTime.parse(logData['timestamp'] as String),
          message: logData['message'] as String,
          level: LogLevel.values.firstWhere((l) => l.name == logData['level']),
          category: logData['category'] as String?,
          tag: logData['tag'] as String?,
          metadata: logData['metadata'] as Map<String, dynamic>?,
          error: logData['error'] != null ? Exception(logData['error']) : null,
          stackTrace: logData['stackTrace'] as String?,
          userId: logData['userId'] as String?,
          sessionId: logData['sessionId'] as String?,
        );
        return LogEvent(
          timestamp: timestamp,
          logEntry: logEntry,
        );
      case 'user_action':
        return UserActionEvent(
          timestamp: timestamp,
          action: json['action'] as String,
          screen: json['screen'] as String?,
          properties: json['properties'] as Map<String, dynamic>?,
        );
      case 'network':
        return NetworkEvent(
          timestamp: timestamp,
          method: json['method'] as String,
          url: json['url'] as String,
          statusCode: json['statusCode'] as int?,
          duration: json['duration'] != null 
              ? Duration(milliseconds: json['duration'] as int)
              : null,
          headers: (json['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
          metadata: json['metadata'] as Map<String, dynamic>?,
        );
      case 'navigation':
        return ScreenNavigationEvent(
          timestamp: timestamp,
          fromScreen: json['fromScreen'] as String,
          toScreen: json['toScreen'] as String,
          parameters: json['parameters'] as Map<String, dynamic>?,
        );
      case 'app_state':
        return AppStateEvent(
          timestamp: timestamp,
          state: json['state'] as String,
          details: json['details'] as Map<String, dynamic>?,
        );
      default:
        throw UnimplementedError('Unknown event type: $type');
    }
  }

  Future<List<SessionRecording>> querySessions({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    final db = await database;

    final filters = <Filter>[];

    if (userId != null) {
      filters.add(Filter.equals('userId', userId));
    }

    if (startDate != null) {
      filters.add(Filter.greaterThanOrEquals('startTime', startDate.toIso8601String()));
    }

    if (endDate != null) {
      filters.add(Filter.lessThanOrEquals('startTime', endDate.toIso8601String()));
    }

    Filter? combinedFilter;
    if (filters.isNotEmpty) {
      combinedFilter = filters.length == 1 ? filters.first : Filter.and(filters);
    }

    final finder = Finder(
      filter: combinedFilter,
      sortOrders: [SortOrder(Field.key, false)], // Most recent first
      limit: limit,
    );

    final records = await _sessionsStore.find(db, finder: finder);

    final sessions = <SessionRecording>[];
    for (final record in records) {
      final data = record.value;
      final sessionKey = record.key;

      // Load events for this session
      final eventsRecord = await _eventsStore.record(sessionKey).get(db);
      List<SessionEvent> events = [];
      
      if (eventsRecord != null) {
        final compressedData = eventsRecord['data'];
        final compressed = compressedData is List<int> 
            ? compressedData 
            : List<int>.from(compressedData as List);
        events = await _decompressEvents(Uint8List.fromList(compressed));
      }

      sessions.add(SessionRecording(
        id: data['id'] as String,
        sessionId: data['sessionId'] as String,
        startTime: DateTime.parse(data['startTime'] as String),
        endTime: data['endTime'] != null ? DateTime.parse(data['endTime'] as String) : null,
        userId: data['userId'] as String,
        deviceInfo: data['deviceInfo'] as String?,
        metadata: data['metadata'] as Map<String, dynamic>,
        events: events,
        status: SessionStatus.values.firstWhere((s) => s.name == data['status']),
        sizeInBytes: data['sizeInBytes'] as int,
      ));
    }

    return sessions;
  }

  Future<SessionRecording?> getSession(String id) async {
    final db = await database;

    final finder = Finder(filter: Filter.equals('id', id));
    final record = await _sessionsStore.findFirst(db, finder: finder);

    if (record == null) return null;

    final data = record.value;
    final sessionKey = record.key;

    // Load events
    final eventsRecord = await _eventsStore.record(sessionKey).get(db);
    List<SessionEvent> events = [];
    
    if (eventsRecord != null) {
      final compressedData = eventsRecord['data'];
      final compressed = compressedData is List<int> 
          ? compressedData 
          : List<int>.from(compressedData as List);
      events = await _decompressEvents(Uint8List.fromList(compressed));
    }

    return SessionRecording(
      id: data['id'] as String,
      sessionId: data['sessionId'] as String,
      startTime: DateTime.parse(data['startTime'] as String),
      endTime: data['endTime'] != null ? DateTime.parse(data['endTime'] as String) : null,
      userId: data['userId'] as String,
      deviceInfo: data['deviceInfo'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>,
      events: events,
      status: SessionStatus.values.firstWhere((s) => s.name == data['status']),
      sizeInBytes: data['sizeInBytes'] as int,
    );
  }

  Future<void> deleteSession(String id) async {
    final db = await database;

    final finder = Finder(filter: Filter.equals('id', id));
    final record = await _sessionsStore.findFirst(db, finder: finder);

    if (record != null) {
      await db.transaction((txn) async {
        await _sessionsStore.record(record.key).delete(txn);
        await _eventsStore.record(record.key).delete(txn);
      });
    }
  }

  Future<void> deleteOldSessions(Duration age) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(age);

    final finder = Finder(
      filter: Filter.lessThan('startTime', cutoffDate.toIso8601String()),
    );

    final records = await _sessionsStore.find(db, finder: finder);

    await db.transaction((txn) async {
      for (final record in records) {
        await _sessionsStore.record(record.key).delete(txn);
        await _eventsStore.record(record.key).delete(txn);
      }
    });
  }

  Future<int> getTotalStorageSize() async {
    final db = await database;

    int totalSize = 0;
    
    // Sum up all session sizes
    final sessions = await _sessionsStore.find(db);
    for (final session in sessions) {
      totalSize += session.value['sizeInBytes'] as int;
    }

    return totalSize;
  }

  Future<Map<String, dynamic>> exportSession(String id) async {
    final session = await getSession(id);
    if (session == null) throw Exception('Session not found');

    return {
      'exportDate': DateTime.now().toIso8601String(),
      'version': 1,
      'session': {
        'id': session.id,
        'sessionId': session.sessionId,
        'startTime': session.startTime.toIso8601String(),
        'endTime': session.endTime?.toIso8601String(),
        'userId': session.userId,
        'deviceInfo': session.deviceInfo,
        'metadata': session.metadata,
        'status': session.status.name,
        'events': session.events.map((e) => e.toJson()).toList(),
      },
    };
  }

  Future<SessionRecording> importSession(Map<String, dynamic> data) async {
    final sessionData = data['session'] as Map<String, dynamic>;
    final eventsJson = sessionData['events'] as List;

    final events = eventsJson.map((json) => _parseSessionEvent(json as Map<String, dynamic>)).toList();

    final session = SessionRecording(
      id: sessionData['id'] as String,
      sessionId: sessionData['sessionId'] as String,
      startTime: DateTime.parse(sessionData['startTime'] as String),
      endTime: sessionData['endTime'] != null 
          ? DateTime.parse(sessionData['endTime'] as String) 
          : null,
      userId: sessionData['userId'] as String,
      deviceInfo: sessionData['deviceInfo'] as String?,
      metadata: sessionData['metadata'] as Map<String, dynamic>,
      events: events,
      status: SessionStatus.values.firstWhere((s) => s.name == sessionData['status']),
      sizeInBytes: utf8.encode(jsonEncode(eventsJson)).length,
    );

    await saveSession(session);
    return session;
  }
}