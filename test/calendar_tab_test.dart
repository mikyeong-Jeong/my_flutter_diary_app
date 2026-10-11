import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:diary_app/core/models/diary_entry.dart';
import 'package:diary_app/main.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('calendar_tab_test');
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

  /// 달력 탭(0번)이 선택된 홈 화면으로 앱 시작 (일반 휴대폰 폭 360dp)
  Future<void> pumpCalendarTab(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp(initialRoutes: [
      RouteSettings(name: '/', arguments: {'tabIndex': 0}),
    ]));
    await tester.pumpAndSettle();
  }

  CalendarFormat currentFormat(WidgetTester tester) =>
      tester.widget<TableCalendar<DiaryEntry>>(find.byType(TableCalendar<DiaryEntry>)).calendarFormat;

  testWidgets('달력 위에서 위/아래로 드래그해도 월간 달력이 줄어들지 않는다', (tester) async {
    await pumpCalendarTab(tester);
    expect(currentFormat(tester), CalendarFormat.month);

    // 달력 날짜 칸에서 위로 드래그 (아래 일기를 보려는 동작)
    final dayCell = find.descendant(
      of: find.byType(TableCalendar<DiaryEntry>),
      matching: find.text('15'),
    );
    await tester.drag(dayCell, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(currentFormat(tester), CalendarFormat.month);

    // 아래로 드래그해도 그대로 월간
    await tester.drag(dayCell, const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(currentFormat(tester), CalendarFormat.month);
  });
}
