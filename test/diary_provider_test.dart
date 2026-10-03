import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diary_app/core/models/diary_entry.dart';
import 'package:diary_app/core/providers/diary_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('diary_test');
    SharedPreferences.setMockInitialValues({});

    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // 파일 저장 경로를 임시 디렉토리로 대체
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );
    // 홈 위젯 플러그인 호출은 성공으로 처리
    messenger.setMockMethodCallHandler(
      const MethodChannel('home_widget'),
      (call) async => true,
    );
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<DiaryProvider> createProvider() async {
    final provider = DiaryProvider();
    await provider.loadEntries();
    return provider;
  }

  test('일기·할 일·메모가 타입별로 구분되고 다시 불러와도 유지된다', () async {
    final provider = await createProvider();

    await provider.addEntry(DiaryEntry(date: '2026-10-03', title: '일기', content: '내용'));
    await provider.addEntry(DiaryEntry(
      date: '2026-10-03',
      title: '할 일 1',
      content: '□ 청소',
      type: EntryType.datedNote,
    ));
    await provider.addEntry(DiaryEntry(
      date: '2026-10-03',
      title: '할 일 2',
      content: '□ 빨래',
      type: EntryType.datedNote,
    ));
    await provider.addEntry(DiaryEntry(title: '메모', content: '내용', type: EntryType.general));

    expect(provider.diaries.length, 1);
    expect(provider.datedNotes.length, 2);
    expect(provider.generalNotes.length, 1);
    expect(provider.getDatedNotesForDate(DateTime(2026, 10, 3)).length, 2);
    expect(provider.getDatedNotesForDate(DateTime(2026, 10, 4)), isEmpty);

    // 새 Provider로 다시 불러와도 같은 데이터가 유지되어야 함
    final reloaded = await createProvider();
    expect(reloaded.diaries.length, 1);
    expect(reloaded.datedNotes.length, 2);
    expect(reloaded.generalNotes.length, 1);
  });

  test('updateEntry는 기존 항목을 수정하고, 없는 항목이면 새로 추가한다', () async {
    final provider = await createProvider();
    final note = DiaryEntry(
      date: '2026-10-03',
      title: '할 일',
      content: '□ 운동',
      type: EntryType.datedNote,
    );

    await provider.updateEntry(note);
    expect(provider.datedNotes.single.content, '□ 운동');

    await provider.updateEntry(note.copyWith(content: '■ 운동'));
    expect(provider.datedNotes.single.content, '■ 운동');
  });

  test('deleteEntry로 항목을 삭제한다', () async {
    final provider = await createProvider();
    final note = DiaryEntry(
      date: '2026-10-03',
      title: '할 일',
      content: '□ 독서',
      type: EntryType.datedNote,
    );
    await provider.addEntry(note);

    await provider.deleteEntry(note.id);

    expect(provider.datedNotes, isEmpty);
    expect((await createProvider()).datedNotes, isEmpty);
  });
}
