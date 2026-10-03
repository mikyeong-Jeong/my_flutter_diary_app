import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/core/models/diary_entry.dart';
import 'package:diary_app/core/utils/bold_utils.dart';
import 'package:diary_app/core/widgets/checklist_text.dart';
import 'package:diary_app/features/write/presentation/widgets/advanced_rich_text_field.dart';
import 'package:diary_app/features/write/presentation/widgets/checklist_text_editing_controller.dart';
import 'package:diary_app/features/write/presentation/widgets/text_style_state.dart';

/// span 트리에서 [text]와 같은 TextSpan의 스타일 찾기
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
  group('BoldUtils', () {
    test('선택 구간 굵게 토글: 일부만 굵으면 전체를 굵게, 전체가 굵으면 해제', () {
      var ranges = BoldUtils.toggle([], 2, 5);
      expect(ranges, [[2, 5]]);

      // 일부 겹치는 구간 → 합쳐서 굵게
      ranges = BoldUtils.toggle(ranges, 4, 8);
      expect(ranges, [[2, 8]]);

      // 이미 굵은 구간 안쪽 해제 → 앞뒤만 남음
      ranges = BoldUtils.toggle(ranges, 4, 6);
      expect(ranges, [[2, 4], [6, 8]]);
    });

    test('글자를 입력/삭제하면 굵게 구간이 따라 움직인다', () {
      const before = '오늘은 중요한 날';
      final ranges = [[4, 7]]; // '중요한'

      // 앞에 입력 → 뒤로 이동
      expect(BoldUtils.adjustForEdit(before, '정말 $before', ranges), [[7, 10]]);
      // 굵은 글자 사이에 입력 → 굵게 이어짐
      expect(BoldUtils.adjustForEdit(before, '오늘은 중요하고한 날', ranges), [[4, 9]]);
      // 굵은 구간 뒤에 입력 → 그대로
      expect(BoldUtils.adjustForEdit(before, '$before!', ranges), [[4, 7]]);
      // 굵은 글자 일부 삭제 → 줄어듦
      expect(BoldUtils.adjustForEdit(before, '오늘은 중한 날', ranges), [[4, 6]]);
      // 굵은 글자 전체 삭제 → 사라짐
      expect(BoldUtils.adjustForEdit(before, '오늘은  날', ranges), isEmpty);
    });

    test('앞뒤 공백을 잘라내면 굵게 구간도 같은 기준으로 이동한다', () {
      final result = BoldUtils.trim('  안녕 세상  ', [[2, 4], [5, 7]]);
      expect(result.text, '안녕 세상');
      expect(result.boldRanges, [[0, 2], [3, 5]]);
    });
  });

  group('본문 컨트롤러 굵게', () {
    testWidgets('선택한 글자만 굵게 표시되고, 입력하면 구간이 따라 움직인다', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
      final context = tester.element(find.byType(SizedBox));

      final controller = ChecklistTextEditingController(text: '오늘은 중요한 날');
      controller.selection = const TextSelection(baseOffset: 4, extentOffset: 7);
      expect(controller.toggleBoldOnSelection(), isTrue);
      expect(controller.boldRanges, [[4, 7]]);
      expect(controller.isSelectionBold, isTrue);

      var span = controller.buildTextSpan(context: context, withComposing: false);
      expect(styleOfSpan(span, '중요한')?.fontWeight, FontWeight.bold);
      expect(styleOfSpan(span, '오늘은 ')?.fontWeight, isNot(FontWeight.bold));

      // 앞에 글자를 입력하면 굵게 구간이 뒤로 이동
      controller.text = '정말 오늘은 중요한 날';
      expect(controller.boldRanges, [[7, 10]]);
      span = controller.buildTextSpan(context: context, withComposing: false);
      expect(styleOfSpan(span, '중요한')?.fontWeight, FontWeight.bold);

      // 선택 없이 토글하면 아무 변화 없음
      controller.selection = const TextSelection.collapsed(offset: 0);
      expect(controller.toggleBoldOnSelection(), isFalse);
      expect(controller.boldRanges, [[7, 10]]);
    });

    testWidgets('글자를 드래그해 선택하면 메뉴에 "굵게"가 나오고, 누르면 굵게 처리된다', (tester) async {
      final controller = ChecklistTextEditingController(text: '오늘은 중요한 날');
      final styleState = TextStyleState();
      addTearDown(styleState.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AdvancedRichTextField(controller: controller, textStyleState: styleState, maxLines: null),
        ),
      ));

      // 드래그로 '중요한' 선택 후 선택 메뉴 표시
      await tester.tap(find.byType(TextField));
      await tester.pump();
      controller.selection = const TextSelection(baseOffset: 4, extentOffset: 7);
      await tester.pump();
      tester.state<EditableTextState>(find.byType(EditableText)).showToolbar();
      await tester.pumpAndSettle();

      expect(find.text('굵게'), findsOneWidget);
      await tester.tap(find.text('굵게'));
      await tester.pumpAndSettle();
      expect(controller.boldRanges, [[4, 7]]);

      // 다시 선택하면 '굵게 해제'
      controller.selection = const TextSelection(baseOffset: 4, extentOffset: 7);
      await tester.pump();
      tester.state<EditableTextState>(find.byType(EditableText)).showToolbar();
      await tester.pumpAndSettle();
      expect(find.text('굵게 해제'), findsOneWidget);
      await tester.tap(find.text('굵게 해제'));
      await tester.pumpAndSettle();
      expect(controller.boldRanges, isEmpty);
    });
  });

  group('저장 및 표시', () {
    test('굵게 구간이 JSON 저장/복원 후에도 유지되고, 예전 데이터는 빈 목록', () {
      final entry = DiaryEntry(title: '제목', content: '오늘은 중요한 날', boldRanges: [[4, 7]]);
      expect(DiaryEntry.fromJson(entry.toJson()).boldRanges, [[4, 7]]);

      final legacyJson = entry.toJson()..remove('boldRanges');
      expect(DiaryEntry.fromJson(legacyJson).boldRanges, isEmpty);
    });

    testWidgets('읽기 화면 텍스트에서 굵게 구간이 굵게 표시된다', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ChecklistText('오늘은 중요한 날', boldRanges: [[4, 7]])),
      ));
      final span = tester
          .widget<RichText>(find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains('중요한'),
          ).first)
          .text;
      expect(styleOfSpan(span, '중요한')?.fontWeight, FontWeight.bold);
      expect(styleOfSpan(span, '오늘은 ')?.fontWeight, isNot(FontWeight.bold));
    });
  });
}
