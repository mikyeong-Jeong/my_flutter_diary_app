import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diary_app/main.dart';
import 'package:diary_app/core/models/calculator_row.dart';
import 'package:diary_app/core/models/calculator_sheet.dart';
import 'package:diary_app/core/services/calculator_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('calculator_test');
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

  /// 계산기 탭(4번)이 선택된 홈 화면으로 앱 시작 (일반 휴대폰 폭 360dp)
  Future<void> pumpCalculatorTab(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp(initialRoutes: [
      RouteSettings(name: '/', arguments: {'tabIndex': 4}),
    ]));
    await tester.pumpAndSettle();
  }

  String totalText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('calculator_total'))).data!;

  Finder itemField(int rowIndex) => find.widgetWithText(TextField, '항목').at(rowIndex);
  // 금액 입력칸 (숫자 키보드, 예산 입력칸 제외)
  Finder amountField(int rowIndex) => find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.keyboardType == TextInputType.number &&
            w.key != const Key('calculator_budget'),
      ).at(rowIndex);
  Finder budgetField() => find.byKey(const Key('calculator_budget'));
  String remainingText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('calculator_remaining'))).data!;

  testWidgets('+ 버튼으로 계산을 추가하고, 목록에는 제목과 합계만 표시된다', (tester) async {
    await pumpCalculatorTab(tester);
    expect(find.text('작성된 계산이 없습니다'), findsOneWidget);

    // 새 계산 추가
    await tester.tap(find.byTooltip('계산 추가'));
    await tester.pumpAndSettle();
    expect(find.text('새 계산'), findsOneWidget);
    expect(totalText(tester), '0원');

    await tester.enterText(find.widgetWithText(TextField, '제목'), '10월 생활비');
    await tester.enterText(itemField(0), '점심');
    await tester.enterText(amountField(0), '12000');
    await tester.pump();
    expect(find.text('12,000'), findsOneWidget); // 천 단위 콤마 자동
    expect(totalText(tester), '12,000원');

    // 행 추가
    await tester.tap(find.text('행 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(itemField(1), '커피');
    await tester.enterText(amountField(1), '4500');
    await tester.pump();
    expect(totalText(tester), '16,500원');

    // 행 추가 후 비워둔 줄은 저장되지 않음
    await tester.tap(find.text('행 추가'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 저장 버튼 없이 뒤로 가기만 해도 자동 저장되어 목록에 표시
    expect(find.byTooltip('저장'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('10월 생활비'), findsOneWidget);
    expect(find.text('지출 16,500원'), findsOneWidget);
    expect(find.text('점심'), findsNothing); // 목록에는 항목이 보이지 않음
    expect(tester.takeException(), isNull);

    // 저장소에도 반영
    final saved = await tester.runAsync(() => CalculatorStorage.load());
    expect(saved!.single.title, '10월 생활비');
    expect(saved.single.rows.length, 2);
    expect(saved.single.total, 16500);
  });

  testWidgets('목록에서 계산을 열어 수정하고 삭제할 수 있다', (tester) async {
    await tester.runAsync(() => CalculatorStorage.save([
          CalculatorSheet(
            id: 's1',
            title: '여행 경비',
            rows: const [
              CalculatorRow(id: 'r1', date: '2026-10-01', item: '숙소', amount: 80000),
              CalculatorRow(id: 'r2', date: '2026-10-02', item: '식비', amount: 25000),
            ],
          ),
        ]));
    await pumpCalculatorTab(tester);
    expect(find.text('지출 105,000원'), findsOneWidget);

    // 열기 → 기존 값 표시
    await tester.tap(find.text('여행 경비'));
    await tester.pumpAndSettle();
    expect(find.text('계산 수정'), findsOneWidget);
    expect(find.text('80,000'), findsOneWidget);
    expect(totalText(tester), '105,000원');

    // 첫 번째 행 삭제 (자동 저장)
    await tester.tap(find.byTooltip('행 삭제').first);
    await tester.pumpAndSettle();
    expect(totalText(tester), '25,000원');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('지출 25,000원'), findsOneWidget);

    // 다시 열어 계산 삭제
    await tester.tap(find.text('여행 경비'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pumpAndSettle();
    expect(find.text('작성된 계산이 없습니다'), findsOneWidget);
  });

  testWidgets('행이 많아지면 총 합계 영역은 하단에 고정되고 나머지만 스크롤된다', (tester) async {
    // 30개 행이 있는 계산
    await tester.runAsync(() => CalculatorStorage.save([
          CalculatorSheet(
            id: 's1',
            title: '긴 목록',
            rows: [
              for (int i = 0; i < 30; i++)
                CalculatorRow(id: 'r$i', date: '2026-10-01', item: '항목$i', amount: 1000),
            ],
          ),
        ]));
    await pumpCalculatorTab(tester);
    await tester.tap(find.text('긴 목록'));
    await tester.pumpAndSettle();

    final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final totalBottom = tester.getBottomLeft(find.byKey(const Key('calculator_total'))).dy;
    expect(totalText(tester), '30,000원');
    expect(totalBottom, lessThanOrEqualTo(screenHeight)); // 처음부터 화면 안에 보임

    // 마지막 '행 추가' 버튼은 처음에는 화면 밖 → 스크롤해서 도달
    await tester.scrollUntilVisible(
      find.text('행 추가').hitTestable(),
      300,
      // 바깥 목록의 Scrollable (입력칸 내부 Scrollable 제외)
      scrollable: find.descendant(
        of: find.byKey(const Key('calculator_scroll')),
        matching: find.byType(Scrollable),
      ).first,
    );
    expect(find.text('행 추가'), findsOneWidget);
    // 제목 입력칸은 함께 스크롤되어 화면 위로 사라짐
    expect(find.widgetWithText(TextField, '긴 목록').hitTestable(), findsNothing);

    // 스크롤 후에도 총 합계는 같은 위치에 고정
    expect(tester.getBottomLeft(find.byKey(const Key('calculator_total'))).dy, totalBottom);
    expect(tester.takeException(), isNull);
  });

  testWidgets('예산을 입력하면 남은 금액(예산 - 지출)이 표시되고, 초과 시 음수로 표시된다', (tester) async {
    await pumpCalculatorTab(tester);
    await tester.tap(find.byTooltip('계산 추가'));
    await tester.pumpAndSettle();

    // 예산 미입력 시 남은 금액은 '-'
    expect(remainingText(tester), '-');

    await tester.enterText(find.widgetWithText(TextField, '제목'), '주간 식비');
    await tester.enterText(budgetField(), '50000');
    await tester.enterText(amountField(0), '16500');
    await tester.pump();
    expect(find.text('50,000'), findsOneWidget);
    expect(totalText(tester), '16,500원');
    expect(remainingText(tester), '33,500원');

    // 예산 초과
    await tester.enterText(amountField(0), '51000');
    await tester.pump();
    expect(remainingText(tester), '-1,000원');
    final remainingWidget = tester.widget<Text>(find.byKey(const Key('calculator_remaining')));
    expect(remainingWidget.style?.color, Colors.red);

    // 목록에 지출/남은 금액 표시, 다시 열면 예산 유지
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('지출 51,000원 · 남은 -1,000원'), findsOneWidget);

    await tester.tap(find.text('주간 식비'));
    await tester.pumpAndSettle();
    expect(find.text('50,000'), findsOneWidget);
    expect(remainingText(tester), '-1,000원');
  });

  testWidgets('입력하는 즉시 자동 저장되고, 빈 계산은 목록에 남지 않는다', (tester) async {
    await pumpCalculatorTab(tester);

    // 아무것도 입력하지 않고 나가면 계산이 만들어지지 않음
    await tester.tap(find.byTooltip('계산 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('작성된 계산이 없습니다'), findsOneWidget);
    expect(await tester.runAsync(() => CalculatorStorage.load()), isEmpty);

    // 입력하면 화면을 나가기 전에도 저장소에 바로 저장됨
    await tester.tap(find.byTooltip('계산 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '제목'), '자동 저장');
    await tester.enterText(amountField(0), '7000');
    await tester.pump();
    var saved = await tester.runAsync(() => CalculatorStorage.load());
    expect(saved!.single.title, '자동 저장');
    expect(saved.single.total, 7000);
    expect(find.byTooltip('삭제'), findsOneWidget); // 저장되면 삭제 버튼 표시

    // 내용을 모두 지우고 나가면 목록에서 제거
    await tester.enterText(find.widgetWithText(TextField, '자동 저장'), '');
    await tester.enterText(amountField(0), '');
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('작성된 계산이 없습니다'), findsOneWidget);
    saved = await tester.runAsync(() => CalculatorStorage.load());
    expect(saved, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('행 추가 버튼은 마지막 줄 바로 아래에 있고, 누르면 새 줄 항목에 커서가 간다', (tester) async {
    await pumpCalculatorTab(tester);
    await tester.tap(find.byTooltip('계산 추가'));
    await tester.pumpAndSettle();

    final addButton = find.byKey(const Key('calculator_add_row'));
    // 마지막 줄(첫 줄) 바로 아래 위치
    final lastRowBottom = tester.getBottomLeft(itemField(0)).dy;
    final buttonTop = tester.getTopLeft(addButton).dy;
    expect(buttonTop, greaterThan(lastRowBottom));
    expect(buttonTop - lastRowBottom, lessThan(24));

    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // 새 줄(두 번째)의 항목 입력칸에 포커스
    final secondItem = tester.widget<TextField>(itemField(1));
    expect(secondItem.focusNode!.hasFocus, isTrue);
    // 버튼은 다시 새 마지막 줄 아래로 이동
    expect(tester.getTopLeft(addButton).dy, greaterThan(tester.getBottomLeft(itemField(1)).dy));
  });

  test('CalculatorSheet 합계와 JSON 변환', () {
    final sheet = CalculatorSheet(
      title: '점심값',
      budget: 20000,
      rows: const [
        CalculatorRow(id: '1', date: '2026-10-03', item: '점심', amount: 12000),
        CalculatorRow(id: '2', date: '2026-10-03', item: '커피', amount: 4500),
      ],
    );
    expect(sheet.total, 16500);

    final restored = CalculatorSheet.fromJson(sheet.toJson());
    expect(restored.id, sheet.id);
    expect(restored.title, '점심값');
    expect(restored.rows.map((r) => r.item).toList(), ['점심', '커피']);
    expect(restored.total, 16500);
    expect(restored.budget, 20000);
    expect(restored.remaining, 3500);
  });
}
