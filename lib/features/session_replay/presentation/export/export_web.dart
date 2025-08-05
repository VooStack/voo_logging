import 'dart:html' as html;
import 'dart:typed_data';

Future<void> exportSessionData(Uint8List bytes, String fileName) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  
  html.Url.revokeObjectUrl(url);
}