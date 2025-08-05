import 'dart:convert';
import 'dart:typed_data';

// Conditional imports
import 'export_stub.dart'
    if (dart.library.html) 'export_web.dart'
    if (dart.library.io) 'export_mobile.dart';

/// Cross-platform session exporter
class SessionExporter {
  static Future<void> exportSession({
    required Map<String, dynamic> exportData,
    required String sessionId,
  }) async {
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    final fileName = 'session_${sessionId}_${DateTime.now().millisecondsSinceEpoch}.json';

    await exportSessionData(bytes, fileName);
  }
}