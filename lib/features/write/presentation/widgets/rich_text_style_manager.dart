import 'package:flutter/material.dart';

/// 개별 텍스트 범위의 스타일 정보
class TextStyleRange {
  final int start;
  final int end;
  final double? fontSize;
  final Color? color;
  final bool? isBold;
  final bool? isUnderline;
  final bool? isLineThrough;

  const TextStyleRange({
    required this.start,
    required this.end,
    this.fontSize,
    this.color,
    this.isBold,
    this.isUnderline,
    this.isLineThrough,
  });

  TextStyleRange copyWith({
    int? start,
    int? end,
    double? fontSize,
    Color? color,
    bool? isBold,
    bool? isUnderline,
    bool? isLineThrough,
  }) {
    return TextStyleRange(
      start: start ?? this.start,
      end: end ?? this.end,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      isBold: isBold ?? this.isBold,
      isUnderline: isUnderline ?? this.isUnderline,
      isLineThrough: isLineThrough ?? this.isLineThrough,
    );
  }

  /// 기본 스타일에 현재 범위 스타일을 적용한 TextStyle 생성
  TextStyle toTextStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontSize: fontSize ?? baseStyle.fontSize,
      color: color ?? baseStyle.color,
      fontWeight: (isBold ?? false) ? FontWeight.bold : FontWeight.normal,
      decoration: _buildDecoration(baseStyle.decoration),
    );
  }

  /// 텍스트 데코레이션 생성
  TextDecoration _buildDecoration(TextDecoration? baseDecoration) {
    List<TextDecoration> decorations = [];
    
    if (isUnderline ?? false) {
      decorations.add(TextDecoration.underline);
    }
    
    if (isLineThrough ?? false) {
      decorations.add(TextDecoration.lineThrough);
    }
    
    if (decorations.isEmpty) {
      return baseDecoration ?? TextDecoration.none;
    } else if (decorations.length == 1) {
      return decorations.first;
    } else {
      return TextDecoration.combine(decorations);
    }
  }
}

/// Rich Text 스타일 관리자
/// 
/// 텍스트의 각 범위별로 개별 스타일을 적용할 수 있도록 관리합니다.
class RichTextStyleManager extends ChangeNotifier {
  /// 텍스트 스타일 범위 목록
  List<TextStyleRange> _styleRanges = [];
  
  /// 현재 커서 위치에서의 기본 스타일 (새로 입력되는 텍스트용)
  double _currentFontSize = 16.0;
  Color _currentColor = Colors.black;
  bool _currentIsBold = false;
  bool _currentIsUnderline = false;
  bool _currentIsLineThrough = false;
  
  /// 사용 가능한 색상 목록
  static const List<Color> _availableColors = [
    Colors.black,
    Colors.red,
    Colors.blue,
  ];
  int _colorIndex = 0;

  // === Getters ===
  
  List<TextStyleRange> get styleRanges => List.unmodifiable(_styleRanges);
  double get currentFontSize => _currentFontSize;
  Color get currentColor => _currentColor;
  bool get currentIsBold => _currentIsBold;
  bool get currentIsUnderline => _currentIsUnderline;
  bool get currentIsLineThrough => _currentIsLineThrough;

  /// 현재 기본 스타일
  TextStyle get currentTextStyle => TextStyle(
    fontSize: _currentFontSize,
    color: _currentColor,
    fontWeight: _currentIsBold ? FontWeight.bold : FontWeight.normal,
    decoration: _buildCurrentDecoration(),
  );

