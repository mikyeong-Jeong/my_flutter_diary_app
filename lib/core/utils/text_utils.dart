/// 텍스트 유틸리티 클래스
class TextUtils {
  /// 문자열이 유효한 UTF-8인지 확인하고 정리
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
      print('Error sanitizing text: $e');
      return text;
    }
  }
  
  /// 유효한 유니코드 문자인지 확인
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
  static bool hasInvalidCharacters(String text) {
    for (int i = 0; i < text.length; i++) {
      if (!_isValidUnicode(text.codeUnitAt(i))) {
        return true;
      }
    }
    return false;
  }
}
