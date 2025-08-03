import 'dart:typed_data';
import 'dart:html' as html;

/// 웹 플랫폼을 위한 다운로드 헬퍼
/// 
/// 브라우저에서 파일을 다운로드할 수 있도록 Blob과 anchor 태그를 사용합니다.
/// 주로 백업 파일을 내보내기 할 때 사용됩니다.
/// 
/// @param fileName : 다운로드할 파일명 (.json 확장자 포함)
/// @param content : 파일에 저장할 문자열 내용 (JSON 형식)
void downloadFile(String fileName, String content) {
  final bytes = Uint8List.fromList(content.codeUnits);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement()
    ..href = url
    ..download = fileName
    ..click();
  html.Url.revokeObjectUrl(url);
}
