import 'package:flutter/material.dart';
import 'custom_toolbar.dart';
import 'text_style_state.dart';
import 'advanced_rich_text_field.dart';
import 'rich_text_style_manager.dart';

/// 툴바 오버레이 위치 관리 클래스
/// 
/// 키보드 위에 툴바를 고정 위치시키고, 키보드 높이 변화에 따라
/// 툴바 위치를 자동으로 조정하는 기능을 제공합니다.
class ToolbarOverlayManager {
  /// 오버레이 엔트리
  OverlayEntry? _overlayEntry;
  
  /// 현재 컨텍스트
  BuildContext? _context;
  
  /// 텍스트 스타일 상태
  TextStyleState? _textStyleState;
  
  /// 현재 활성화된 텍스트 컨트롤러
  TextEditingController? _textController;
  
  /// Rich Text 필드의 GlobalKey 참조 (스타일 적용용)
  GlobalKey<AdvancedRichTextFieldState>? _richTextFieldKey;
  
  /// 툴바 표시 여부
  bool _isVisible = false;
  
  /// 키보드 높이 감지를 위한 리스너
  VoidCallback? _keyboardListener;

  /// 싱글톤 인스턴스
  static final ToolbarOverlayManager _instance = ToolbarOverlayManager._internal();
  
  factory ToolbarOverlayManager() {
    return _instance;
  }
  
  ToolbarOverlayManager._internal();

  /// 툴바 오버레이 초기화 및 표시
  /// 
  /// [context] - 현재 화면의 BuildContext
  /// [textStyleState] - 텍스트 스타일 상태 관리 객체
  /// [textController] - 현재 활성화된 TextEditingController
  /// [richTextFieldKey] - AdvancedRichTextField의 GlobalKey (선택사항)
  void showToolbar(
    BuildContext context,
    TextStyleState textStyleState,
    TextEditingController textController, {
    GlobalKey<AdvancedRichTextFieldState>? richTextFieldKey,
  }) {
    // 기존 툴바가 있으면 제거
    hideToolbar();
    
    _context = context;
    _textStyleState = textStyleState;
    _textController = textController;
    _richTextFieldKey = richTextFieldKey;
    _isVisible = true;
    
    // 오버레이 엔트리 생성
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildToolbarOverlay(),
    );
    
    // 오버레이에 툴바 추가
    Overlay.of(context)?.insert(_overlayEntry!);
    
