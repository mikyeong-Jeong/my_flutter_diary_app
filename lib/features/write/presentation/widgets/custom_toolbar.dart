import 'package:flutter/material.dart';
import 'checklist_text_editing_controller.dart';
import 'text_style_state.dart';

/// 삼성 노트 스타일 입력 툴바 위젯
/// 
/// 키보드 위에 고정되어 표시되며, 텍스트 스타일을 변경할 수 있는 버튼들을 제공합니다.
/// 텍스트 크기, 색상, Bold, Underline, 체크박스 기능을 포함합니다.
class CustomToolbar extends StatefulWidget {
  /// 텍스트 스타일 상태 관리 객체
  final TextStyleState textStyleState;
  
  /// 현재 활성화된 TextEditingController (체크박스 삽입용)
  final TextEditingController? textController;
  
  /// 툴바가 표시되는지 여부
  final bool isVisible;
  
  /// 툴바 표시/숨김 상태 변경 콜백
  final ValueChanged<bool>? onVisibilityChanged;
  
  /// 선택된 텍스트에 스타일 적용 콜백들
  final Function(int start, int end, double fontSize)? onApplyFontSize;
  final Function(int start, int end, Color color)? onApplyColor;
  final Function(int start, int end, bool isBold)? onApplyBold;
  final Function(int start, int end, bool isUnderline)? onApplyUnderline;

  const CustomToolbar({
    super.key,
    required this.textStyleState,
    this.textController,
    this.isVisible = true,
    this.onVisibilityChanged,
    this.onApplyFontSize,
    this.onApplyColor,
    this.onApplyBold,
    this.onApplyUnderline,
  });

  @override
  State<CustomToolbar> createState() => _CustomToolbarState();
}

