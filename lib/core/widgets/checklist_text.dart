import 'package:flutter/material.dart';

import '../utils/bold_utils.dart';
import '../utils/checklist_utils.dart';

/// 체크박스(☐/☑)를 아이콘으로 표시하는 텍스트
///
/// - 저장된 ☐/☑ 문자는 같은 디자인의 체크박스 아이콘으로 그립니다.
///   (☑ 문자는 기기에 따라 컬러 이모지로 표시되어 ☐와 모양이 달라지므로 아이콘 사용)
/// - [onChanged]가 있으면 아이콘을 탭해 체크/해제하고, 바뀐 전체 텍스트를 전달합니다.
/// - 체크된 항목(☑ 뒤 텍스트)은 취소선과 흐린 색으로 표시합니다.
/// - [boldRanges] 구간은 굵게 표시합니다.
/// - [selectable]이 true이면 길게 눌러 텍스트를 선택/복사할 수 있습니다.
class ChecklistText extends StatelessWidget {
  const ChecklistText(
    this.text, {
    super.key,
    this.style,
    this.onChanged,
    this.selectable = true,
    this.maxLines,
    this.overflow,
    this.boldRanges = const [],
  });

  final String text;
  final TextStyle? style;
  final ValueChanged<String>? onChanged;

  /// 길게 눌러 선택/복사 가능 여부 (목록 미리보기에서는 false)
  final bool selectable;
  final int? maxLines;
  final TextOverflow? overflow;

  /// 굵게(Bold) 처리할 구간 목록 ([start, end) 쌍)
  final List<List<int>> boldRanges;

  @override
  Widget build(BuildContext context) {
    final baseStyle = DefaultTextStyle.of(context).style.merge(style);
    final spans = buildChecklistSpans(
      text: text,
      baseStyle: baseStyle,
      boldRanges: boldRanges,
      onToggle: onChanged == null ? null : (index) => onChanged!(ChecklistUtils.toggleAt(text, index)),
    );
    final richText = Text.rich(
      TextSpan(style: baseStyle, children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
    // SelectionArea: 길게 눌러 선택/복사 유지
    return selectable ? SelectionArea(child: richText) : richText;
  }
}

/// 체크박스 아이콘 (☐: 빈 네모, ☑: 체크된 네모)
///
/// 읽기 화면과 편집 화면에서 같은 모양을 쓰기 위해 공통으로 사용합니다.
Widget checklistIcon({required bool checked, required TextStyle style}) {
  final size = (style.fontSize ?? 14) * 1.3;
  return Padding(
    padding: const EdgeInsets.only(right: 2),
    child: Icon(
      checked ? Icons.check_box : Icons.check_box_outline_blank,
      size: size,
      color: style.color,
    ),
  );
}

/// 텍스트를 체크박스 아이콘 + 취소선이 적용된 span 목록으로 변환
///
/// 체크박스 문자 1개는 아이콘(WidgetSpan) 1개로 바뀌므로 텍스트 위치(offset)가 그대로 유지됩니다.
/// [onToggle]이 있으면 아이콘을 탭할 때 해당 체크박스의 위치를 전달합니다.
List<InlineSpan> buildChecklistSpans({
  required String text,
  required TextStyle baseStyle,
  List<List<int>> boldRanges = const [],
  ValueChanged<int>? onToggle,
}) {
  final checkedRanges = ChecklistUtils.checkedRanges(text);
  final checkedStyle = baseStyle.copyWith(
    decoration: TextDecoration.lineThrough,
    color: (baseStyle.color ?? Colors.black).withOpacity(0.5),
  );

  bool isChecked(int index) =>
      checkedRanges.any((range) => index >= range[0] && index < range[1]);

  final spans = <InlineSpan>[];
  final buffer = StringBuffer();
  bool? bufferChecked;
  bool bufferBold = false;

  void flush() {
    if (buffer.isEmpty) return;
    final style = bufferChecked == true ? checkedStyle : baseStyle;
    spans.add(TextSpan(
      text: buffer.toString(),
      style: bufferBold ? style.copyWith(fontWeight: FontWeight.bold) : style,
    ));
    buffer.clear();
  }

  for (int i = 0; i < text.length; i++) {
    final char = text[i];
    if (ChecklistUtils.isCheckbox(char)) {
      flush();
      final icon = checklistIcon(checked: char == ChecklistUtils.checked, style: baseStyle);
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: onToggle == null
            ? icon
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onToggle(i),
                child: icon,
              ),
      ));
      continue;
    }
    final checked = isChecked(i);
    final bold = BoldUtils.isBoldAt(boldRanges, i);
    if (bufferChecked != checked || bufferBold != bold) {
      flush();
      bufferChecked = checked;
      bufferBold = bold;
    }
    buffer.write(char);
  }
  flush();
  return spans;
}