    // 키보드 높이 변화 감지 리스너 등록
    _setupKeyboardListener();
  }

  /// 툴바 오버레이 숨김
  void hideToolbar() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isVisible = false;
    _keyboardListener = null;
    
    // 리소스 정리
    _context = null;
    _textStyleState = null;
    _textController = null;
    _richTextFieldKey = null;
  }

  /// 툴바 표시 상태 확인
  bool get isVisible => _isVisible && _overlayEntry != null;

  /// 툴바 오버레이 위젯 생성
  Widget _buildToolbarOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: _getToolbarBottomPosition(),
      child: Material(
        elevation: 8.0, // 더 높은 elevation으로 다른 요소 위에 표시
        color: Colors.transparent,
        type: MaterialType.transparency,
        child: Container(
          // 명시적인 z-index 설정
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: CustomToolbar(
            textStyleState: _textStyleState!,
            textController: _textController,
            isVisible: _isVisible,
            // Rich Text 스타일 적용 콜백들
            onApplyFontSize: _getRichTextFieldState() != null 
              ? (start, end, fontSize) => _getRichTextFieldState()!.styleManager.applyFontSizeToSelection(start, end, fontSize)
              : null,
            onApplyColor: _getRichTextFieldState() != null 
              ? (start, end, color) => _getRichTextFieldState()!.styleManager.applyColorToSelection(start, end, color)
              : null,
            onApplyBold: _getRichTextFieldState() != null 
              ? (start, end, isBold) => _getRichTextFieldState()!.styleManager.applyBoldToSelection(start, end, isBold)
              : null,
            onApplyUnderline: _getRichTextFieldState() != null 
              ? (start, end, isUnderline) => _getRichTextFieldState()!.styleManager.applyUnderlineToSelection(start, end, isUnderline)
              : null,
          ),
        ),
      ),
    );
  }

  /// 툴바의 하단 위치 계산
  /// 키보드 높이를 고려하여 적절한 위치를 반환
  double _getToolbarBottomPosition() {
    if (_context == null) return 0;
    
    final mediaQuery = MediaQuery.of(_context!);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final safeAreaBottom = mediaQuery.padding.bottom;
    
    // 키보드가 올라와 있으면 키보드 바로 위에
    if (keyboardHeight > 0) {
      // 최소 높이 보장 (일부 기기에서 부정확한 viewInsets 대응)
      final minKeyboardHeight = 200.0;
      final adjustedHeight = keyboardHeight < minKeyboardHeight ? minKeyboardHeight : keyboardHeight;
      
      // 키보드 바로 위에 배치 (간격 제거)
      return adjustedHeight;
    } else {
      // 키보드가 없을 때는 SafeArea 하단에 고정
      return safeAreaBottom;
    }
  }

  /// 키보드 높이 변화 감지 리스너 설정
  void _setupKeyboardListener() {
    if (_context == null) return;
    
    // MediaQuery 변화를 감지하여 툴바 위치 업데이트
    _keyboardListener = () {
      if (_overlayEntry != null && _context != null) {
        // 키보드 높이가 변경되면 오버레이 재구성
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_overlayEntry != null) {
            _overlayEntry!.markNeedsBuild();
          }
        });
      }
    };
  }
  
  /// 키보드 높이 변화 감지 시 호출 (Mixin에서 사용)
  void onKeyboardHeightChanged() {
    if (_overlayEntry != null && _context != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  /// Rich Text Field의 State에 접근하기 위한 헬퍼 메서드
  AdvancedRichTextFieldState? _getRichTextFieldState() {
    return _richTextFieldKey?.currentState;
  }

  /// 현재 활성화된 텍스트 컨트롤러 업데이트
  void updateTextController(TextEditingController? controller) {
    if (_isVisible && _overlayEntry != null) {
      _textController = controller;
      _overlayEntry!.markNeedsBuild();
    }
  }

  /// 툴바 가시성 토글
  void toggleVisibility() {
    if (_isVisible) {
      hideToolbar();
    } else if (_context != null && _textStyleState != null && _textController != null) {
      showToolbar(_context!, _textStyleState!, _textController!);
    }
  }
}

/// 키보드 인식 StatefulWidget을 위한 Mixin
/// 
/// 화면에서 이 Mixin을 사용하면 키보드 높이 변화를 자동으로 감지하고
/// 툴바 위치를 업데이트할 수 있습니다.
mixin KeyboardAwareToolbarMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  /// 툴바 오버레이 매니저
  late final ToolbarOverlayManager _toolbarManager;
  
  /// 텍스트 스타일 상태
  late final TextStyleState _textStyleState;
  
  /// 이전 키보드 높이 (변화 감지용)
  double _previousKeyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    _toolbarManager = ToolbarOverlayManager();
    _textStyleState = TextStyleState();
    // WidgetsBinding 옵저버 등록
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    
    // 키보드 높이 변화 감지 (디바운싱 적용)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final currentKeyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      final heightDifference = (currentKeyboardHeight - _previousKeyboardHeight).abs();
      
      // 최소 변화량 임계값 (작은 변화는 무시)
      if (heightDifference < 10.0) return;
      
      if (currentKeyboardHeight != _previousKeyboardHeight) {
        _previousKeyboardHeight = currentKeyboardHeight;
        
        // 키보드 상태 감지 개선
        final isKeyboardVisible = currentKeyboardHeight > 50.0; // 더 엄격한 임계값
        
        if (isKeyboardVisible && !_toolbarManager.isVisible) {
          // 지연 시간을 두어 키보드 애니메이션 완료 대기
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && isKeyboardVisible) {
              _showToolbarIfNeeded();
            }
          });
        } else if (!isKeyboardVisible && _toolbarManager.isVisible) {
          _toolbarManager.hideToolbar();
        } else if (_toolbarManager.isVisible) {
          // 키보드 높이가 변경되었지만 툴바가 이미 표시 중인 경우 위치 업데이트
          _toolbarManager.onKeyboardHeightChanged();
        }
      }
    });
  }

  @override
  void dispose() {
    // WidgetsBinding 옵저버 해제
    WidgetsBinding.instance.removeObserver(this);
    _toolbarManager.hideToolbar();
    _textStyleState.dispose();
    super.dispose();
  }

  /// 현재 활성화된 TextEditingController 반환
  /// 서브클래스에서 구현해야 함
  TextEditingController? get currentTextController;
  
  /// 현재 활성화된 AdvancedRichTextField의 GlobalKey 반환 (선택사항)
  /// Rich Text 기능을 사용하려면 서브클래스에서 구현
  GlobalKey<AdvancedRichTextFieldState>? get currentRichTextFieldKey => null;

  /// 툴바 표시 (필요한 경우에만)
  void _showToolbarIfNeeded() {
    final controller = currentTextController;
    final richTextFieldKey = currentRichTextFieldKey;
    if (controller != null && mounted) {
      _toolbarManager.showToolbar(
        context, 
        _textStyleState, 
        controller,
        richTextFieldKey: richTextFieldKey,
      );
    }
  }

  /// 수동으로 툴바 표시/숨김
  void toggleToolbar() {
    _toolbarManager.toggleVisibility();
  }

  /// 텍스트 스타일 상태 접근자
  TextStyleState get textStyleState => _textStyleState;
}