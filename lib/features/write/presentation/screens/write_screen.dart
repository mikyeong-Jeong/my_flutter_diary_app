import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/diary_provider.dart';
import '../../../../core/models/diary_entry.dart';

class WriteScreen extends StatefulWidget {
  final DiaryEntry? entry;
  
  const WriteScreen({super.key, this.entry});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  List<String> _selectedTags = [];
  List<String> _selectedIcons = [];
  
  final List<String> _availableTags = [
    '자기계발', '운동', '독서', '공부', '일상', '감정', '건강', '취미', '가족', '친구'
  ];
  
  final List<String> _availableIcons = [
    '😊', '😢', '😡', '😴', '🤔', '💪', '📖', '🎵', '🍔', '☕',
    '🌟', '❤️', '🔥', '✨', '🎯', '🌈', '🎉', '👍', '💡', '🏃'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _selectedDate = DateTime.parse(widget.entry!.date);
      _selectedTags = List.from(widget.entry!.tags);
      _selectedIcons = List.from(widget.entry!.icons);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry != null ? '기록 수정' : '새 기록 작성'),
        actions: [
          TextButton(
            onPressed: _saveEntry,
            child: const Text('저장'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 선택
              _buildDateSelector(),
              const SizedBox(height: 24),
              
              // 제목 입력
              _buildTitleField(),
              const SizedBox(height: 16),
              
              // 본문 입력
              _buildContentField(),
              const SizedBox(height: 24),
              
              // 감정 아이콘 선택
              _buildIconSelector(),
              const SizedBox(height: 24),
              
              // 태그 선택
              _buildTagSelector(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: const Text('날짜'),
        subtitle: Text(DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(_selectedDate)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked != null) {
            setState(() {
              _selectedDate = picked;
            });
          }
        },
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: '제목',
        hintText: '오늘의 기록을 한 줄로 표현해보세요',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '제목을 입력해주세요';
        }
        return null;
      },
    );
  }

  Widget _buildContentField() {
    return TextFormField(
      controller: _contentController,
      decoration: const InputDecoration(
        labelText: '내용',
        hintText: '오늘 있었던 일이나 느낀 점을 자유롭게 작성해보세요',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 8,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '내용을 입력해주세요';
        }
        return null;
      },
    );
  }

  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '감정 표현 (최대 5개)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // 선택된 아이콘들
        if (_selectedIcons.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Wrap(
              spacing: 8,
              children: _selectedIcons.map((icon) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcons.remove(icon);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        
        const SizedBox(height: 12),
        
        // 아이콘 선택 그리드
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              childAspectRatio: 1,
            ),
            itemCount: _availableIcons.length,
            itemBuilder: (context, index) {
              final icon = _availableIcons[index];
              final isSelected = _selectedIcons.contains(icon);
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedIcons.remove(icon);
                    } else if (_selectedIcons.length < 5) {
                      _selectedIcons.add(icon);
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected 
                        ? Border.all(color: Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // 커스텀 이모지 입력
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: '직접 이모지 입력',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty && _selectedIcons.length < 5) {
                    setState(() {
                      _selectedIcons.add(value);
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '태그',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
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
            );
          }).toList(),
        ),
      ],
    );
  }

  void _saveEntry() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final entry = DiaryEntry(
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      tags: _selectedTags,
      icons: _selectedIcons,
      lastModified: DateTime.now().toIso8601String(),
    );

    if (widget.entry != null) {
      // 수정
      context.read<DiaryProvider>().updateEntry(entry);
    } else {
      // 새로 작성
      context.read<DiaryProvider>().addEntry(entry);
    }

    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.entry != null ? '기록이 수정되었습니다' : '새 기록이 저장되었습니다'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
