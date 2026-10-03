import 'package:flutter/material.dart';

import '../../../../core/utils/checklist_utils.dart';

/// 체크된 항목(☑ 뒤 텍스트)에 취소선을 그려주는 본문 입력용 컨트롤러
///
/// 읽기 화면(ChecklistText)과 같은 규칙으로 취소선을 표시합니다.
/// 한글 입력 중 조합 구간(밑줄) 표시도 유지합니다.
class ChecklistTextEditingController extends TextEditingController {
  ChecklistTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;
    final checkedRanges = ChecklistUtils.checkedRanges(text);
    final composing = value.composing;
    final hasComposing = withComposing && value.isComposingRangeValid;

    // 체크된 항목이 없으면 기본 동작 사용
    if (checkedRanges.isEmpty) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }

    // 스타일이 바뀌는 지점(취소선 시작/끝, 조합 구간 시작/끝)으로 텍스트를 나눔
    final breakpoints = <int>{0, text.length};
    for (final range in checkedRanges) {
      breakpoints..add(range[0])..add(range[1]);
    }
    if (hasComposing) {
      breakpoints..add(composing.start)..add(composing.end);
    }
    final points = breakpoints.where((p) => p >= 0 && p <= text.length).toList()..sort();

    final checkedColor = (style?.color ?? Colors.black).withOpacity(0.5);
    final spans = <TextSpan>[];
    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      if (start == end) continue;

      final isChecked = checkedRanges.any((r) => start >= r[0] && end <= r[1]);
      final isComposing = hasComposing && start >= composing.start && end <= composing.end;

      final decorations = <TextDecoration>[
        if (isChecked) TextDecoration.lineThrough,
        if (isComposing) TextDecoration.underline,
      ];
      spans.add(TextSpan(
        text: text.substring(start, end),
        style: decorations.isEmpty
            ? null
            : TextStyle(
                decoration: TextDecoration.combine(decorations),
                color: isChecked ? checkedColor : null,
              ),
      ));
    }

    return TextSpan(style: style, children: spans);
  }
}
