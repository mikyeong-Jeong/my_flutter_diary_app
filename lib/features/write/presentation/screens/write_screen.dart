import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/diary_provider.dart';
import '../../../../core/models/diary_entry.dart';

class WriteScreen extends StatefulWidget {
  const WriteScreen({super.key});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedMood = '';
  late DiaryEntry _entry;
  bool _isEditing = false;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is DiaryEntry) {
      _entry = arguments;
      _isEditing = _entry.content.isNotEmpty;
      
      if (_isEditing) {
        _titleController.text = _entry.title;
        _contentController.text = _entry.content;
        _selectedMood = _entry.mood;
      }
    } else {
      _entry = DiaryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now().toIso8601String(),
        title: '',
        content: '',
        mood: '',
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveDiary() {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('일기 내용을 입력해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final updatedEntry = _entry.copyWith(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      mood: _selectedMood,
      updatedAt: DateTime.now(),
    );

    final diaryProvider = context.read<DiaryProvider>();
    
    if (_isEditing) {
      diaryProvider.updateEntry(updatedEntry);
    } else {
      diaryProvider.addEntry(updatedEntry);
    }

    Navigator.pop(context);
  }

  void _deleteDiary() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일기 삭제'),
        content: const Text('이 일기를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              context.read<DiaryProvider>().deleteEntry(_entry.id);
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context); // 화면 닫기
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '일기 수정' : '일기 작성'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 표시
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(
                      _entry.date != null 
                        ? DateTime.parse(_entry.date!) 
                        : DateTime.now()
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // 기분 선택
            const Text(
              '오늘의 기분',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _moods.map((mood) {
                final isSelected = _selectedMood == mood['emoji'];
                return ChoiceChip(
                  label: Text(
                    '${mood['emoji']} ${mood['label']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMood = selected ? mood['emoji']! : '';
                    });
                  },
                  selectedColor: Theme.of(context).primaryColor,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // 제목 입력
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '오늘의 일기 제목을 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            
            // 내용 입력
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '내용',
                hintText: '오늘 하루는 어떠셨나요?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: null,
              minLines: 10,
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
      ),
    );
  }
}
