import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/core/models/diary_entry.dart';

void main() {
  group('DiaryEntry 직렬화', () {
    test('할 일(datedNote) 타입이 JSON 왕복 후에도 유지된다', () {
      final entry = DiaryEntry(
        date: '2026-10-03',
        title: '장보기',
        content: '☐ 우유\n☑ 계란',
        type: EntryType.datedNote,
      );

      final restored = DiaryEntry.fromJson(entry.toJson());

      expect(restored.id, entry.id);
      expect(restored.type, EntryType.datedNote);
      expect(restored.date, '2026-10-03');
      expect(restored.content, '☐ 우유\n☑ 계란');
    });

    test('이전 버전의 mood/icons 필드를 moods/customEmojis로 변환한다', () {
      final json = DiaryEntry(title: '제목', content: '내용', date: '2026-01-01').toJson()
        ..['mood'] = '😊';

      expect(DiaryEntry.fromJson(json).moods, ['😊']);

      final jsonWithIcons = DiaryEntry(title: '제목', content: '내용').toJson()
        ..['icons'] = ['⭐'];

      expect(DiaryEntry.fromJson(jsonWithIcons).customEmojis, ['⭐']);
    });
  });

  group('DiaryEntry.compareForList', () {
    DiaryEntry make(EntryType type, String? date, int minute) => DiaryEntry(
          title: '',
          content: '',
          type: type,
          date: date,
          updatedAt: DateTime(2026, 1, 1, 0, minute),
        );

    test('일기 → 할 일 → 일반 메모 순, 날짜/수정시간 최신순으로 정렬한다', () {
      final list = [
        make(EntryType.general, null, 1),
        make(EntryType.datedNote, '2026-01-01', 5),
        make(EntryType.dated, '2026-01-01', 1),
        make(EntryType.datedNote, '2026-01-02', 1),
        make(EntryType.general, null, 9),
        make(EntryType.datedNote, '2026-01-01', 7),
        make(EntryType.dated, '2026-01-03', 1),
      ]..sort(DiaryEntry.compareForList);

      expect(
        list.map((e) => '${e.type.name}:${e.date}:${e.updatedAt.minute}').toList(),
        [
          'dated:2026-01-03:1',
          'dated:2026-01-01:1',
          'datedNote:2026-01-02:1',
          'datedNote:2026-01-01:7',
          'datedNote:2026-01-01:5',
          'general:null:9',
          'general:null:1',
        ],
      );
    });

    test('모든 타입 조합에서 비교 결과가 대칭이다', () {
      final list = [
        make(EntryType.dated, '2026-01-01', 1),
        make(EntryType.datedNote, '2026-01-01', 2),
        make(EntryType.datedNote, '2026-01-01', 3),
        make(EntryType.general, null, 4),
      ];
      for (final a in list) {
        for (final b in list) {
          expect(
            DiaryEntry.compareForList(a, b).sign,
            -DiaryEntry.compareForList(b, a).sign,
          );
        }
      }
    });
  });
}
