import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../utils/checklist_utils.dart';

/// 체크박스를 탭으로 토글할 수 있는 읽기 전용 텍스트
///
/// - □/■ 문자를 탭하면 체크 상태가 바뀌고 [onChanged]로 바뀐 전체 텍스트를 전달합니다.
/// - 체크된 항목(■ 뒤 텍스트)은 취소선과 흐린 색으로 표시합니다.
/// - 기존처럼 길게 눌러 텍스트를 선택/복사할 수 있습니다.
/// - [onChanged]가 null이면 체크박스를 탭해도 변경되지 않습니다.
class ChecklistText extends StatefulWidget {
  const ChecklistText(
    this.text, {
    super.key,
    this.style,
    this.onChanged,
  });

  final String text;
  final TextStyle? style;
  final ValueChanged<String>? onChanged;

  @override
  State<ChecklistText> createState() => _ChecklistTextState();
}

class _ChecklistTextState extends State<ChecklistText> {
  /// 체크박스 문자별 탭 인식기 (빌드마다 다시 만들므로 이전 것은 해제)
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final baseStyle = DefaultTextStyle.of(context).style.merge(widget.style);
    final text = widget.text;
    final checkedRanges = ChecklistUtils.checkedRanges(text);
    final checkedStyle = baseStyle.copyWith(
      decoration: TextDecoration.lineThrough,
      color: (baseStyle.color ?? Colors.black).withOpacity(0.5),
    );
    final checkboxStyle = baseStyle.copyWith(
      // 탭하기 쉽도록 체크박스 문자는 조금 크게 표시
      fontSize: (baseStyle.fontSize ?? 14) * 1.25,
      color: Theme.of(context).primaryColor,
    );

    bool isChecked(int index) =>
        checkedRanges.any((range) => index >= range[0] && index < range[1]);

    final spans = <TextSpan>[];
    final buffer = StringBuffer();
    bool? bufferChecked;

    void flush() {
      if (buffer.isEmpty) return;
      spans.add(TextSpan(
        text: buffer.toString(),
        style: bufferChecked == true ? checkedStyle : baseStyle,
      ));
      buffer.clear();
    }

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (ChecklistUtils.isCheckbox(char)) {
        flush();
        TapGestureRecognizer? recognizer;
        if (widget.onChanged != null) {
          recognizer = TapGestureRecognizer()
            ..onTap = () => widget.onChanged!(ChecklistUtils.toggleAt(text, i));
          _recognizers.add(recognizer);
        }
        spans.add(TextSpan(text: char, style: checkboxStyle, recognizer: recognizer));
        continue;
      }
      final checked = isChecked(i);
      if (bufferChecked != checked) {
        flush();
        bufferChecked = checked;
      }
      buffer.write(char);
    }
    flush();

    // SelectionArea: 길게 눌러 선택/복사 유지, Text.rich: 체크박스 탭 인식기 동작
    return SelectionArea(
      child: Text.rich(TextSpan(style: baseStyle, children: spans)),
    );
  }
}
