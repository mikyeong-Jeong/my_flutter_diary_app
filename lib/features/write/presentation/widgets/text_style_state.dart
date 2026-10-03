import 'package:flutter/material.dart';

import '../../../../core/utils/checklist_utils.dart';

/// 텍스트 스타일 상태 관리 클래스
/// 
/// 사용자가 입력 툴바에서 선택한 텍스트 스타일 설정을 관리합니다.
/// 폰트 크기, 색상, Bold, Underline, 체크박스 상태 등을 포함합니다.
class TextStyleState extends ChangeNotifier {
  /// 현재 폰트 크기 (12-24px 범위)
  double _fontSize = 16.0;
  
  /// 현재 텍스트 색상 (검정, 빨강, 파랑 순환)
  Color _textColor = Colors.black;
  
  /// Bold 활성화 여부
  bool _isBold = false;
  
  /// Underline 활성화 여부
  bool _isUnderline = false;
  
  /// 취소선(체크박스 완료) 활성화 여부
  bool _isLineThrough = false;
  
  /// 사용 가능한 색상 목록 (순환용)
  static const List<Color> _availableColors = [
    Colors.black,
    Colors.red,
    Colors.blue,
  ];
  
  /// 현재 색상 인덱스
  int _colorIndex = 0;

  // === Getters ===
  
  /// 현재 폰트 크기
  double get fontSize => _fontSize;
  
  /// 현재 텍스트 색상
  Color get textColor => _textColor;
  
  /// Bold 활성화 여부
  bool get isBold => _isBold;
  
  /// Underline 활성화 여부
  bool get isUnderline => _isUnderline;
  
  /// 취소선 활성화 여부
  bool get isLineThrough => _isLineThrough;
  
  /// 현재 설정을 기반으로 한 TextStyle 객체
  TextStyle get currentTextStyle => TextStyle(
    fontSize: _fontSize,
    color: _textColor,
    fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
    decoration: _getTextDecoration(),
  );

  // === 폰트 크기 조정 ===
  
  /// 폰트 크기 증가 (최대 24px)
  void increaseFontSize() {
    if (_fontSize < 24.0) {
      _fontSize = (_fontSize + 2.0).clamp(12.0, 24.0);
      notifyListeners();
    }
  }
  
  /// 폰트 크기 감소 (최소 12px)
  void decreaseFontSize() {
    if (_fontSize > 12.0) {
      _fontSize = (_fontSize - 2.0).clamp(12.0, 24.0);
      notifyListeners();
    }
  }

  // === 텍스트 색상 변경 ===
  
  /// 텍스트 색상 순환 변경 (검정 → 빨강 → 파랑 → 검정...)
  void cycleTextColor() {
    _colorIndex = (_colorIndex + 1) % _availableColors.length;
    _textColor = _availableColors[_colorIndex];
    notifyListeners();
  }

  // === Bold/Underline 토글 ===
  
  /// Bold 상태 토글
  void toggleBold() {
    _isBold = !_isBold;
    notifyListeners();
  }
  
  /// Underline 상태 토글
  void toggleUnderline() {
    _isUnderline = !_isUnderline;
    notifyListeners();
  }
  
  /// 취소선 상태 토글 (체크박스용)
  void toggleLineThrough() {
    _isLineThrough = !_isLineThrough;
    notifyListeners();
  }

  // === 체크박스 관련 메서드 ===
  
  /// 커서 위치에 체크박스 삽입 (이모지 추가 방식)
  /// 현재 커서 위치에 바로 체크박스를 삽입합니다
  void insertCheckbox(TextEditingController controller) {
    final currentText = controller.text;
    final selection = controller.selection;
    
    // 현재 커서 위치에 체크박스 문자 삽입
    // 본문에 커서가 없으면(selection = -1) 텍스트 끝에 삽입
    final cursorPosition = selection.isValid
        ? selection.start.clamp(0, currentText.length)
        : currentText.length;
    
    // 빈 체크박스와 공백을 현재 위치에 삽입
    String newText = currentText.replaceRange(
      cursorPosition, 
      cursorPosition, 
      '${ChecklistUtils.unchecked} ' // 체크박스 전용 기호 (☐)
    );
    
    // 커서를 체크박스 뒤로 이동
    int newCursorPos = cursorPosition + 2;
    
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
    
    notifyListeners();
  }
  
  /// 선택된 텍스트에 현재 스타일 적용
  /// Rich Text 지원 시 사용할 수 있는 메서드
  void applyStyleToSelection(TextEditingController controller, {
    Function(int start, int end, double fontSize)? onApplyFontSize,
    Function(int start, int end, Color color)? onApplyColor,
    Function(int start, int end, bool isBold)? onApplyBold,
    Function(int start, int end, bool isUnderline)? onApplyUnderline,
  }) {
    final selection = controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final start = selection.start;
      final end = selection.end;
      
      // 콜백이 제공된 경우 선택된 텍스트에 스타일 적용
      onApplyFontSize?.call(start, end, _fontSize);
      onApplyColor?.call(start, end, _textColor);
      onApplyBold?.call(start, end, _isBold);
      onApplyUnderline?.call(start, end, _isUnderline);
      
      notifyListeners();
    }
  }
  
  /// 선택된 텍스트에 폰트 크기만 적용
  void applyFontSizeToSelection(TextEditingController controller, {
    Function(int start, int end, double fontSize)? onApplyFontSize,
  }) {
    final selection = controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      onApplyFontSize?.call(selection.start, selection.end, _fontSize);
      notifyListeners();
    }
  }
  
  /// 선택된 텍스트에 색상만 적용
  void applyColorToSelection(TextEditingController controller, {
    Function(int start, int end, Color color)? onApplyColor,
  }) {
    final selection = controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      onApplyColor?.call(selection.start, selection.end, _textColor);
      notifyListeners();
    }
  }
  
  /// 선택된 텍스트에 Bold만 적용
  void applyBoldToSelection(TextEditingController controller, {
    Function(int start, int end, bool isBold)? onApplyBold,
  }) {
    final selection = controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      onApplyBold?.call(selection.start, selection.end, _isBold);
      notifyListeners();
    }
  }
  
  /// 선택된 텍스트에 Underline만 적용
  void applyUnderlineToSelection(TextEditingController controller, {
    Function(int start, int end, bool isUnderline)? onApplyUnderline,
  }) {
    final selection = controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      onApplyUnderline?.call(selection.start, selection.end, _isUnderline);
      notifyListeners();
    }
  }

  // === 내부 헬퍼 메서드 ===
  
  /// 현재 설정에 따른 TextDecoration 생성
  TextDecoration _getTextDecoration() {
    List<TextDecoration> decorations = [];
    
    if (_isUnderline) {
      decorations.add(TextDecoration.underline);
    }
    
    if (_isLineThrough) {
      decorations.add(TextDecoration.lineThrough);
    }
    
    if (decorations.isEmpty) {
      return TextDecoration.none;
    } else if (decorations.length == 1) {
      return decorations.first;
    } else {
      return TextDecoration.combine(decorations);
    }
  }
  
  /// 스타일 상태 초기화
  void reset() {
    _fontSize = 16.0;
    _textColor = Colors.black;
    _colorIndex = 0;
    _isBold = false;
    _isUnderline = false;
    _isLineThrough = false;
    notifyListeners();
  }
  
  /// 디버그용 현재 상태 출력
  @override
  String toString() {
    return 'TextStyleState(fontSize: $_fontSize, color: $_textColor, '
           'bold: $_isBold, underline: $_isUnderline, lineThrough: $_isLineThrough)';
  }
}