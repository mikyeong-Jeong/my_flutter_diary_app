import 'package:flutter/material.dart';

import '../../../../core/utils/bold_utils.dart';
import '../../../../core/utils/checklist_utils.dart';
import '../../../../core/widgets/checklist_text.dart';

/// 본문 입력용 컨트롤러
///
/// - 체크박스(☐/☑)를 아이콘으로 그리고, 체크된 항목(☑ 뒤 텍스트)에 취소선을 그립니다.
/// - 일부 글자 굵게(Bold): [boldRanges] 구간을 굵게 표시하고, 글자를 입력/삭제하면 구간이 따라 움직입니다.
/// - 체크박스 문자 1개를 아이콘 1개로 그리므로 커서/선택 위치는 그대로 유지됩니다.
/// - 한글 입력 중 조합 구간(밑줄) 표시도 유지합니다.
class ChecklistTextEditingController extends TextEditingController {
  ChecklistTextEditingController({super.text, List<List<int>>? boldRanges})
      : _boldRanges = BoldUtils.normalize(boldRanges ?? const []);

  List<List<int>> _boldRanges;

  /// 굵게 처리된 구간 목록 ([start, end) 쌍)
  List<List<int>> get boldRanges => _boldRanges;

  set boldRanges(List<List<int>> ranges) {
    _boldRanges = BoldUtils.normalize(ranges);
    notifyListeners();
  }

  /// 본문이 바뀌면 굵게 구간을 바뀐 위치에 맞춰 이동
  @override
  set value(TextEditingValue newValue) {
    if (newValue.text != text && _boldRanges.isNotEmpty) {
      _boldRanges = BoldUtils.adjustForEdit(text, newValue.text, _boldRanges);
    }
    super.value = newValue;
  }

  /// 현재 선택한 구간이 모두 굵게 처리되어 있는지
  bool get isSelectionBold {
    final s = selection;
    return s.isValid && !s.isCollapsed && BoldUtils.isFullyBold(_boldRanges, s.start, s.end);
  }

  /// 현재 선택한 구간 굵게 토글 (선택이 없으면 아무 동작 안 함)
  ///
  /// 선택 구간이 모두 굵으면 해제, 아니면 전체를 굵게 처리합니다.
  bool toggleBoldOnSelection() {
    final s = selection;
    if (!s.isValid || s.isCollapsed) return false;
    boldRanges = BoldUtils.toggle(_boldRanges, s.start, s.end);
    return true;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;
    final hasCheckbox = text.contains(ChecklistUtils.unchecked) || text.contains(ChecklistUtils.checked);

    // 체크박스·굵게 처리가 없으면 기본 동작 사용
    if (!hasCheckbox && _boldRanges.isEmpty) {
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
    bool bufferBold = false;

    void flush() {
      if (buffer.isEmpty) return;
      final decorations = <TextDecoration>[
        if (bufferChecked) TextDecoration.lineThrough,
        if (bufferComposing) TextDecoration.underline,
      ];
      final hasStyle = decorations.isNotEmpty || bufferBold;
      spans.add(TextSpan(
        text: buffer.toString(),
        style: !hasStyle
            ? null
            : TextStyle(
                decoration: decorations.isEmpty ? null : TextDecoration.combine(decorations),
                color: bufferChecked ? checkedColor : null,
                fontWeight: bufferBold ? FontWeight.bold : null,
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
      final bold = BoldUtils.isBoldAt(_boldRanges, i);
      if (checked != bufferChecked || composingHere != bufferComposing || bold != bufferBold) {
        flush();
        bufferChecked = checked;
        bufferComposing = composingHere;
        bufferBold = bold;
      }
      buffer.write(char);
    }
    flush();

    return TextSpan(style: style, children: spans);
  }
}
