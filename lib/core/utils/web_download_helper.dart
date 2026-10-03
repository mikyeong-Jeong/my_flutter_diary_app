import 'dart:html' as html;

import 'json_utils.dart';

/// 웹 플랫폼을 위한 다운로드 헬퍼
///
/// 브라우저에서 파일을 다운로드할 수 있도록 Blob과 anchor 태그를 사용합니다.
/// 주로 백업 파일을 내보내기 할 때 사용됩니다.
///
/// @param fileName : 다운로드할 파일명 (.json 확장자 포함)
/// @param content : 파일에 저장할 문자열 내용 (JSON 형식)
void downloadFile(String fileName, String content) {
  // content.codeUnits(UTF-16)를 그대로 바이트로 쓰면 한글이 깨지므로
  // 모바일 백업과 동일하게 UTF-8(BOM 포함) 바이트로 변환
  final bytes = JsonUtils.toUtf8Bytes(content, includeBom: true);
  final blob = html.Blob([bytes], 'application/json;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement()
    ..href = url
    ..download = fileName
    ..click();
  html.Url.revokeObjectUrl(url);
}
