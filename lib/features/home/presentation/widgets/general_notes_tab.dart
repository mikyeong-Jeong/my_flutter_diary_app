import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/diary_provider.dart';

/// 일반 메모 탭 위젯
/// 
/// 날짜와 무관한 일반 메모들을 보여주는 탭입니다.
/// 특정 메모 ID로 스크롤 및 선택 기능을 지원합니다.
class GeneralNotesTab extends StatefulWidget {
  final String? targetMemoId; // 특정 메모로 스크롤할 ID
  
  const GeneralNotesTab({super.key, this.targetMemoId});

  @override
  State<GeneralNotesTab> createState() => _GeneralNotesTabState();
}

class _GeneralNotesTabState extends State<GeneralNotesTab> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedMemoId; // 현재 선택된 메모 ID
  
  @override
  void initState() {
    super.initState();
    // 특정 메모가 지정되었다면 해당 메모로 스크롤
    if (widget.targetMemoId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToMemo(widget.targetMemoId!);
      });
    }
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  /// 특정 메모로 스크롤하고 하이라이트
  void _scrollToMemo(String memoId) {
    final diaryProvider = context.read<DiaryProvider>();
    final notes = diaryProvider.generalNotes;
    
    // 메모 인덱스 찾기
    final index = notes.indexWhere((note) => note.id == memoId);
    if (index != -1) {
      setState(() {
        _selectedMemoId = memoId;
      });
      
      // 스크롤 위치 계산 (각 카드의 높이를 고려)
      // 약간의 지연 후 스크롤하여 렌더링 완료 확보
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          final position = index * 150.0; // 대략적인 카드 높이
          _scrollController.animateTo(
            position,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
      
      // 3초 후 하이라이트 제거
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _selectedMemoId = null;
          });
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<DiaryProvider>(
      builder: (context, diaryProvider, child) {
        final notes = diaryProvider.generalNotes;

        if (notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '작성된 메모가 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '첫 번째 메모를 작성해보세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            final isSelected = note.id == _selectedMemoId;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                  width: isSelected ? 2 : 0,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ] : null,
              ),
              child: Card(
                margin: EdgeInsets.zero,
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/read', arguments: note);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목과 이모지
                      Row(
                        children: [
                          Expanded(
                            child: note.title.isNotEmpty
                                ? Text(
                                    note.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      if (note.title.isNotEmpty) const SizedBox(height: 8),
                      // 전체 내용 표시
                      if (note.content.isNotEmpty) ...[
                        Text(
                          note.content,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                      ],
                      // 생성/수정 시간
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '생성: ${note.formattedCreatedAt}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (note.createdAt != note.updatedAt)
                            Text(
                              '수정: ${note.formattedUpdatedAt}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
