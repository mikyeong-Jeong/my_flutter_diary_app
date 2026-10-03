import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diary_app/core/models/diary_entry.dart';
import 'package:diary_app/core/providers/diary_provider.dart';
import 'package:diary_app/core/utils/json_utils.dart';
import 'package:diary_app/core/models/calculator_row.dart';
import 'package:diary_app/core/models/calculator_sheet.dart';
import 'package:diary_app/core/services/calculator_storage.dart';

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

  test('백업 파일로 내보낸 뒤 복원해도 한글과 이모지가 깨지지 않는다', () async {
    final provider = await createProvider();
    await provider.addEntry(DiaryEntry(
      date: '2026-10-03',
      title: '한글 제목',
      content: '오늘은 맑음 ☀️\n□ 할 일',
      moods: ['😊'],
      tags: ['일상'],
    ));

    // 설정 화면과 동일한 경로: 내보내기 → UTF-8(BOM) 파일 바이트 → 읽기 → 복원
    final backup = await provider.exportBackup();
    final bytes = JsonUtils.toUtf8Bytes(backup, includeBom: true);
    await provider.deleteAllEntries();
    expect(provider.entries, isEmpty);

    final restoredJson = jsonEncode(JsonUtils.decodeFromBytes(bytes));
    await provider.importBackup(restoredJson);

    final reloaded = await createProvider();
    final entry = reloaded.diaries.single;
    expect(entry.title, '한글 제목');
    expect(entry.content, '오늘은 맑음 ☀️\n□ 할 일');
    expect(entry.moods, ['😊']);
    expect(entry.tags, ['일상']);
  });

  test('백업에 계산기 데이터가 포함되고 복원된다', () async {
    final provider = await createProvider();
    await CalculatorStorage.save([
      CalculatorSheet(
        id: 'c1',
        title: '10월 생활비',
        budget: 300000,
        rows: const [CalculatorRow(id: 'r1', date: '2026-10-03', item: '장보기', amount: 45000)],
      ),
    ]);

    final backup = await provider.exportBackup();
    expect((jsonDecode(backup) as Map)['calculatorSheets'], hasLength(1));

    // 계산기 데이터를 지운 뒤 복원
    await CalculatorStorage.save([]);
    await provider.importBackup(backup);

    final restored = await CalculatorStorage.load();
    expect(restored.single.title, '10월 생활비');
    expect(restored.single.budget, 300000);
    expect(restored.single.rows.single.item, '장보기');
    expect(restored.single.remaining, 255000);
  });

  test('계산기 기능 이전의 백업으로 복원하면 기존 계산기 데이터는 유지된다', () async {
    final provider = await createProvider();
    await CalculatorStorage.save([CalculatorSheet(id: 'c1', title: '유지될 계산')]);

    // calculatorSheets 키가 없는 예전 형식 백업
    final oldBackup = jsonEncode({'entries': [], 'settings': {}, 'version': '2.0'});
    await provider.importBackup(oldBackup);

    expect((await CalculatorStorage.load()).single.title, '유지될 계산');
  });
}
