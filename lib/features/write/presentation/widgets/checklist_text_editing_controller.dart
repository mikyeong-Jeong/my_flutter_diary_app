import 'package:flutter/material.dart';

import '../../../../core/utils/checklist_utils.dart';
import '../../../../core/widgets/checklist_text.dart';

/// 체크박스(☐/☑)를 아이콘으로 그리고, 체크된 항목(☑ 뒤 텍스트)에 취소선을 그려주는 본문 입력용 컨트롤러
///
/// 읽기 화면(ChecklistText)과 같은 아이콘·취소선 규칙을 사용합니다.
/// 체크박스 문자 1개를 아이콘 1개로 그리므로 커서/선택 위치는 그대로 유지됩니다.
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
    final hasCheckbox = text.contains(ChecklistUtils.unchecked) || text.contains(ChecklistUtils.checked);

    // 체크박스가 없으면 기본 동작 사용
    if (!hasCheckbox) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }

    final checkedRanges = ChecklistUtils.checkedRanges(text);
    final composing = value.composing;
    final hasComposing = withComposing && value.isComposingRangeValid;
    final baseStyle = style ?? const TextStyle();
    final checkedColor = (baseStyle.color ?? Colors.black).withOpacity(0.5);

    bool isChecked(int index) => checkedRanges.any((r) => index >= r[0] && index < r[1]);
    bool isComposing(int index) => hasComposing && index >= composing.start && index < composing.end;

    final spans = <InlineSpan>[];
    final buffer = StringBuffer();
    bool bufferChecked = false;
    bool bufferComposing = false;

    void flush() {
      if (buffer.isEmpty) return;
      final decorations = <TextDecoration>[
        if (bufferChecked) TextDecoration.lineThrough,
        if (bufferComposing) TextDecoration.underline,
      ];
      spans.add(TextSpan(
        text: buffer.toString(),
        style: decorations.isEmpty
            ? null
            : TextStyle(
                decoration: TextDecoration.combine(decorations),
                color: bufferChecked ? checkedColor : null,
              ),
      ));
      buffer.clear();
    }

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (ChecklistUtils.isCheckbox(char)) {
        flush();
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: checklistIcon(checked: char == ChecklistUtils.checked, style: baseStyle),
        ));
        continue;
      }
      final checked = isChecked(i);
      final composingHere = isComposing(i);
      if (checked != bufferChecked || composingHere != bufferComposing) {
        flush();
        bufferChecked = checked;
        bufferComposing = composingHere;
      }
      buffer.write(char);
    }
    flush();

    return TextSpan(style: style, children: spans);
  }
}
