import 'package:flutter/material.dart';

import '../models/diary_entry.dart';

/// 항목 종류별 대표 색상
///
/// 목록 카드 테두리 등에서 일기·할 일·메모·계산을 색으로 구분할 때 사용합니다.
/// (달력 탭 카드, 검색 결과 배지와 같은 색 체계)
class EntryColors {
  EntryColors._();

  /// 일기 (파랑)
  static const Color diary = Colors.blue;

  /// 할 일 (주황)
  static const Color todo = Colors.orange;

  /// 메모 (초록)
  static const Color memo = Colors.green;

  /// 계산 (보라)
  static const Color calculator = Colors.purple;

  /// 목록 카드 테두리 두께
  static const double borderWidth = 1.5;

  /// 일기 항목 종류에 맞는 색상
  static Color of(EntryType type) {
    switch (type) {
      case EntryType.dated:
        return diary;
      case EntryType.datedNote:
        return todo;
      case EntryType.general:
        return memo;
    }
  }

  /// 목록 카드용 테두리 (항목 색상)
  static RoundedRectangleBorder cardShape(Color color) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: color, width: borderWidth),
    );
  }
}
