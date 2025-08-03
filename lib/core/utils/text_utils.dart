/// 텍스트 유틸리티 클래스
/// 
/// 일기와 메모에 입력된 텍스트를 정제하고 유효성을 검사하는 유틸리티 클래스입니다.
/// 유효하지 않은 유니코드 문자를 제거하여 데이터 무결성을 보장합니다.
class TextUtils {
  /// 문자열이 유효한 UTF-8인지 확인하고 정리
  /// 
  /// 유효하지 않은 유니코드 문자를 필터링하여 안전한 문자열을 반환합니다.
  /// 한글, 영어, 숫자, 기본 기호, 이모지 등을 허용합니다.
  /// 
  /// @param text : 정리할 문자열
  /// @return String : 유효한 문자만 포함된 문자열
  static String sanitizeText(String text) {
    try {
      // 유효하지 않은 문자 제거
      final buffer = StringBuffer();
      for (int i = 0; i < text.length; i++) {
        final char = text[i];
        final codeUnit = char.codeUnitAt(0);
        
        // 유효한 유니코드 범위인지 확인
        if (_isValidUnicode(codeUnit)) {
          buffer.write(char);
        }
      }
      
      return buffer.toString();
    } catch (e) {
      // 에러 발생 시 원본 텍스트 반환
      return text;
    }
  }
  
  /// 유효한 유니코드 문자인지 확인
  /// 
  /// 허용되는 유니코드 범위:
  /// - 기본 라틴 문자 (ASCII)
  /// - 한글 및 한글 자모
  /// - CJK 한자
  /// - 이모지 및 기호
  /// - 개행, 탭 등 제어 문자
  static bool _isValidUnicode(int codeUnit) {
    // 기본 라틴 문자 (0x0020-0x007E)
    if (codeUnit >= 0x0020 && codeUnit <= 0x007E) return true;
    
    // 한글 (0xAC00-0xD7AF)
    if (codeUnit >= 0xAC00 && codeUnit <= 0xD7AF) return true;
    
    // 한글 자모 (0x1100-0x11FF)
    if (codeUnit >= 0x1100 && codeUnit <= 0x11FF) return true;
    
    // 한글 호환 자모 (0x3130-0x318F)
    if (codeUnit >= 0x3130 && codeUnit <= 0x318F) return true;
    
    // CJK 통합 한자 (0x4E00-0x9FFF)
    if (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) return true;
    
    // 이모지 및 기타 유니코드 기호
    if (codeUnit >= 0x1F300 && codeUnit <= 0x1F9FF) return true;
    
    // 기타 일반적인 유니코드 범위
    if (codeUnit >= 0x0080 && codeUnit <= 0x00FF) return true; // Latin-1 Supplement
    if (codeUnit >= 0x2000 && codeUnit <= 0x206F) return true; // General Punctuation
    
    // 개행 문자, 탭 등
    if (codeUnit == 0x0009 || codeUnit == 0x000A || codeUnit == 0x000D) return true;
    
    return false;
  }
  
  /// 문자열에 유효하지 않은 문자가 있는지 확인
  /// 
  /// 입력된 문자열에 허용되지 않는 문자가 포함되어 있는지 검사합니다.
  /// 저장 전 유효성 검사에 사용할 수 있습니다.
  /// 
  /// @param text : 검사할 문자열  
  /// @return bool : 유효하지 않은 문자가 있으면 true
  static bool hasInvalidCharacters(String text) {
    for (int i = 0; i < text.length; i++) {
      if (!_isValidUnicode(text.codeUnitAt(i))) {
        return true;
      }
    }
    return false;
  }
}