class _CustomToolbarState extends State<CustomToolbar>
    with SingleTickerProviderStateMixin {
  
  /// 툴바 애니메이션 컨트롤러
  late AnimationController _animationController;
  
  /// 툴바 슬라이드 애니메이션
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // 슬라이드 애니메이션 설정 (아래에서 위로)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // 초기 표시 상태에 따라 애니메이션 시작
    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(CustomToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 표시 상태가 변경되면 애니메이션 실행
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: 56.0, // 툴바 고정 높이
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, -2),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: _buildToolbarContent(),
        ),
      ),
    );
  }

  /// 툴바 내용 위젯 생성
  Widget _buildToolbarContent() {
    return AnimatedBuilder(
      animation: widget.textStyleState,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1. 체크박스 삽입 버튼
              _buildToolbarButton(
                icon: Icons.check_box_outlined,
                onPressed: _handleCheckboxToggle,
                tooltip: '체크박스 추가',
                isActive: false,
              ),

              // 2. 선택한 글자 굵게 (선택 구간이 모두 굵으면 활성 표시)
              _buildBoldButton(),
              
              // TODO: 아래 기능들은 부분 스타일링 문제로 인해 임시 비활성화
              // 추후 RichText 방식 개선 또는 다른 해결책 구현 시 활성화 예정
              
              /* 
              // 구분선
              _buildDivider(),
              
              // 2. 글자 색상 변경 버튼 (임시 비활성화)
              _buildColorButton(),
              
              // 구분선
              _buildDivider(),
              
              // 3. 폰트 크기 버튼들 (임시 비활성화)
              _buildToolbarButton(
                icon: Icons.remove,
                onPressed: () => _handleFontSizeDecrease(),
                tooltip: '폰트 크기 감소',
                isEnabled: widget.textStyleState.fontSize > 12.0,
              ),
              
              // 현재 폰트 크기 표시
              _buildFontSizeDisplay(),
              
              _buildToolbarButton(
                icon: Icons.add,
                onPressed: () => _handleFontSizeIncrease(),
                tooltip: '폰트 크기 증가',
                isEnabled: widget.textStyleState.fontSize < 24.0,
              ),
              
              // 구분선
              _buildDivider(),
              
              // 4. Bold 토글 버튼 (임시 비활성화)
              _buildToolbarButton(
                icon: Icons.format_bold,
                onPressed: () => _handleBoldToggle(),
                tooltip: 'Bold',
                isActive: widget.textStyleState.isBold,
              ),
              
              // 구분선
              _buildDivider(),
              
              // 5. Underline 토글 버튼 (임시 비활성화)
              _buildToolbarButton(
                icon: Icons.format_underlined,
                onPressed: () => _handleUnderlineToggle(),
                tooltip: 'Underline',
                isActive: widget.textStyleState.isUnderline,
              ),
              */
            ],
          ),
        );
      },
    );
  }

  /// 기본 툴바 버튼 위젯 생성
  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    bool isActive = false,
    bool isEnabled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive 
              ? Theme.of(context).primaryColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive 
              ? Border.all(color: Theme.of(context).primaryColor, width: 1)
              : null,
        ),
        child: IconButton(
          icon: Icon(
            icon,
            size: 20,
            color: isEnabled 
                ? (isActive ? Theme.of(context).primaryColor : Theme.of(context).iconTheme.color)
                : Theme.of(context).disabledColor,
          ),
          onPressed: isEnabled ? onPressed : null,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  /// 글자 색상 변경 버튼 (특별 처리)
  Widget _buildColorButton() {
    return Tooltip(
      message: '글자 색상',
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.palette, size: 20, color: Colors.grey),
              Positioned(
                bottom: 4,
                child: Container(
                  width: 16,
                  height: 3,
                  decoration: BoxDecoration(
                    color: widget.textStyleState.textColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
          onPressed: () => _handleColorChange(),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  /// 현재 폰트 크기 표시 위젯
  Widget _buildFontSizeDisplay() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Text(
          '${widget.textStyleState.fontSize.toInt()}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  /// 구분선 위젯
  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  /// 체크박스 추가 처리 (이모지 추가 방식)
  void _handleCheckboxToggle() {
    if (widget.textController != null) {
      widget.textStyleState.insertCheckbox(widget.textController!);
    }
  }

  /// 폰트 크기 증가 처리
  void _handleFontSizeIncrease() {
    if (widget.textController != null) {
      final selection = widget.textController!.selection;
      if (selection.isValid && !selection.isCollapsed) {
        // 선택된 텍스트가 있으면 해당 영역에만 적용
        widget.textStyleState.increaseFontSize();
        widget.onApplyFontSize?.call(
          selection.start, 
          selection.end, 
          widget.textStyleState.fontSize
        );
      } else {
        // 선택된 텍스트가 없으면 이후 입력될 텍스트에 적용
        widget.textStyleState.increaseFontSize();
      }
    } else {
      widget.textStyleState.increaseFontSize();
    }
  }

  /// 폰트 크기 감소 처리
  void _handleFontSizeDecrease() {
    if (widget.textController != null) {
      final selection = widget.textController!.selection;
      if (selection.isValid && !selection.isCollapsed) {
        // 선택된 텍스트가 있으면 해당 영역에만 적용
        widget.textStyleState.decreaseFontSize();
        widget.onApplyFontSize?.call(
          selection.start, 
          selection.end, 
          widget.textStyleState.fontSize
        );
      } else {
        // 선택된 텍스트가 없으면 이후 입력될 텍스트에 적용
        widget.textStyleState.decreaseFontSize();
      }
    } else {
      widget.textStyleState.decreaseFontSize();
    }
  }

  /// 색상 변경 처리
  void _handleColorChange() {
    if (widget.textController != null) {
      final selection = widget.textController!.selection;
      if (selection.isValid && !selection.isCollapsed) {
        // 선택된 텍스트가 있으면 해당 영역에만 적용
        widget.textStyleState.cycleTextColor();
        widget.onApplyColor?.call(
          selection.start, 
          selection.end, 
          widget.textStyleState.textColor
        );
      } else {
        // 선택된 텍스트가 없으면 이후 입력될 텍스트에 적용
        widget.textStyleState.cycleTextColor();
      }
    } else {
      widget.textStyleState.cycleTextColor();
    }
  }

  /// 선택한 글자 굵게 토글 (선택이 없으면 안내)
  void _handleBoldToggle() {
    final controller = widget.textController;
    if (controller is! ChecklistTextEditingController) return;
    if (!controller.toggleBoldOnSelection()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('굵게 할 글자를 먼저 드래그해서 선택해주세요'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 굵게 버튼 (선택이 바뀔 때마다 활성 상태 갱신)
  Widget _buildBoldButton() {
    final controller = widget.textController;
    if (controller is! ChecklistTextEditingController) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => _buildToolbarButton(
        icon: Icons.format_bold,
        onPressed: _handleBoldToggle,
        tooltip: '굵게',
        isActive: controller.isSelectionBold,
      ),
    );
  }

  /// Underline 토글 처리
  void _handleUnderlineToggle() {
    if (widget.textController != null) {
      final selection = widget.textController!.selection;
      if (selection.isValid && !selection.isCollapsed) {
        // 선택된 텍스트가 있으면 해당 영역에만 적용
        widget.textStyleState.toggleUnderline();
        widget.onApplyUnderline?.call(
          selection.start, 
          selection.end, 
          widget.textStyleState.isUnderline
        );
      } else {
        // 선택된 텍스트가 없으면 이후 입력될 텍스트에 적용
        widget.textStyleState.toggleUnderline();
      }
    } else {
      widget.textStyleState.toggleUnderline();
    }
  }
}