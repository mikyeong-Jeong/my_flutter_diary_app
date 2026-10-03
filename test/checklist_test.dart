import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diary_app/core/models/diary_entry.dart';
import 'package:diary_app/core/providers/diary_provider.dart';
import 'package:diary_app/core/utils/checklist_utils.dart';
import 'package:diary_app/core/widgets/checklist_text.dart';
import 'package:diary_app/features/read/presentation/screens/dated_note_read_screen.dart';
import 'package:diary_app/features/write/presentation/widgets/checklist_text_editing_controller.dart';

/// RichText 안에서 [text]가 포함된 TextSpan의 스타일을 찾음
/// 본문 텍스트(체크박스 포함)를 그리는 RichText의 span
InlineSpan contentSpan(WidgetTester tester, String containing) {
  return tester
      .widget<RichText>(find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains(containing),
      ).first)
      .text;
}

TextStyle? styleOfSpan(InlineSpan root, String text) {
  TextStyle? found;
  root.visitChildren((span) {
    if (span is TextSpan && span.text == text) {
      found = span.style;
      return false;
    }
    return true;
  });
  return found;
}

void main() {
  group('ChecklistUtils', () {
    test('toggleAt은 체크박스만 토글한다', () {
      expect(ChecklistUtils.toggleAt('☐ 우유', 0), '☑ 우유');
      expect(ChecklistUtils.toggleAt('☑ 우유', 0), '☐ 우유');
      expect(ChecklistUtils.toggleAt('☐ 우유', 2), '☐ 우유');
    });

    test('checkedRanges는 ☑ 뒤부터 사용자가 입력한 줄바꿈 전까지를 반환한다', () {
      const text = '☑ 우유\n☐ 계란\n메모 ☑ 빵 ☐ 잼\n☑ 아주 긴 항목은 화면에서 자동 줄바꿈되어도 끝까지';
      final ranges = ChecklistUtils.checkedRanges(text);
      expect(
        ranges.map((r) => text.substring(r[0], r[1])).toList(),
        [' 우유', ' 빵 ☐ 잼', ' 아주 긴 항목은 화면에서 자동 줄바꿈되어도 끝까지'],
      );
    });
  });

  group('체크박스 전용 기호', () {
    test('직접 입력한 일반 네모 기호(□/■)는 체크박스로 인식하지 않는다', () {
      expect(ChecklistUtils.isCheckbox('\u25A1'), isFalse); // □
      expect(ChecklistUtils.isCheckbox('\u25A0'), isFalse); // ■
      expect(ChecklistUtils.toggleAt('\u25A1 네모 기호', 0), '\u25A1 네모 기호');
      expect(ChecklistUtils.checkedRanges('\u25A0 강조 표시'), isEmpty);
    });

    test('이전 버전 체크박스(줄 맨 앞 □/■)만 전용 기호로 변환한다', () {
      const legacy = '\u25A1 우유\n  \u25A0 계란\n가격표 \u25A1 \u25A0 표시\n\u25A1빵';
      expect(
        ChecklistUtils.migrateLegacy(legacy),
        '☐ 우유\n  ☑ 계란\n가격표 \u25A1 \u25A0 표시\n\u25A1빵',
      );
    });

    test('예전 데이터를 불러오면 체크박스가 변환되고 수정 시간은 유지된다', () {
      final updatedAt = DateTime(2026, 9, 1, 8, 0);
      final legacyJson = DiaryEntry(
        title: '장보기',
        content: '\u25A1 우유\n\u25A0 계란',
        type: EntryType.datedNote,
        date: '2026-09-01',
        updatedAt: updatedAt,
      ).toJson();

      final entry = DiaryEntry.fromJson(legacyJson);
      expect(entry.content, '☐ 우유\n☑ 계란');
      expect(entry.updatedAt, updatedAt);
      expect(ChecklistUtils.checkedRanges(entry.content), isNotEmpty);
    });
  });

  group('ChecklistText (읽기 전용)', () {
    testWidgets('체크박스를 탭하면 토글된 텍스트를 전달한다', (tester) async {
      String? changed;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChecklistText('☐ 우유\n☑ 계란', onChanged: (v) => changed = v),
        ),
      ));

      // 체크박스는 아이콘으로 그려지며, 아이콘을 탭하면 토글
      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      expect(changed, '☑ 우유\n☑ 계란');
    });

    testWidgets('일반 네모 기호(□/■)는 탭해도 바뀌지 않고 취소선도 없다', (tester) async {
      String? changed;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChecklistText('\u25A0 강조 문장\n☐ 할 일', onChanged: (v) => changed = v),
        ),
      ));

      await tester.tapOnText(find.textRange.ofSubstring('\u25A0'));
      expect(changed, isNull);
      final span = contentSpan(tester, '할 일');
      expect(styleOfSpan(span, '\u25A0 강조 문장\n')?.decoration, isNot(TextDecoration.lineThrough));
    });

    testWidgets('체크된 항목에만 취소선을 그린다', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ChecklistText('☐ 우유\n☑ 계란')),
      ));

      final span = contentSpan(tester, '우유');
      expect(styleOfSpan(span, ' 계란')?.decoration, TextDecoration.lineThrough);
      expect(styleOfSpan(span, ' 우유\n')?.decoration, isNot(TextDecoration.lineThrough));
      // ☐/☑ 문자는 글자(이모지)로 그리지 않고 같은 디자인의 아이콘으로 표시
      expect(span.toPlainText().contains('☑'), isFalse);
      expect(span.toPlainText().contains('☐'), isFalse);
      // 아이콘 색은 본문과 같은 글자색 (테마 강조색으로 바뀌지 않음)
      final baseColor = styleOfSpan(span, ' 우유\n')?.color;
      expect(tester.widget<Icon>(find.byIcon(Icons.check_box_outline_blank)).color, baseColor);
      expect(tester.widget<Icon>(find.byIcon(Icons.check_box)).color, baseColor);
    });
  });

  group('ChecklistTextEditingController (편집)', () {
    testWidgets('체크된 항목에 취소선을 그리고, 한글 조합 구간 밑줄을 유지한다', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
      final context = tester.element(find.byType(SizedBox));

      final controller = ChecklistTextEditingController(text: '☑ 완료\n☐ 할 일');
      var span = controller.buildTextSpan(context: context, withComposing: true);
      expect(styleOfSpan(span, ' 완료')?.decoration, TextDecoration.lineThrough);

      // '할'을 조합 중인 상태
      controller.value = controller.value.copyWith(
        composing: const TextRange(start: 7, end: 8),
      );
      span = controller.buildTextSpan(context: context, withComposing: true);
      expect(styleOfSpan(span, '할')?.decoration, TextDecoration.underline);
      expect(styleOfSpan(span, ' 완료')?.decoration, TextDecoration.lineThrough);
      // 체크박스 문자 1개 = 아이콘 1개 (텍스트 길이/커서 위치 유지)
      expect(span.toPlainText().length, controller.text.length);
    });

    testWidgets('입력칸에서도 체크박스가 아이콘으로 그려진다', (tester) async {
      final controller = ChecklistTextEditingController(text: '☑ 완료\n☐ 할 일');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: TextField(controller: controller, maxLines: null)),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.check_box), findsOneWidget);
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);

      // 입력해도 오류 없이 동작
      await tester.enterText(find.byType(TextField), '☑ 완료\n☐ 할 일\n추가');
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('할 일 읽기 화면', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('checklist_test');
      SharedPreferences.setMockInitialValues({});
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => tempDir.path,
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('home_widget'),
        (call) async => true,
      );
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    testWidgets('읽기 화면에서 체크박스를 탭하면 체크되고 저장되며, 수정 시간은 유지된다', (tester) async {
      final provider = DiaryProvider();
      final note = DiaryEntry(
        date: '2026-10-03',
        title: '장보기',
        content: '☐ 우유\n☐ 계란',
        type: EntryType.datedNote,
        updatedAt: DateTime(2026, 10, 1, 9, 0),
      );
      await tester.runAsync(() async {
        await provider.loadEntries();
        await provider.addEntry(note);
      });

      await tester.pumpWidget(ChangeNotifierProvider<DiaryProvider>.value(
        value: provider,
        child: MaterialApp(
          // 실제 앱과 동일한 한국어 로케일 (날짜 표시용)
          locale: const Locale('ko', 'KR'),
          supportedLocales: const [Locale('ko', 'KR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          onGenerateRoute: (settings) => MaterialPageRoute(
            settings: RouteSettings(name: '/dated_note', arguments: note),
            builder: (_) => const DatedNoteReadScreen(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // 첫 번째 체크박스 탭
      await tester.tap(find.byIcon(Icons.check_box_outline_blank).first);
      // 저장(파일 쓰기)이 끝날 때까지 실제 시간을 흘려보내며 대기
      for (int i = 0; i < 10 && provider.datedNotes.single.content.startsWith('☐'); i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(provider.datedNotes.single.content, '☑ 우유\n☐ 계란');
      // 체크해도 수정 시간은 바뀌지 않음
      expect(provider.datedNotes.single.updatedAt, DateTime(2026, 10, 1, 9, 0));
      final span = contentSpan(tester, '우유');
      expect(styleOfSpan(span, ' 우유')?.decoration, TextDecoration.lineThrough);

      // 다시 불러와도 체크 상태가 유지됨
      final reloaded = DiaryProvider();
      await tester.runAsync(() => reloaded.loadEntries());
      expect(reloaded.datedNotes.single.content, '☑ 우유\n☐ 계란');
      expect(reloaded.datedNotes.single.updatedAt, DateTime(2026, 10, 1, 9, 0));
    });
  });
}
