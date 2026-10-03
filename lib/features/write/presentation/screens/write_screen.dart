import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/diary_provider.dart';
import '../../../../core/models/diary_entry.dart';
import '../../../../core/utils/text_utils.dart';
import '../widgets/toolbar_overlay_manager.dart';
import '../widgets/advanced_rich_text_field.dart';
import '../widgets/checklist_text_editing_controller.dart';

class WriteScreen extends StatefulWidget {
  const WriteScreen({super.key});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> with WidgetsBindingObserver, KeyboardAwareToolbarMixin {
  final _titleController = TextEditingController();
  // 체크된 항목(☑)에 취소선을 표시하는 본문 컨트롤러
  final _contentController = ChecklistTextEditingController();
  final _customTagController = TextEditingController();
  final _customEmojiController = TextEditingController();
  
  // 포커스 노드들
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  
  // Rich Text 필드에 대한 GlobalKey
  final _richTextFieldKey = GlobalKey<AdvancedRichTextFieldState>();
  
  List<String> _selectedMoods = [];
  List<String> _selectedCustomEmojis = [];
  List<String> _selectedTags = [];
  late DiaryEntry _entry;
  bool _isEditing = false;
  DateTime _selectedDate = DateTime.now();
  bool _isInitialized = false; // 초기화 상태 추적

  // 기본 기분 이모지 (8개로 축소)
  final List<Map<String, String>> _moods = [
    {'emoji': '😊', 'label': '행복'},
    {'emoji': '😔', 'label': '슬픔'},
    {'emoji': '😡', 'label': '화남'},
    {'emoji': '😌', 'label': '평온'},
    {'emoji': '😴', 'label': '피곤'},
    {'emoji': '🤔', 'label': '고민'},
    {'emoji': '😍', 'label': '사랑'},
    {'emoji': '😎', 'label': '자신감'},
  ];

  // 기본 제공 태그 (10개로 축소)
  final List<String> _defaultTags = [
    '일상', '기분', '날씨', '음식', '여행', 
    '친구', '가족', '일', '공부', '운동'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 한 번만 초기화 - 중복 초기화 방지
    // 화면 이동 시 arguments를 통해 데이터를 받아 초기화
    if (!_isInitialized) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      
      // 위젯에서 전달된 메모 ID 처리
      if (arguments is Map<String, dynamic>) {
        final editMemoId = arguments['editMemoId'];
        if (editMemoId != null) {
          // 메모 ID로 해당 메모 찾기
          final provider = context.read<DiaryProvider>();
          final memo = provider.entries.firstWhere(
            (entry) => entry.id == editMemoId,
            orElse: () => DiaryEntry(
              date: DateTime.now().toIso8601String(),
              title: '',
              content: '',
              type: EntryType.dated,
            ),
          );
          _entry = memo;
          _isEditing = true;
          _titleController.text = _entry.title;
          _contentController.text = _entry.content;
          _selectedMoods = List.from(_entry.moods);
          _selectedCustomEmojis = List.from(_entry.customEmojis);
          _selectedTags = List.from(_entry.tags);
          if (_entry.date != null) {
            _selectedDate = DateTime.parse(_entry.date!);
          }
        }
      } else if (arguments is DiaryEntry) {
        _entry = arguments;
        _isEditing = _entry.content.isNotEmpty || _entry.title.isNotEmpty;
        
        if (_entry.date != null) {
          _selectedDate = DateTime.parse(_entry.date!);
        }
        
        if (_isEditing) {
          _titleController.text = _entry.title;
          _contentController.text = _entry.content;
          _selectedMoods = List.from(_entry.moods);
          _selectedCustomEmojis = List.from(_entry.customEmojis);
          _selectedTags = List.from(_entry.tags);
        }
      } else {
        _entry = DiaryEntry(
          date: DateTime.now().toIso8601String(),
          title: '',
          content: '',
          type: EntryType.dated,
        );
        _selectedDate = DateTime.now();
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _customTagController.dispose();
    _customEmojiController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _saveDiary() async {
    
    // 날짜별 메모의 경우 날짜 변경 시 중복 체크
    if (_entry.type == EntryType.dated) {
      final currentDate = _formatDate(_selectedDate);
      
      // 날짜가 변경되었거나 새 메모인 경우 중복 체크
      if (!_isEditing || (_isEditing && _entry.date != currentDate)) {
        final existingEntry = context.read<DiaryProvider>().getEntryForDate(_selectedDate);
        
        // 기존 메모 편집 시 자기 자신은 제외
        if (existingEntry != null && existingEntry.id != _entry.id) {
          final shouldOverwrite = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('이미 작성된 일기가 있습니다'),
              content: Text('${DateFormat('yyyy년 M월 d일').format(_selectedDate)}에 이미 일기가 있습니다.\n덮어쓰시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('덮어쓰기'),
                ),
              ],
            ),
          );
          
          if (shouldOverwrite != true) return;
          
          // 기존 엔트리를 삭제
          await context.read<DiaryProvider>().deleteEntry(existingEntry.id);
        }
      }
    }

    final newDate = _entry.type == EntryType.dated ? _formatDate(_selectedDate) : _entry.date;

    // 텍스트 정리 (유효하지 않은 문자 제거)
    final cleanTitle = TextUtils.sanitizeText(_titleController.text.trim());
    final cleanContent = TextUtils.sanitizeText(_contentController.text.trim());
    
    // Content sanitization completed
    
    final updatedEntry = _entry.copyWith(
      title: cleanTitle,
      content: cleanContent,
      date: newDate,
      moods: _entry.type == EntryType.general ? [] : _selectedMoods,
      customEmojis: _entry.type == EntryType.general ? [] : _selectedCustomEmojis,
      tags: _entry.type == EntryType.general ? [] : _selectedTags,
      updatedAt: DateTime.now(),
    );

    // Entry updated with new values

    final diaryProvider = context.read<DiaryProvider>();
    
    try {
      if (_isEditing) {
        await diaryProvider.updateEntry(updatedEntry);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장되었습니다 (${DateFormat('M월 d일').format(_selectedDate)})'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await diaryProvider.addEntry(updatedEntry);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('작성되었습니다 (${DateFormat('M월 d일').format(_selectedDate)})'),
            backgroundColor: Colors.green,
          ),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _deleteDiary() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_entry.type == EntryType.dated ? '일기 삭제' : '메모 삭제'),
        content: Text(_entry.type == EntryType.dated ? '이 일기를 삭제하시겠습니까?' : '이 메모를 삭제하시겠습니까?'),
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

  void _addCustomTag() {
    final tag = _customTagController.text.trim();
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _customTagController.clear();
      });
    }
  }

  void _addCustomEmoji() {
    final emoji = _customEmojiController.text.trim();
    if (emoji.isNotEmpty && !_selectedCustomEmojis.contains(emoji)) {
      setState(() {
        _selectedCustomEmojis.add(emoji);
        _customEmojiController.clear();
      });
    }
  }

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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isGeneral = _entry.type == EntryType.general;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing 
          ? (isGeneral ? '메모 수정' : '일기 수정')
          : (isGeneral ? '메모 작성' : '일기 작성')
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteDiary,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveDiary,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 날짜/타입 표시
            Container(
              key: ValueKey(_selectedDate), // 날짜가 변경되면 위젯 재생성
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(isGeneral ? Icons.note : Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  if (isGeneral)
                    const Text(
                      '일반 메모',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    )
                  else
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
                labelText: '제목${isGeneral ? ' (선택사항)' : ''}',
                hintText: isGeneral ? '메모 제목을 입력하세요' : '오늘의 일기 제목을 입력하세요',
                border: const OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),

            // 내용 입력 (자동 높이 조정)
            Container(
              constraints: const BoxConstraints(
                minHeight: 300, // 최소 높이 300px로 증가
              ),
              child: AdvancedRichTextField(
                key: _richTextFieldKey,
                controller: _contentController,
                focusNode: _contentFocusNode,
                textStyleState: textStyleState,
                decoration: InputDecoration(
                  labelText: '내용${isGeneral ? ' (선택사항)' : ''}',
                  hintText: isGeneral ? '메모 내용을 입력하세요' : '오늘 하루는 어떠셨나요?',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null, // 무제한 라인
                minLines: 12, // 최소 12라인으로 증가
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
            ),
            const SizedBox(height: 24),

            // 날짜별 메모에만 기분 선택 표시
            if (!isGeneral) ...[
              const Text('오늘의 기분 (다중 선택 가능)', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // 기본 이모지를 항상 100% 보이도록 수정
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _moods.map((mood) {
                  final isSelected = _selectedMoods.contains(mood['emoji']);
                  return FilterChip(
                    label: Text('${mood['emoji']} ${mood['label']}',
                      style: TextStyle(fontSize: 14, color: isSelected ? Colors.white : null)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedMoods.add(mood['emoji']!);
                        } else {
                          _selectedMoods.remove(mood['emoji']);
                        }
                      });
                    },
                    selectedColor: Theme.of(context).primaryColor,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              // 사용자 지정 이모지 입력
              const Text('사용자 지정 이모지', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customEmojiController,
                      decoration: const InputDecoration(
                        hintText: '이모지 입력 (예: 😄)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addCustomEmoji(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addCustomEmoji,
                    child: const Text('추가'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // 선택된 사용자 지정 이모지 표시
              if (_selectedCustomEmojis.isNotEmpty) ...[
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _selectedCustomEmojis.map((emoji) {
                    return Chip(
                      label: Text(emoji, style: const TextStyle(fontSize: 18)),
                      onDeleted: () {
                        setState(() {
                          _selectedCustomEmojis.remove(emoji);
                        });
                      },
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              // 태그 섹션
              const Text('태그', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // 기본 제공 태그 (항상 100% 보이도록)
              const Text('기본 태그', 
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _defaultTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                  label: Text(tag, style: const TextStyle(fontSize: 14)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.7),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // 사용자 직접 추가 태그
            const Text('사용자 태그 추가', 
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customTagController,
                    decoration: const InputDecoration(
                      hintText: '새 태그 입력',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addCustomTag(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addCustomTag,
                  child: const Text('추가'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 선택된 태그 표시
            if (_selectedTags.isNotEmpty) ...[
              const Text('선택된 태그', 
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _selectedTags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() {
                        _selectedTags.remove(tag);
                      });
                    },
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            ], // if (!isGeneral) 닫기
            
            // 메타 정보 표시 (일반 메모의 경우)
            if (isGeneral && _isEditing) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('생성: ${_entry.formattedCreatedAt}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    if (_entry.createdAt != _entry.updatedAt)
                      Text('수정: ${_entry.formattedUpdatedAt}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
            ], // Column children 닫기
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
