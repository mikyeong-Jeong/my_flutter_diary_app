import 'package:flutter/material.dart';
import '../../../../core/utils/checklist_utils.dart';
import 'rich_text_style_manager.dart';
import 'text_style_state.dart';

/// 고급 Rich Text 지원 텍스트 필드
/// 
/// 선택된 텍스트에 개별적으로 스타일을 적용할 수 있으며,
/// 체크박스 기능도 지원합니다.
class AdvancedRichTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextStyleState textStyleState;
  final InputDecoration? decoration;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  const AdvancedRichTextField({
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
  State<AdvancedRichTextField> createState() => AdvancedRichTextFieldState();
}

class AdvancedRichTextFieldState extends State<AdvancedRichTextField> {
  late RichTextStyleManager _styleManager;
  String _previousText = '';

  @override
  void initState() {
    super.initState();
    _styleManager = RichTextStyleManager();
    _previousText = widget.controller.text;
    
    // 텍스트 변경 감지
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _styleManager.dispose();
    super.dispose();
  }

  /// 텍스트 변경 이벤트 처리
  void _onTextChanged() {
    final currentText = widget.controller.text;
    if (currentText == _previousText) return;

    // 이전/현재 텍스트의 공통 앞부분·뒷부분을 제외한 실제 변경 구간 계산
    final oldText = _previousText;
    final minLength = oldText.length < currentText.length ? oldText.length : currentText.length;
    int prefix = 0;
    while (prefix < minLength && oldText.codeUnitAt(prefix) == currentText.codeUnitAt(prefix)) {
      prefix++;
    }
    int suffix = 0;
    while (suffix < minLength - prefix &&
        oldText.codeUnitAt(oldText.length - 1 - suffix) ==
            currentText.codeUnitAt(currentText.length - 1 - suffix)) {
      suffix++;
    }
    final removedLength = oldText.length - prefix - suffix;
    final insertedLength = currentText.length - prefix - suffix;

    // 기존 스타일 범위를 변경 구간에 맞춰 이동/축소한 뒤
    _styleManager.adjustRangesForTextChange(prefix, removedLength, insertedLength);

    // 새로 입력된 텍스트에 현재 툴바 스타일 적용
    if (insertedLength > 0) {
      _applyCurrentStyleToNewText(prefix, prefix + insertedLength);
    }

    _previousText = currentText;
  }
  
  /// 새로 입력된 텍스트에 현재 스타일 적용
  void _applyCurrentStyleToNewText(int start, int end) {
    // 현재 툴바 설정에 따라 스타일 적용
    final textStyleState = widget.textStyleState;
    
    // 기본 스타일과 다른 경우에만 적용
    bool needsApply = false;
    
    if (textStyleState.fontSize != 16.0 ||
        textStyleState.textColor != Colors.black ||
        textStyleState.isBold ||
        textStyleState.isUnderline) {
      needsApply = true;
    }
    
    if (needsApply) {
      _styleManager.applyStyleToRange(
        start, 
        end,
        fontSize: textStyleState.fontSize != 16.0 ? textStyleState.fontSize : null,
        color: textStyleState.textColor != Colors.black ? textStyleState.textColor : null,
        isBold: textStyleState.isBold ? true : null,
        isUnderline: textStyleState.isUnderline ? true : null,
      );
    }
  }

  /// 체크박스 클릭 처리
  void _handleTap() {
    Future.delayed(const Duration(milliseconds: 50), () {
      final selection = widget.controller.selection;
      if (selection.isValid && selection.isCollapsed) {
        _checkAndToggleCheckbox(selection.baseOffset);
      }
    });
  }

  /// 체크박스 클릭 감지 및 토글 처리
  void _checkAndToggleCheckbox(int offset) {
    final text = widget.controller.text;
    if (text.isEmpty) return;

    // 체크박스 글자(☐/☑)의 오른쪽 절반을 탭해 커서가 '체크박스|공백' 사이에 놓인 경우에만 토글
    // (체크박스 왼쪽 = 줄 맨 앞으로 커서를 옮기는 탭은 토글하지 않음)
    if (offset >= 1 && offset < text.length) {
      final prevChar = text[offset - 1];
      if (ChecklistUtils.isCheckbox(prevChar) && text[offset] == ' ') {
        _toggleCheckboxAtPosition(
          offset - 1,
          prevChar == ChecklistUtils.unchecked ? ChecklistUtils.checked : ChecklistUtils.unchecked,
        );
      }
    }
  }
  
  /// 특정 위치의 체크박스를 토글
  void _toggleCheckboxAtPosition(int position, String newChar) {
    final text = widget.controller.text;
    final newText = text.replaceRange(position, position + 1, newChar);
    
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: widget.controller.selection,
    );
  }

  /// 선택된 텍스트에 현재 스타일 적용
  void applyCurrentStyleToSelection() {
    final selection = widget.controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;

    final start = selection.start;
    final end = selection.end;

    // 현재 스타일을 선택 영역에 적용
    _styleManager.applyFontSizeToSelection(start, end, widget.textStyleState.fontSize);
    _styleManager.applyColorToSelection(start, end, widget.textStyleState.textColor);
    _styleManager.applyBoldToSelection(start, end, widget.textStyleState.isBold);
    _styleManager.applyUnderlineToSelection(start, end, widget.textStyleState.isUnderline);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.textStyleState, _styleManager]),
      builder: (context, child) {
        // 단순한 TextField만 사용 - 체크박스 기능만 지원
        return TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          decoration: widget.decoration,
          // 색상은 테마를 따름 (다크모드에서 검정 고정 시 글자가 보이지 않음)
          style: const TextStyle(
            fontSize: 16.0,
            height: 1.2,
          ),
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          onTap: _handleTap,
          cursorWidth: 1.5,
          showCursor: true,
          enableInteractiveSelection: true,
        );
      },
    );
  }

  /// 외부에서 스타일 적용을 위한 메서드
  void applyStyleToCurrentSelection() {
    applyCurrentStyleToSelection();
  }

  /// 스타일 매니저에 접근하기 위한 getter
  RichTextStyleManager get styleManager => _styleManager;
}