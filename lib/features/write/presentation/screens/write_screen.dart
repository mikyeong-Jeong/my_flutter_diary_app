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
  final _tagController = TextEditingController();
  final _customIconController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  List<String> _selectedTags = [];
  List<String> _selectedIcons = [];
  
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final args = ModalRoute.of(context)?.settings.arguments;
    
    if (args is DiaryEntry) {
      // 기존 엔트리 수정
      if (!_isEditing) {
        _isEditing = true;
        _loadExistingEntry(args);
      }
    } else if (args is DateTime) {
      // 특정 날짜로 새 엔트리 작성
      _selectedDate = args;
    }
  }

  void _loadExistingEntry(DiaryEntry entry) {
    _titleController.text = entry.title;
    _contentController.text = entry.content;
    _selectedDate = DateTime.parse(entry.date);
    _selectedTags = List.from(entry.tags);
    _selectedIcons = List.from(entry.icons);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _customIconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '일기 수정' : '일기 작성'),
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveEntry,
              icon: const Icon(Icons.save, size: 20),
              label: const Text('저장'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
        ],
      ),
      body: Scrollbar(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 선택
              _buildDateSelector(),
              const SizedBox(height: 24),
              
              // 제목 입력
              _buildTitleInput(),
              const SizedBox(height: 24),
              
              // 감정 아이콘 선택
              _buildIconSelector(),
              const SizedBox(height: 24),
              
              // 내용 입력
              _buildContentInput(),
              const SizedBox(height: 24),
              
              // 태그 입력
              _buildTagInput(),
              const SizedBox(height: 24),
              
              // 선택된 태그 표시
              _buildSelectedTags(),
              const SizedBox(height: 100), // 하단 여백
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calendar_today,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: const Text('날짜', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(_selectedDate),
          style: const TextStyle(fontSize: 16),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Theme.of(context).primaryColor,
        ),
        onTap: _selectDate,
      ),
    );
  }

  Widget _buildTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '제목',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: '제목을 입력하세요 (선택사항)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            prefixIcon: const Icon(Icons.title),
          ),
          maxLength: 100,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildIconSelector() {
    final defaultIcons = [
      '😊', '😢', '😡', '😍', '🤔',
      '💪', '📖', '🏃', '🍔', '☕',
      '🌞', '🌙', '⭐', '❤️', '👍',
      '💼', '🎵', '🎬', '🎮', '📱',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '감정 표현',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '최대 5개까지 선택 가능',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).disabledColor,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // 선택된 아이콘들 (크게 표시)
                if (_selectedIcons.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '선택된 감정',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12.0,
                          runSpacing: 12.0,
                          children: _selectedIcons.map((icon) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIcons.remove(icon);
                                });
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    icon,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // 아이콘 선택 그리드
                Text(
                  '감정 선택',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    childAspectRatio: 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: defaultIcons.length,
                  itemBuilder: (context, index) {
                    final icon = defaultIcons[index];
                    final isSelected = _selectedIcons.contains(icon);
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedIcons.remove(icon);
                          } else if (_selectedIcons.length < 5) {
                            _selectedIcons.add(icon);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('최대 5개까지만 선택할 수 있습니다')),
                            );
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).dividerColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                // 커스텀 아이콘 추가
                const SizedBox(height: 20),
                TextField(
                  controller: _customIconController,
                  decoration: InputDecoration(
                    hintText: '이모지를 직접 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.add_reaction),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addCustomIcon,
                    ),
                  ),
                  onSubmitted: (_) => _addCustomIcon(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '내용',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: TextField(
            controller: _contentController,
            decoration: InputDecoration(
              hintText: '오늘 하루는 어땠나요?\n특별한 일이나 느낀 점을 자유롭게 적어보세요. (선택사항)',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
              hintStyle: TextStyle(
                color: Theme.of(context).disabledColor,
                height: 1.5,
              ),
            ),
            maxLines: 12,
            minLines: 8,
            textInputAction: TextInputAction.newline,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagInput() {
    final defaultTags = [
      '자기계발', '운동', '독서', '일기',
      '감정', '회고', '계획', '목표',
      '가족', '친구', '직장', '취미',
      '건강', '여행', '음식', '공부',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '태그',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tagController,
          decoration: InputDecoration(
            hintText: '태그를 입력하고 엔터를 누르세요',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            prefixIcon: const Icon(Icons.tag),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addTag,
            ),
          ),
          onSubmitted: (_) => _addTag(),
        ),
        const SizedBox(height: 16),
        
        // 기본 태그들
        Text(
          '추천 태그',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: defaultTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (!_selectedTags.contains(tag)) {
                      _selectedTags.add(tag);
                    }
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSelectedTags() {
    if (_selectedTags.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선택된 태그',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _selectedTags.map((tag) {
              return Chip(
                label: Text(
                  tag,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _selectedTags.remove(tag);
                  });
                },
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _addCustomIcon() {
    final icon = _customIconController.text.trim();
    if (icon.isNotEmpty && _selectedIcons.length < 5) {
      setState(() {
        if (!_selectedIcons.contains(icon)) {
          _selectedIcons.add(icon);
        }
        _customIconController.clear();
      });
    } else if (_selectedIcons.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최대 5개까지만 선택할 수 있습니다')),
      );
    }
  }

  Future<void> _saveEntry() async {
    // 제목과 내용이 모두 비어있으면 저장하지 않음
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제목 또는 내용 중 하나는 입력해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final entry = DiaryEntry(
        date: dateString,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: _selectedTags,
        icons: _selectedIcons,
        lastModified: DateTime.now().toIso8601String(),
      );

      await context.read<DiaryProvider>().saveEntry(entry);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(_isEditing ? '일기가 수정되었습니다' : '일기가 저장되었습니다'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('저장 중 오류가 발생했습니다: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
