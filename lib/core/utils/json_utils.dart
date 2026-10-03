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
  /// 
  /// UTF-8(BOM 유무 무관)과 UTF-16(BOM 있는 경우, 예: Windows 메모장 '유니코드' 저장)을 지원합니다.
  /// 그 외 인코딩(EUC-KR 등)은 깨진 한글이 그대로 복원되지 않도록 오류를 발생시킵니다.
  static dynamic decodeFromBytes(List<int> bytes) {
    final String content;

    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      // UTF-16 LE (BOM: FF FE)
      content = _decodeUtf16(bytes.sublist(2), littleEndian: true);
    } else if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      // UTF-16 BE (BOM: FE FF)
      content = _decodeUtf16(bytes.sublist(2), littleEndian: false);
    } else {
      // UTF-8 BOM 제거
      List<int> cleanBytes = bytes;
      if (bytes.length >= 3 && 
          bytes[0] == _utf8Bom[0] && 
          bytes[1] == _utf8Bom[1] && 
          bytes[2] == _utf8Bom[2]) {
        cleanBytes = bytes.sublist(3);
      }

      try {
        content = utf8.decode(cleanBytes);
      } on FormatException {
        // allowMalformed/latin1로 억지로 읽으면 한글이 '�' 등으로 깨진 채 복원되므로 중단
        throw const FormatException(
          '백업 파일이 UTF-8 형식이 아니어서 한글이 깨질 수 있습니다. '
          '앱에서 내보낸 원본 백업 파일을 사용해주세요.',
        );
      }
    }

    return jsonDecode(content);
  }

  /// BOM을 제외한 UTF-16 바이트를 문자열로 변환
  static String _decodeUtf16(List<int> bytes, {required bool littleEndian}) {
    if (bytes.length.isOdd) {
      throw const FormatException('UTF-16 백업 파일이 손상되었습니다.');
    }
    final codeUnits = <int>[];
    for (int i = 0; i < bytes.length; i += 2) {
      codeUnits.add(littleEndian
          ? bytes[i] | (bytes[i + 1] << 8)
          : (bytes[i] << 8) | bytes[i + 1]);
    }
    return String.fromCharCodes(codeUnits);
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

  /// JSON 문자열을 안전하게 디코딩 시도
  /// 실패 시 null 반환
  static dynamic tryDecode(String jsonString) {
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      return null;
    }
  }
}
