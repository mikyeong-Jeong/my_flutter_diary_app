import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    
    if (currentText != _previousText) {
      final selection = widget.controller.selection;
      
      if (selection.isValid) {
        int changeStart = selection.baseOffset;
        int oldLength = _previousText.length;
        int newLength = currentText.length;
        
        // 텍스트 추가된 경우 (새로 입력된 텍스트)
        if (newLength > oldLength) {
          int addedLength = newLength - oldLength;
          int insertStart = changeStart - addedLength;
          
          // 새로 입력된 텍스트에 현재 툴바 스타일 적용
          if (insertStart >= 0 && addedLength > 0) {
            _applyCurrentStyleToNewText(insertStart, insertStart + addedLength);
          }
        }
        
        // 텍스트 변경 시 스타일 범위 조정
        _styleManager.adjustRangesForTextChange(changeStart, oldLength, newLength);
      }
      
      // 체크박스 상태 업데이트
      _updateCheckboxStyle(currentText);
      
      _previousText = currentText;
    }
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
      if (selection.isValid) {
        _checkAndToggleCheckbox(selection.baseOffset);
      }
    });
  }

  /// 체크박스 클릭 감지 및 토글 처리
  void _checkAndToggleCheckbox(int offset) {
    final text = widget.controller.text;
    if (text.isEmpty) return;

    // 클릭한 위치에서 체크박스 문자 확인
    if (offset >= 0 && offset < text.length) {
      final char = text[offset];
      
      // 빈 체크박스(□) 클릭 시
      if (char == '□') {
        _toggleCheckboxAtPosition(offset, '■');
        return;
      }
      
      // 체크된 체크박스(■) 클릭 시  
      if (char == '■') {
        _toggleCheckboxAtPosition(offset, '□');
        return;
      }
    }
    
    // 체크박스 바로 뒤 공백 클릭 시도 체크
    if (offset >= 1 && offset < text.length) {
      final prevChar = text[offset - 1];
      if ((prevChar == '□' || prevChar == '■') && text[offset] == ' ') {
        final newChar = prevChar == '□' ? '■' : '□';
        _toggleCheckboxAtPosition(offset - 1, newChar);
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

  /// RichText 기능 비활성화 - 단순한 체크박스만 지원
  Widget _buildStyledRichText() {
    // 더 이상 사용하지 않음
    return const SizedBox.shrink();
  }

  /// TextSpan 기능 비활성화 - 단순한 체크박스만 지원
  List<TextSpan> _buildLineBasedTextSpans(String text) {
    // 더 이상 사용하지 않음
    return [];
  }

  /// TextField의 동적 패딩 계산 (호환성을 위해 유지)
  EdgeInsets _calculateTextFieldPadding() {
    return _getTextFieldPadding();
  }
  
  /// TextField의 패딩 계산 (RichText와 동기화용)
  EdgeInsets _getTextFieldPadding() {
    final decoration = widget.decoration;
    
    // 명시적 contentPadding이 있으면 사용
    if (decoration?.contentPadding != null) {
      return decoration!.contentPadding! as EdgeInsets;
    }
    
    // 기본 Flutter TextField 패딩
    final border = decoration?.border;
    if (border is OutlineInputBorder) {
      return const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0);
    } else if (border is UnderlineInputBorder) {
      return const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0);
    } else {
      // 기본값
      return const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0);
    }
  }


  /// 체크박스 상태 업데이트 (RichText 방식에서는 불필요)
  void _updateCheckboxStyle(String text) {
    // RichText 방식에서는 줄별로 자동 처리되므로 별도 업데이트 불필요
    // 향후 호환성을 위해 메서드는 유지
  }

  /// 외부에서 스타일 적용을 위한 메서드
  void applyStyleToCurrentSelection() {
    applyCurrentStyleToSelection();
  }

  /// 스타일 매니저에 접근하기 위한 getter
  RichTextStyleManager get styleManager => _styleManager;
}