import 'dart:convert';
import 'dart:typed_data';

class JsonUtils {
  // UTF-8 BOM
  static const List<int> _utf8Bom = [0xEF, 0xBB, 0xBF];

  /// JSON 문자열을 UTF-8 바이트 배열로 변환
  /// BOM을 포함하면 일부 앱에서 한글을 더 잘 인식할 수 있음
  static Uint8List toUtf8Bytes(String jsonString, {bool includeBom = false}) {
    final utf8Bytes = utf8.encode(jsonString);
    
    if (includeBom) {
      // BOM + UTF-8 bytes
      return Uint8List.fromList([..._utf8Bom, ...utf8Bytes]);
    }
    
    return Uint8List.fromList(utf8Bytes);
  }

  /// 바이트 배열에서 JSON 객체로 안전하게 디코딩
  /// BOM이 있으면 제거하고, 다양한 인코딩을 시도
  static dynamic decodeFromBytes(List<int> bytes) {
    // BOM 제거
    List<int> cleanBytes = bytes;
    if (bytes.length >= 3 && 
        bytes[0] == _utf8Bom[0] && 
        bytes[1] == _utf8Bom[1] && 
        bytes[2] == _utf8Bom[2]) {
      cleanBytes = bytes.sublist(3);
    }

    try {
      // UTF-8로 디코딩 시도
      final content = utf8.decode(cleanBytes);
      return jsonDecode(content);
    } catch (e) {
      // UTF-8 실패 시 다른 방법 시도
      try {
        // 잘못된 문자 무시하고 디코딩
        final content = utf8.decode(cleanBytes, allowMalformed: true);
        return jsonDecode(content);
      } catch (e2) {
        // Latin1으로 시도 (일부 Windows 환경)
        try {
          final content = latin1.decode(cleanBytes);
          return jsonDecode(content);
        } catch (e3) {
          throw FormatException('Failed to decode JSON: $e, $e2, $e3');
        }
      }
    }
  }

  /// 파일에서 읽은 문자열을 안전하게 정규화
  static String normalizeJsonString(String input) {
    // 잘못된 이스케이프 시퀀스 제거
    String normalized = input;
    
    // BOM 제거
    if (normalized.startsWith('\uFEFF')) {
      normalized = normalized.substring(1);
    }
    
    // 제어 문자 제거
    normalized = normalized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    
    // 공백 정리
    normalized = normalized.trim();
    
    return normalized;
  }

  /// JSON을 보기 좋게 포맷팅 (한글 유지)
  static String prettyPrint(dynamic jsonObject) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(jsonObject);
  }
}
