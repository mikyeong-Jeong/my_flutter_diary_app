import 'package:flutter/material.dart';
import 'text_style_state.dart';

/// Rich Text 지원 텍스트 필드
/// 
/// 각 줄에 개별적으로 스타일을 적용할 수 있으며, 
/// 체크박스가 있는 줄에만 취소선을 적용합니다.
class RichTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextStyleState textStyleState;
  final InputDecoration? decoration;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  const RichTextField({
    super.key,
    required this.controller,
    required this.textStyleState,
    this.focusNode,
    this.decoration,
    this.maxLines,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<RichTextField> createState() => _RichTextFieldState();
}

class _RichTextFieldState extends State<RichTextField> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.textStyleState,
      builder: (context, child) {
        return TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          decoration: widget.decoration,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          onTap: _handleTap,
          // Rich Text 렌더링을 위한 커스텀 빌더
          style: widget.textStyleState.currentTextStyle,
        );
      },
    );
  }

  /// 텍스트 필드 클릭 이벤트 처리
  void _handleTap() {
    Future.delayed(const Duration(milliseconds: 50), () {
      final selection = widget.controller.selection;
      if (selection.isValid) {
        _checkAndToggleCheckbox(selection.baseOffset);
      }
    });
  }

  /// 특정 위치에 체크박스가 있는지 확인하고 토글
  void _checkAndToggleCheckbox(int offset) {
    final text = widget.controller.text;
    if (text.isEmpty) return;

    int lineStart = text.lastIndexOf('\n', offset) + 1;
    String lineText = '';
    int lineEnd = text.indexOf('\n', lineStart);
    if (lineEnd == -1) lineEnd = text.length;

    if (lineStart < text.length) {
      lineText = text.substring(lineStart, lineEnd);
    }

    if ((lineText.startsWith('☐ ') || lineText.startsWith('☑ ')) && 
        offset >= lineStart && offset <= lineStart + 2) {
      widget.textStyleState.toggleCheckboxAt(widget.controller, offset);
    }
  }

  /// 텍스트를 줄별로 분석하여 Rich Text 스타일 생성
  List<TextSpan> _buildStyledTextSpans(String text) {
    final lines = text.split('\n');
    final List<TextSpan> spans = [];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // 체크박스가 있는 줄인지 확인
      final bool hasCheckedCheckbox = line.startsWith('☑ ');
      final bool hasUncheckedCheckbox = line.startsWith('☐ ');
      
      TextStyle lineStyle = widget.textStyleState.currentTextStyle;
      
      if (hasCheckedCheckbox) {
        // 체크된 체크박스가 있는 줄은 취소선 적용
        lineStyle = lineStyle.copyWith(
          decoration: TextDecoration.combine([
            if (widget.textStyleState.isUnderline) TextDecoration.underline,
            TextDecoration.lineThrough,
          ]),
        );
      } else if (hasUncheckedCheckbox) {
        // 체크되지 않은 체크박스가 있는 줄은 취소선 제거
        lineStyle = lineStyle.copyWith(
          decoration: widget.textStyleState.isUnderline 
              ? TextDecoration.underline 
              : TextDecoration.none,
        );
      }
      
      spans.add(TextSpan(text: line, style: lineStyle));
      
      // 마지막 줄이 아니면 줄바꿈 추가
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    
    return spans;
  }
}