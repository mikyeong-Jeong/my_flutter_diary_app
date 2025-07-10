import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/diary_provider.dart';
import '../../../../core/models/diary_entry.dart';

class GeneralNotesTab extends StatelessWidget {
  const GeneralNotesTab({super.key});

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
          padding: const EdgeInsets.all(16.0),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/write', arguments: note);
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
                          if (note.allEmojis.isNotEmpty)
                            Wrap(
                              spacing: 4,
                              children: note.allEmojis
                                  .map<Widget>((emoji) => Text(emoji, style: const TextStyle(fontSize: 20)))
                                  .toList(),
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
                      // 태그
                      if (note.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: note.tags
                              .map<Widget>((tag) => Chip(
                                    label: Text(tag, style: const TextStyle(fontSize: 12)),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList(),
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
            );
          },
        );
      },
    );
  }
}
