import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/diary_provider.dart';
import '../../../../core/models/diary_entry.dart';
import '../../../write/presentation/screens/write_screen.dart';
import '../../../write/presentation/screens/general_note_screen.dart';

class EntriesTab extends StatefulWidget {
  const EntriesTab({super.key});

  @override
  State<EntriesTab> createState() => _EntriesTabState();
}

class _EntriesTabState extends State<EntriesTab> {
  bool _showDatedOnly = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<DiaryProvider>(
      builder: (context, diaryProvider, child) {
        if (diaryProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final entries = _showDatedOnly 
            ? diaryProvider.datedEntries 
            : diaryProvider.entries;

        return Column(
          children: [
            // 필터 토글
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  FilterChip(
                    label: Text('날짜별 메모 (${diaryProvider.totalDatedEntries})'),
                    selected: _showDatedOnly,
                    onSelected: (selected) {
                      setState(() {
                        _showDatedOnly = true;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text('전체 메모 (${diaryProvider.totalEntries})'),
                    selected: !_showDatedOnly,
                    onSelected: (selected) {
                      setState(() {
                        _showDatedOnly = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            // 메모 리스트
            Expanded(
              child: entries.isEmpty 
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () async {
                        await diaryProvider.loadEntries();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return _EntryCard(
                            entry: entry,
                            onTap: () {
                              if (entry.type == EntryType.dated) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WriteScreen(),
                                    settings: RouteSettings(arguments: entry),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GeneralNoteScreen(entry: entry),
                                  ),
                                );
                              }
                            },
                            onDelete: () {
                              _showDeleteDialog(context, entry, diaryProvider);
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showDatedOnly ? Icons.calendar_today : Icons.book_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _showDatedOnly 
                ? '아직 작성된 날짜별 기록이 없습니다'
                : '아직 작성된 메모가 없습니다',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 기록을 작성해보세요!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, DiaryEntry entry, DiaryProvider diaryProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('메모 삭제'),
          content: Text(
            entry.type == EntryType.dated 
                ? '${entry.formattedDate}의 기록을 삭제하시겠습니까?'
                : '"${entry.title.isEmpty ? "제목 없음" : entry.title}" 메모를 삭제하시겠습니까?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await diaryProvider.deleteEntry(entry.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('메모가 삭제되었습니다')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('삭제 실패: $e')),
                    );
                  }
                }
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }
}

class _EntryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EntryCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date/type and icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // 타입 표시
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: entry.type == EntryType.dated 
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                                : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            entry.type == EntryType.dated ? '날짜별' : '일반',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: entry.type == EntryType.dated 
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.type == EntryType.dated 
                              ? entry.formattedDate
                              : DateFormat('yyyy년 M월 d일', 'ko_KR').format(entry.updatedAt),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Emotion icons
                      if (entry.icons.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Row(
                            children: entry.icons.take(3).map((icon) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  icon,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      // More menu
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            onDelete();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline),
                                SizedBox(width: 8),
                                Text('삭제'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Title
              if (entry.title.isNotEmpty) ...[
                Text(
                  entry.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // Content - 전체 내용 표시
              Text(
                entry.content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              // Tags
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: entry.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Last modified time
              Text(
                '마지막 수정: ${_formatDateTime(entry.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('M월 d일 HH:mm', 'ko_KR').format(dateTime);
  }
}
