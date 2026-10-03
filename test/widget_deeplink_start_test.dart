import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diary_app/main.dart';
import 'package:diary_app/core/models/diary_entry.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('deeplink_start_test');
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

  testWidgets('위젯으로 시작하면 달력(홈)이 아니라 해당 항목 화면이 첫 화면으로 뜬다', (tester) async {
    final entry = DiaryEntry(
      date: '2026-10-03',
      title: '위젯에서 연 일기',
      content: '본문',
    );

    await tester.pumpWidget(MyApp(initialRoutes: [
      const RouteSettings(name: '/'),
      RouteSettings(name: '/read', arguments: entry),
    ]));

    // 첫 프레임부터 읽기 화면이 보여야 함 (달력을 거치지 않음)
    expect(find.text('일기 보기'), findsOneWidget);
    expect(find.text('위젯에서 연 일기'), findsOneWidget);
    expect(find.text('나의 다이어리'), findsNothing);

    // 뒤로 가기 시 홈 화면으로 돌아감
    expect(MyApp.navigatorKey.currentState!.canPop(), isTrue);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('나의 다이어리'), findsOneWidget);
  });

  testWidgets('home?tab=N 딥링크로 시작하면 해당 탭이 바로 선택된다', (tester) async {
    await tester.pumpWidget(const MyApp(initialRoutes: [
      RouteSettings(name: '/', arguments: {'tabIndex': 3}),
    ]));
    await tester.pump();

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.controller!.index, 3);
  });
}
