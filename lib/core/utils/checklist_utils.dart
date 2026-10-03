/// 체크박스(□/■) 텍스트 처리 유틸리티
///
/// 본문에 '□ 할 일' / '■ 완료한 일' 형태로 저장된 체크박스를
/// 읽기 화면과 편집 화면에서 같은 규칙으로 해석하기 위한 함수들입니다.
class ChecklistUtils {
  ChecklistUtils._();

  /// 체크되지 않은 체크박스 문자
  static const String unchecked = '□';

  /// 체크된 체크박스 문자
  static const String checked = '■';

  /// 해당 문자가 체크박스인지 확인
  static bool isCheckbox(String char) => char == unchecked || char == checked;

  /// [index] 위치의 체크박스를 토글한 텍스트를 반환
  ///
  /// [index]가 체크박스 문자가 아니면 원본 텍스트를 그대로 반환합니다.
  static String toggleAt(String text, int index) {
    if (index < 0 || index >= text.length) return text;
    final char = text[index];
    if (!isCheckbox(char)) return text;
    final newChar = char == unchecked ? checked : unchecked;
    return text.replaceRange(index, index + 1, newChar);
  }

  /// 취소선을 그어야 할 구간 목록 ([start, end) 쌍)
  ///
  /// 체크된 체크박스(■) 바로 뒤부터 사용자가 입력한 줄바꿈(\n) 전까지를
  /// 완료된 항목으로 보고 취소선 구간으로 반환합니다.
  /// 화면 폭 때문에 자동 줄바꿈된 부분도 같은 줄로 보고 끝까지 취소선을 긋습니다.
  static List<List<int>> checkedRanges(String text) {
    final ranges = <List<int>>[];
    for (int i = 0; i < text.length; i++) {
      if (text[i] != checked) continue;
      final start = i + 1;
      int end = text.indexOf('\n', start);
      if (end == -1) end = text.length;
      if (end > start) ranges.add([start, end]);
      // 같은 줄의 나머지는 이미 취소선 구간에 포함됨
      i = end;
    }
    return ranges;
  }
}
