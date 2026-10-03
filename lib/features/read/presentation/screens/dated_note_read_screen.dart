import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/diary_entry.dart';
import '../../../../core/providers/diary_provider.dart';
import '../../../../core/widgets/checklist_text.dart';

/// 할 일 읽기 전용 화면
/// 
/// 할 일 항목을 선택했을 때 먼저 보여지는 읽기 전용 화면입니다.
/// 편집하려면 우상단 편집 버튼을 클릭해야 합니다.
class DatedNoteReadScreen extends StatelessWidget {
  const DatedNoteReadScreen({super.key});

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
        title: const Text('할 일 보기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // 편집 화면으로 이동
              Navigator.pushReplacementNamed(
                context,
                '/write/dated_note',
                arguments: entry,
              );
            },
            tooltip: '수정하기',
          ),
        ],
      ),
      body: SafeArea(
        // 하단 시스템 내비게이션 바(edge-to-edge)에 내용이 가려지지 않도록
        top: false,
        child: SingleChildScrollView(
          // 오른쪽 아래 수정 버튼(FAB)에 마지막 줄이 가려지지 않도록 하단 여백 추가
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 표시
              if (entry.date != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR')
                            .format(DateTime.parse(entry.date!)),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            
              const SizedBox(height: 16),
            
              // 제목 (있는 경우에만)
              if (entry.title.isNotEmpty) ...[
                Text(
                  entry.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            
              // 할 일 내용 (시스템 기본 선택/복사 기능)
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
                // 체크박스(☐/☑)를 탭하면 체크/해제되고 바로 저장 (체크된 항목은 취소선)
                child: ChecklistText(
                  entry.content,
                  boldRanges: entry.boldRanges,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
                  onChanged: (newContent) {
                    // 체크 표시만 바뀐 것이므로 수정 시간은 그대로 유지
                    // (copyWith는 updatedAt 미지정 시 현재 시간으로 바꿈)
                    context.read<DiaryProvider>().updateEntry(
                          entry.copyWith(content: newContent, updatedAt: entry.updatedAt),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 편집 화면으로 이동
          Navigator.pushReplacementNamed(
            context,
            '/write/dated_note',
            arguments: entry,
          );
        },
        child: const Icon(Icons.edit),
        tooltip: '수정하기',
      ),
    );
  }
}