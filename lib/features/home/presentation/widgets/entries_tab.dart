import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/diary_provider.dart';

class EntriesTab extends StatelessWidget {
  const EntriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DiaryProvider>(
      builder: (context, diaryProvider, child) {
        final entries = diaryProvider.diaries;

        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '작성된 일기가 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '첫 번째 일기를 작성해보세요',
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
          padding: const EdgeInsets.all(16.0),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              // 메모·할 일 탭과 동일한 테두리 윤곽선
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/read', arguments: entry);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 날짜와 이모지
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.formattedDate,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (entry.allEmojis.isNotEmpty)
                            Wrap(
                              spacing: 4,
                              children: entry.allEmojis
                                  .map<Widget>((emoji) => Text(emoji, style: const TextStyle(fontSize: 20)))
                                  .toList(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 목록에는 제목만 표시 (내용은 일기를 열어서 확인)
                      Text(
                        entry.title.isNotEmpty ? entry.title : '제목 없음',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: entry.title.isNotEmpty ? null : Colors.grey[600],
                        ),
                      ),
                      // 태그
                      if (entry.tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: entry.tags
                              .map<Widget>((tag) => Chip(
                                    label: Text(tag, style: const TextStyle(fontSize: 12)),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // 수정 시간
                      Text(
                        '최근 수정: ${entry.formattedUpdatedAt}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
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
