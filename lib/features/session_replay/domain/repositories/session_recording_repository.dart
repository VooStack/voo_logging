import 'package:voo_logging/features/session_replay/domain/entities/session_recording.dart';

abstract class SessionRecordingRepository {
  Future<void> startRecording({
    required String sessionId,
    required String userId,
    Map<String, dynamic>? metadata,
  });

  Future<void> stopRecording();

  Future<void> pauseRecording();

  Future<void> resumeRecording();

  Future<void> addEvent(SessionEvent event);

  Future<SessionRecording?> getCurrentRecording();

  Future<List<SessionRecording>> getRecordings({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  });

  Future<SessionRecording?> getRecording(String id);

  Future<void> deleteRecording(String id);

  Future<void> deleteOldRecordings(Duration age);

  Future<int> getTotalStorageSize();

  Future<void> exportRecording(String id, String filePath);

  Future<SessionRecording> importRecording(String filePath);

  Stream<SessionRecording> get recordingStream;

  bool get isRecording;
}