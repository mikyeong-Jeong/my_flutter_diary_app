/// 본문 일부 굵게(Bold) 처리용 유틸리티
///
/// 굵게 처리한 구간은 본문 글자와 별도로 [start, end) 범위 목록(boldRanges)으로 저장합니다.
/// 본문 글자 자체는 바뀌지 않으므로 검색·체크박스·백업과 충돌하지 않습니다.
class BoldUtils {
  BoldUtils._();

  /// 범위 정렬 및 겹치거나 맞닿은 범위 병합, 빈 범위 제거
  static List<List<int>> normalize(List<List<int>> ranges) {
    final sorted = ranges.where((r) => r.length == 2 && r[0] < r[1]).map((r) => [r[0], r[1]]).toList()
      ..sort((a, b) => a[0].compareTo(b[0]));
    final merged = <List<int>>[];
    for (final r in sorted) {
      if (merged.isNotEmpty && r[0] <= merged.last[1]) {
        if (r[1] > merged.last[1]) merged.last[1] = r[1];
      } else {
        merged.add(r);
      }
    }
    return merged;
  }

  /// [index] 위치의 글자가 굵게 처리되어 있는지
  static bool isBoldAt(List<List<int>> ranges, int index) =>
      ranges.any((r) => index >= r[0] && index < r[1]);

  /// [start, end) 구간 전체가 굵게 처리되어 있는지
  static bool isFullyBold(List<List<int>> ranges, int start, int end) {
    if (start >= end) return false;
    for (int i = start; i < end; i++) {
      if (!isBoldAt(ranges, i)) return false;
    }
    return true;
  }

  /// 선택 구간 굵게 토글: 전체가 이미 굵으면 해제, 아니면 전체를 굵게
  static List<List<int>> toggle(List<List<int>> ranges, int start, int end) {
    if (start >= end) return normalize(ranges);
    if (isFullyBold(ranges, start, end)) {
      // 선택 구간만 잘라내기
      final result = <List<int>>[];
      for (final r in ranges) {
        if (r[1] <= start || r[0] >= end) {
          result.add([r[0], r[1]]);
        } else {
          if (r[0] < start) result.add([r[0], start]);
          if (r[1] > end) result.add([end, r[1]]);
        }
      }
      return normalize(result);
    }
    return normalize([...ranges, [start, end]]);
  }

  /// 본문이 [oldText]에서 [newText]로 바뀌었을 때 굵게 범위를 이동/축소
  ///
  /// 바뀐 구간 앞의 범위는 그대로, 뒤의 범위는 길이 차이만큼 이동합니다.
  /// 굵은 글자 사이에 입력한 글자는 굵게 이어지고, 지운 부분은 범위에서 빠집니다.
  static List<List<int>> adjustForEdit(String oldText, String newText, List<List<int>> ranges) {
    if (oldText == newText || ranges.isEmpty) return ranges;

    final minLength = oldText.length < newText.length ? oldText.length : newText.length;
    int prefix = 0;
    while (prefix < minLength && oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
      prefix++;
    }
    int suffix = 0;
    while (suffix < minLength - prefix &&
        oldText.codeUnitAt(oldText.length - 1 - suffix) == newText.codeUnitAt(newText.length - 1 - suffix)) {
      suffix++;
    }
    final removed = oldText.length - prefix - suffix;
    final inserted = newText.length - prefix - suffix;
    final changeEnd = prefix + removed;
    final delta = inserted - removed;

    final result = <List<int>>[];
    for (final r in ranges) {
      final a = r[0], b = r[1];
      if (b <= prefix) {
        result.add([a, b]);
      } else if (a >= changeEnd) {
        result.add([a + delta, b + delta]);
      } else if (a < prefix && b > changeEnd) {
        // 굵은 구간 안쪽을 편집: 입력한 글자도 굵게 유지
        result.add([a, b + delta]);
      } else {
        final newA = a < prefix ? a : prefix + inserted;
        final newB = b > changeEnd ? b + delta : prefix;
        if (newA < newB) result.add([newA, newB]);
      }
    }
    return normalize(result);
  }

  /// 앞뒤 공백을 잘라낸 텍스트와, 그 텍스트 기준으로 옮긴 굵게 범위
  static TrimmedBoldText trim(String text, List<List<int>> ranges) {
    final leading = text.length - text.trimLeft().length;
    final trimmed = text.trim();
    final shifted = <List<int>>[];
    for (final r in ranges) {
      final a = (r[0] - leading).clamp(0, trimmed.length);
      final b = (r[1] - leading).clamp(0, trimmed.length);
      if (a < b) shifted.add([a, b]);
    }
    return TrimmedBoldText(trimmed, normalize(shifted));
  }
}

/// [BoldUtils.trim] 결과
class TrimmedBoldText {
  const TrimmedBoldText(this.text, this.boldRanges);

  final String text;
  final List<List<int>> boldRanges;
}