  TextDecoration _buildCurrentDecoration() {
    List<TextDecoration> decorations = [];
    
    if (_currentIsUnderline) {
      decorations.add(TextDecoration.underline);
    }
    
    if (_currentIsLineThrough) {
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

  // === 스타일 적용 메서드 ===

  /// 선택된 텍스트 범위에 폰트 크기 적용
  void applyFontSizeToSelection(int start, int end, double fontSize) {
    if (start >= end) return;
    
    _applyStyleToRange(start, end, fontSize: fontSize);
    notifyListeners();
  }

  /// 선택된 텍스트 범위에 색상 적용
  void applyColorToSelection(int start, int end, Color color) {
    if (start >= end) return;
    
    _applyStyleToRange(start, end, color: color);
    notifyListeners();
  }

  /// 선택된 텍스트 범위에 Bold 적용
  void applyBoldToSelection(int start, int end, bool isBold) {
    if (start >= end) return;
    
    _applyStyleToRange(start, end, isBold: isBold);
    notifyListeners();
  }

  /// 선택된 텍스트 범위에 Underline 적용
  void applyUnderlineToSelection(int start, int end, bool isUnderline) {
    if (start >= end) return;
    
    _applyStyleToRange(start, end, isUnderline: isUnderline);
    notifyListeners();
  }
  
  /// 새로 입력된 텍스트에 스타일 적용 (공개 메서드)
  void applyStyleToRange(
    int start, 
    int end, {
    double? fontSize,
    Color? color,
    bool? isBold,
    bool? isUnderline,
    bool? isLineThrough,
  }) {
    if (start >= end) return;
    
    _applyStyleToRange(
      start, 
      end, 
      fontSize: fontSize,
      color: color,
      isBold: isBold,
      isUnderline: isUnderline,
      isLineThrough: isLineThrough,
    );
    notifyListeners();
  }

  /// 내부적으로 스타일 범위에 스타일 적용
  void _applyStyleToRange(
    int start, 
    int end, {
    double? fontSize,
    Color? color,
    bool? isBold,
    bool? isUnderline,
    bool? isLineThrough,
  }) {
    // 기존 범위와 겹치는 부분 처리
    List<TextStyleRange> newRanges = [];
    
    for (var range in _styleRanges) {
      if (range.end <= start || range.start >= end) {
        // 겹치지 않는 범위는 그대로 유지
        newRanges.add(range);
      } else {
        // 겹치는 범위 처리
        // 앞쪽 부분 (겹치지 않는 부분)
        if (range.start < start) {
          newRanges.add(TextStyleRange(
            start: range.start,
            end: start,
            fontSize: range.fontSize,
            color: range.color,
            isBold: range.isBold,
            isUnderline: range.isUnderline,
            isLineThrough: range.isLineThrough,
          ));
        }
        
        // 뒤쪽 부분 (겹치지 않는 부분)
        if (range.end > end) {
          newRanges.add(TextStyleRange(
            start: end,
            end: range.end,
            fontSize: range.fontSize,
            color: range.color,
            isBold: range.isBold,
            isUnderline: range.isUnderline,
            isLineThrough: range.isLineThrough,
          ));
        }
      }
    }
    
    // 새로운 스타일 범위 추가
    newRanges.add(TextStyleRange(
      start: start,
      end: end,
      fontSize: fontSize,
      color: color,
      isBold: isBold,
      isUnderline: isUnderline,
      isLineThrough: isLineThrough,
    ));
    
    // 범위 정렬
    newRanges.sort((a, b) => a.start.compareTo(b.start));
    _styleRanges = newRanges;
  }

  // === 현재 스타일 조정 메서드 ===

  /// 폰트 크기 증가
  void increaseFontSize() {
    if (_currentFontSize < 24.0) {
      _currentFontSize = (_currentFontSize + 2.0).clamp(12.0, 24.0);
      notifyListeners();
    }
  }

  /// 폰트 크기 감소
  void decreaseFontSize() {
    if (_currentFontSize > 12.0) {
      _currentFontSize = (_currentFontSize - 2.0).clamp(12.0, 24.0);
      notifyListeners();
    }
  }

  /// 색상 순환
  void cycleTextColor() {
    _colorIndex = (_colorIndex + 1) % _availableColors.length;
    _currentColor = _availableColors[_colorIndex];
    notifyListeners();
  }

  /// Bold 토글
  void toggleBold() {
    _currentIsBold = !_currentIsBold;
    notifyListeners();
  }

  /// Underline 토글
  void toggleUnderline() {
    _currentIsUnderline = !_currentIsUnderline;
    notifyListeners();
  }

  /// 텍스트에서 Rich TextSpan 생성
  List<TextSpan> buildTextSpans(String text, TextStyle baseStyle) {
    if (_styleRanges.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    List<TextSpan> spans = [];
    int currentIndex = 0;

    for (var range in _styleRanges) {
      // 스타일이 적용되지 않은 앞부분
      if (currentIndex < range.start) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, range.start),
          style: baseStyle,
        ));
      }

      // 스타일이 적용된 부분
      if (range.start < text.length) {
        int endIndex = range.end.clamp(0, text.length);
        spans.add(TextSpan(
          text: text.substring(range.start, endIndex),
          style: range.toTextStyle(baseStyle),
        ));
        currentIndex = endIndex;
      }
    }

    // 남은 부분
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: baseStyle,
      ));
    }

    return spans;
  }

  /// 텍스트 변경 시 스타일 범위 조정
  ///
  /// [changeStart] 위치에서 [oldLength]만큼의 텍스트가 [newLength]만큼의 텍스트로 바뀌었을 때
  /// 각 스타일 범위를 이동하거나 축소합니다. 범위 안쪽에 입력된 텍스트는 해당 스타일을 이어받습니다.
  void adjustRangesForTextChange(int changeStart, int oldLength, int newLength) {
    final delta = newLength - oldLength;
    final changeEnd = changeStart + oldLength;
    
    List<TextStyleRange> adjustedRanges = [];
    
    for (var range in _styleRanges) {
      if (range.end <= changeStart) {
        // 변경 지점 이전의 범위는 그대로 유지
        adjustedRanges.add(range);
      } else if (range.start >= changeEnd) {
        // 변경 지점 이후의 범위는 오프셋 조정
        adjustedRanges.add(range.copyWith(
          start: range.start + delta,
          end: range.end + delta,
        ));
      } else {
        // 변경 구간과 겹치는 범위: 남는 앞부분/뒷부분만 유지
        final newStart = range.start < changeStart ? range.start : changeStart + newLength;
        final newEnd = range.end > changeEnd ? range.end + delta : changeStart;
        if (range.start < changeStart && range.end > changeEnd) {
          // 범위 내부에서 편집된 경우 전체 범위 유지 (입력된 텍스트도 같은 스타일)
          adjustedRanges.add(range.copyWith(end: range.end + delta));
        } else if (newStart < newEnd) {
          adjustedRanges.add(range.copyWith(start: newStart, end: newEnd));
        }
      }
    }
    
    _styleRanges = adjustedRanges;
    notifyListeners();
  }

  /// 스타일 초기화
  void reset() {
    _styleRanges.clear();
    _currentFontSize = 16.0;
    _currentColor = Colors.black;
    _colorIndex = 0;
    _currentIsBold = false;
    _currentIsUnderline = false;
    _currentIsLineThrough = false;
    notifyListeners();
  }
}