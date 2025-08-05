import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Helper class to handle session export across platforms
class SessionExportHelper {
  /// Export session data as JSON
  static Future<void> exportSession({
    required Map<String, dynamic> exportData,
    required String sessionId,
  }) async {
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    final bytes = utf8.encode(jsonString);
    final fileName = 'session_${sessionId}_${DateTime.now().millisecondsSinceEpoch}.json';

    if (kIsWeb) {
      await _exportForWeb(bytes, fileName);
    } else {
      await _exportForMobile(bytes, fileName);
    }
  }

  static Future<void> _exportForWeb(List<int> bytes, String fileName) async {
    // Dynamic import to avoid issues on non-web platforms
    if (kIsWeb) {
      final html = await _getHtmlLibrary();
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      
      html.Url.revokeObjectUrl(url);
    }
  }

  static Future<void> _exportForMobile(List<int> bytes, String fileName) async {
    // For mobile platforms, we would use file_picker or share_plus
    // For now, we'll just throw an unsupported error
    throw UnsupportedError('Export is currently only supported on web platform');
  }

  static Future<dynamic> _getHtmlLibrary() async {
    if (kIsWeb) {
      // ignore: avoid_dynamic_calls
      return (await import('dart:html')).loadLibrary();
    }
    throw UnsupportedError('HTML library is only available on web');
  }
}

// Stub for conditional imports
Future<dynamic> import(String library) async {
  throw UnsupportedError('Dynamic imports are not supported');
}