import 'dart:typed_data';
import 'dart:html' as html;

void downloadFile(String fileName, String content) {
  final bytes = Uint8List.fromList(content.codeUnits);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement()
    ..href = url
    ..download = fileName
    ..click();
  html.Url.revokeObjectUrl(url);
}
