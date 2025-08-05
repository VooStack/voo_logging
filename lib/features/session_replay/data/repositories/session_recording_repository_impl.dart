import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';
import 'package:voo_logging/features/logging/domain/entities/log_entry.dart';
import 'package:voo_logging/features/logging/domain/entities/voo_logger.dart';
import 'package:voo_logging/features/session_replay/data/datasources/session_recording_storage.dart';
import 'package:voo_logging/features/session_replay/domain/entities/session_recording.dart';
import 'package:voo_logging/features/session_replay/domain/repositories/session_recording_repository.dart';

class SessionRecordingRepositoryImpl implements SessionRecordingRepository {
  final SessionRecordingStorage _storage;
  final Stream<LogEntry>? _logStream;
  final _uuid = const Uuid();
  
  SessionRecording? _currentRecording;
  final List<SessionEvent> _pendingEvents = [];
  Timer? _saveTimer;
  StreamSubscription<LogEntry>? _logSubscription;
  
  final _recordingController = StreamController<SessionRecording>.broadcast();

  SessionRecordingRepositoryImpl({
    SessionRecordingStorage? storage,
    Stream<LogEntry>? logStream,
  }) : _storage = storage ?? SessionRecordingStorage(),
       _logStream = logStream;

  @override
  Future<void> startRecording({
    required String sessionId,
    required String userId,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentRecording != null && _currentRecording!.status == SessionStatus.recording) {
      await stopRecording();
    }

    _currentRecording = SessionRecording(
      id: _uuid.v4(),
      sessionId: sessionId,
      startTime: DateTime.now(),
      userId: userId,
      deviceInfo: await _getDeviceInfo(),
      metadata: metadata ?? {},
      events: [],
      status: SessionStatus.recording,
      sizeInBytes: 0,
    );

    // Subscribe to log stream if provided
    final streamToUse = _logStream ?? VooLogger.instance.stream;
    _logSubscription = streamToUse.listen((logEntry) {
      if (_currentRecording?.status == SessionStatus.recording) {
        addEvent(LogEvent(
          timestamp: logEntry.timestamp,
          logEntry: logEntry,
        ));
      }
    });

    // Start periodic save timer (every 30 seconds)
    _saveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _savePendingEvents();
    });

    _recordingController.add(_currentRecording!);
  }

  @override
  Future<void> stopRecording() async {
    if (_currentRecording == null) return;

    _currentRecording = _currentRecording!.copyWith(
      endTime: DateTime.now(),
      status: SessionStatus.completed,
    );

    await _savePendingEvents();
    await _logSubscription?.cancel();
    _saveTimer?.cancel();

    _recordingController.add(_currentRecording!);
    _currentRecording = null;
    _pendingEvents.clear();
  }

  @override
  Future<void> pauseRecording() async {
    if (_currentRecording?.status != SessionStatus.recording) return;

    _currentRecording = _currentRecording!.copyWith(
      status: SessionStatus.paused,
    );

    await _savePendingEvents();
    _recordingController.add(_currentRecording!);
  }

  @override
  Future<void> resumeRecording() async {
    if (_currentRecording?.status != SessionStatus.paused) return;

    _currentRecording = _currentRecording!.copyWith(
      status: SessionStatus.recording,
    );

    _recordingController.add(_currentRecording!);
  }

  @override
  Future<void> addEvent(SessionEvent event) async {
    try {
      if (_currentRecording == null || _currentRecording!.status != SessionStatus.recording) {
        return;
      }

      _pendingEvents.add(event);

      // Save if we have accumulated many events (to prevent memory issues)
      if (_pendingEvents.length >= 100) {
        await _savePendingEvents();
      }
    } catch (e) {
      // Handle error gracefully - don't let session recording failure break the app
      print('Error adding session event: $e');
    }
  }

  Future<void> _savePendingEvents() async {
    if (_currentRecording == null) return;

    try {
      // Add pending events to current recording
      final allEvents = [..._currentRecording!.events, ..._pendingEvents];
      
      // Calculate size
      final eventsJson = allEvents.map((e) => e.toJson()).toList();
      final sizeInBytes = utf8.encode(jsonEncode(eventsJson)).length;

      _currentRecording = _currentRecording!.copyWith(
        events: allEvents,
        sizeInBytes: sizeInBytes,
      );

      await _storage.saveSession(_currentRecording!);
      _pendingEvents.clear();
    } catch (e) {
      print('Error saving session events: $e');
      // Mark the recording as having an error
      _currentRecording = _currentRecording!.copyWith(
        status: SessionStatus.error,
      );
      _recordingController.add(_currentRecording!);
    }
  }

  @override
  Future<SessionRecording?> getCurrentRecording() async {
    return _currentRecording;
  }

  @override
  Future<List<SessionRecording>> getRecordings({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    return await _storage.querySessions(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  @override
  Future<SessionRecording?> getRecording(String id) async {
    return await _storage.getSession(id);
  }

  @override
  Future<void> deleteRecording(String id) async {
    await _storage.deleteSession(id);
  }

  @override
  Future<void> deleteOldRecordings(Duration age) async {
    await _storage.deleteOldSessions(age);
  }

  @override
  Future<int> getTotalStorageSize() async {
    return await _storage.getTotalStorageSize();
  }

  @override
  Future<void> exportRecording(String id, String filePath) async {
    final data = await _storage.exportSession(id);
    final file = File(filePath);
    await file.writeAsString(jsonEncode(data));
  }

  @override
  Future<SessionRecording> importRecording(String filePath) async {
    final file = File(filePath);
    final jsonString = await file.readAsString();
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    return await _storage.importSession(data);
  }

  @override
  Stream<SessionRecording> get recordingStream => _recordingController.stream;

  @override
  bool get isRecording => _currentRecording?.status == SessionStatus.recording;

  Future<String> _getDeviceInfo() async {
    // This is a simplified version. In a real app, you'd use device_info_plus
    return Platform.operatingSystem;
  }

  void dispose() {
    _saveTimer?.cancel();
    _logSubscription?.cancel();
    _recordingController.close();
  }
}