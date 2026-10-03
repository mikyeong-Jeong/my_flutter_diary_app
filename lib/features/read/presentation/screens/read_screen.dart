import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/diary_entry.dart';
import '../../../../core/providers/diary_provider.dart';
import '../../../../core/widgets/checklist_text.dart';

/// 일기/메모 읽기 전용 화면
/// 
/// 위젯이나 검색 결과에서 일기/메모를 선택했을 때 
/// 먼저 보여지는 읽기 전용 화면입니다.
class ReadScreen extends StatelessWidget {
  const ReadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routeEntry = ModalRoute.of(context)!.settings.arguments as DiaryEntry;
    // 체크박스 토글 등으로 저장된 최신 내용을 표시하기 위해 Provider에서 다시 조회
    final entry = context.watch<DiaryProvider>().entries.firstWhere(
          (e) => e.id == routeEntry.id,
          orElse: () => routeEntry,
        );
    
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.type == EntryType.dated ? '일기 보기' : '메모 보기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // 편집 화면으로 이동
              Navigator.pushReplacementNamed(
                context,
                entry.type == EntryType.datedNote ? '/write/dated_note' : '/write',
                arguments: entry,
              );
            },
            tooltip: '수정하기',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 표시 (날짜별 일기인 경우)
            if (entry.type == EntryType.dated && entry.date != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Text(
                  DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR')
                      .format(DateTime.parse(entry.date!)),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // 제목
            if (entry.title.isNotEmpty) ...[
              Text(
                entry.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // 감정 이모지 (날짜별 일기인 경우)
            if (entry.type == EntryType.dated && 
                (entry.moods.isNotEmpty || entry.customEmojis.isNotEmpty)) ...[
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  ...entry.moods.map((mood) => Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      mood,
                      style: const TextStyle(fontSize: 24),
                    ),
                  )),
                  ...entry.customEmojis.map((emoji) => Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // 태그 (날짜별 일기인 경우)
            if (entry.type == EntryType.dated && entry.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: entry.tags.map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: Theme.of(context).primaryColor,
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            // 본문 내용 (시스템 기본 선택/복사 기능)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              // 체크박스(□/■)를 탭하면 체크/해제되고 바로 저장 (체크된 항목은 취소선)
              child: ChecklistText(
                entry.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
                onChanged: (newContent) {
                  context.read<DiaryProvider>().updateEntry(
                        entry.copyWith(content: newContent),
                      );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 메타 정보
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.create,
                        size: 16,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '작성: ${DateFormat('yyyy-MM-dd HH:mm').format(entry.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.update,
                        size: 16,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '수정: ${DateFormat('yyyy-MM-dd HH:mm').format(entry.updatedAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 편집 화면으로 이동
          Navigator.pushReplacementNamed(
            context,
            '/write',
            arguments: entry,
          );
        },
        child: const Icon(Icons.edit),
        tooltip: '수정하기',
      ),
    );
  }
}