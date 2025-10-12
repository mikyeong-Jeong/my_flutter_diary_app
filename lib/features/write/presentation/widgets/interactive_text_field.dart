import 'package:flutter/material.dart';
import 'text_style_state.dart';

/// 체크박스 클릭 감지가 가능한 인터랙티브 텍스트 필드
/// 
/// 일반 TextField의 모든 기능을 제공하면서, 추가로 텍스트 내 체크박스 클릭을 감지하여
/// 토글 기능을 제공합니다.
class InteractiveTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextStyleState textStyleState;
  final InputDecoration? decoration;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  const InteractiveTextField({
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
  State<InteractiveTextField> createState() => _InteractiveTextFieldState();
}

class _InteractiveTextFieldState extends State<InteractiveTextField> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 텍스트 필드 클릭 이벤트 처리
  void _handleTap() {
    // 약간의 지연 후 커서 위치 확인 (TextField가 커서를 업데이트한 후)
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

    // 해당 오프셋이 포함된 줄 찾기
    int lineStart = text.lastIndexOf('\n', offset) + 1;
    int lineEnd = text.indexOf('\n', lineStart);
    if (lineEnd == -1) lineEnd = text.length;

    if (lineStart >= text.length) return;

    String lineText = text.substring(lineStart, lineEnd);
    
    // 체크박스가 있는 줄인지 확인
    if (lineText.startsWith('☐ ') || lineText.startsWith('☑ ')) {
      // 클릭한 위치가 체크박스 부근인지 확인 (줄 시작에서 3글자 이내)
      if (offset >= lineStart && offset <= lineStart + 2) {
        // 체크박스 영역을 클릭한 경우 토글
        widget.textStyleState.toggleCheckboxAt(widget.controller, offset);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.textStyleState,
      builder: (context, child) {
        return TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          style: widget.textStyleState.currentTextStyle,
          decoration: widget.decoration,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          onTap: _handleTap,
        );
      },
    );
  }
}