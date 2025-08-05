import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> exportSessionData(Uint8List bytes, String fileName) async {
  // 1) Cast our Dart List<Uint8List> into a JSArray<BlobPart>
  final blobParts = ([bytes] as dynamic) as JSArray<web.BlobPart>;

  // 2) Create the Blob and object URL
  final blob = web.Blob(blobParts, web.BlobPropertyBag(type: 'application/octet-stream'));
  final url = web.URL.createObjectURL(blob);

  // 3) Make a hidden <a> tag, point it at our URL, set download filename
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';

  // 4) Append, click, cleanup
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
