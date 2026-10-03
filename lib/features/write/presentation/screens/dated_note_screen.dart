import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/diary_entry.dart';
import '../../../../core/providers/diary_provider.dart';
import '../../../../core/utils/bold_utils.dart';
import '../widgets/toolbar_overlay_manager.dart';
import '../widgets/advanced_rich_text_field.dart';
import '../widgets/checklist_text_editing_controller.dart';

/// 할 일 작성 화면
/// 
/// 특정 날짜에 여러 개의 할 일을 작성할 수 있는 화면입니다.
/// 일반 메모와 달리 날짜 선택 기능이 있고, 이모지/태그 기능은 제외됩니다.
class DatedNoteScreen extends StatefulWidget {
  final DiaryEntry? entry;

  const DatedNoteScreen({super.key, this.entry});

  @override
  State<DatedNoteScreen> createState() => _DatedNoteScreenState();
}

class _DatedNoteScreenState extends State<DatedNoteScreen> with WidgetsBindingObserver, KeyboardAwareToolbarMixin {
  late TextEditingController _titleController;
  late ChecklistTextEditingController _contentController;
  late DateTime _selectedDate;
  
  // 포커스 노드들
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  
  // Rich Text 필드에 대한 GlobalKey
  final _richTextFieldKey = GlobalKey<AdvancedRichTextFieldState>();
  bool _isEditing = false;
  late DiaryEntry _entry;

  @override
  void initState() {
    super.initState();
    
    
    // 전달받은 entry 또는 새 entry 설정
    if (widget.entry != null) {
      _entry = widget.entry!;
      // id는 항상 자동 생성되므로, 이미 저장된 항목인지로 수정 여부를 판단
      _isEditing = context
          .read<DiaryProvider>()
          .entries
          .any((e) => e.id == _entry.id);
      _titleController = TextEditingController(text: _entry.title);
      _contentController = ChecklistTextEditingController(
        text: _entry.content,
        boldRanges: _entry.boldRanges,
      );
      _selectedDate = _entry.date != null ? DateTime.parse(_entry.date!) : DateTime.now();
    } else {
      _entry = DiaryEntry(
        date: _formatDate(DateTime.now()),
        title: '',
        content: '',
        type: EntryType.datedNote,
      );
      _titleController = TextEditingController();
      _contentController = ChecklistTextEditingController();
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  /// 날짜 선택 다이얼로그 표시
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // 현재 작성 중인 할 일의 날짜만 업데이트
        _entry = _entry.copyWith(date: _formatDate(picked));
      });
      
      // 날짜 변경 피드백
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('날짜가 ${DateFormat('yyyy년 M월 d일').format(picked)}로 변경되었습니다'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  /// 할 일 저장
  Future<void> _saveEntry() async {
    // 앞뒤 공백을 잘라내면서 굵게 범위도 같은 기준으로 이동
    final trimmedContent = BoldUtils.trim(_contentController.text, _contentController.boldRanges);
    final content = trimmedContent.text;
    
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('내용을 입력해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);

    try {
      // 할 일 저장 - 중복 제한 제거됨
      final currentDate = _formatDate(_selectedDate);

      final updatedEntry = _entry.copyWith(
        title: _titleController.text.trim(),
        content: content,
        boldRanges: trimmedContent.boldRanges,
        date: currentDate,
        moods: [], // 할 일이지만 이모지 기능 제외
        customEmojis: [], // 할 일이지만 이모지 기능 제외
        tags: [], // 할 일이지만 태그 기능 제외
        type: EntryType.datedNote, // 반드시 할 일 타입으로 설정
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await diaryProvider.updateEntry(updatedEntry);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('할 일이 수정되었습니다 (${DateFormat('M월 d일').format(_selectedDate)})'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await diaryProvider.addEntry(updatedEntry);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('할 일이 작성되었습니다 (${DateFormat('M월 d일').format(_selectedDate)})'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      // 약간의 지연 후 Navigator.pop 실행 (UI 업데이트 시간 확보)
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 50));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 할 일 삭제
  void _deleteEntry() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할 일 삭제'),
        content: const Text('이 할 일을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              context.read<DiaryProvider>().deleteEntry(_entry.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '할 일 수정' : '새 할 일'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteEntry,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveEntry,
            tooltip: '저장',
          ),
        ],
      ),
      body: SafeArea(
        // 하단 시스템 내비게이션 바(edge-to-edge)에 내용이 가려지지 않도록
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 날짜 선택 영역
              Container(
                key: ValueKey(_selectedDate),
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).primaryColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(_selectedDate),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.edit, size: 16, color: Theme.of(context).primaryColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 제목 입력
              TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                decoration: InputDecoration(
                  hintText: '제목 (선택사항)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                style: Theme.of(context).textTheme.titleLarge,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // 내용 입력
              AdvancedRichTextField(
                key: _richTextFieldKey,
                controller: _contentController,
                focusNode: _contentFocusNode,
                textStyleState: textStyleState,
                decoration: InputDecoration(
                  hintText: '내용을 입력하세요...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                minLines: 15,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // 생성/수정 정보 표시
              if (_isEditing)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.create, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '생성: ${_entry.formattedCreatedAt}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.update, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '수정: ${_entry.formattedUpdatedAt}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// KeyboardAwareToolbarMixin에서 요구하는 현재 활성화된 TextEditingController
  @override
  TextEditingController? get currentTextController {
    // 툴바(체크박스)는 본문 전용 - 제목 등 다른 입력칸에 삽입되지 않도록 항상 본문 컨트롤러 반환
    return _contentController;
  }

  /// 현재 활성화된 Rich Text Field의 GlobalKey 반환
  @override
  GlobalKey<AdvancedRichTextFieldState>? get currentRichTextFieldKey {
    // 내용 필드에 포커스가 있을 때만 Rich Text Field Key 반환
    if (_contentFocusNode.hasFocus) {
      return _richTextFieldKey;
    }
    return null;
  }
}