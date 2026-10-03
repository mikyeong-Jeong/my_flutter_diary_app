import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diary_app/core/models/diary_entry.dart';
import 'package:diary_app/core/providers/diary_provider.dart';
import 'package:diary_app/features/search/presentation/screens/search_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('search_test');
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

  testWidgets('좁은 화면에서도 검색 결과의 생성/수정 시간이 카드 밖으로 넘치지 않는다', (tester) async {
    // 360dp 폭의 휴대폰 화면
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final provider = DiaryProvider();
    await tester.runAsync(() async {
      await provider.loadEntries();
      await provider.addEntry(DiaryEntry(
        title: '일반 메모',
        content: '내용',
        type: EntryType.general,
        createdAt: DateTime(2026, 12, 25, 10, 30),
        updatedAt: DateTime(2026, 12, 31, 23, 59),
      ));
      await provider.addEntry(DiaryEntry(
        date: '2026-12-25',
        title: '일기',
        content: '내용',
        createdAt: DateTime(2026, 12, 25, 10, 30),
      ));
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<DiaryProvider>.value(
        value: provider,
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // 일기·할 일 탭
    expect(find.textContaining('작성: 2026년 12월 25일'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 일반 메모 탭
    await tester.tap(find.textContaining('일반 메모 ('));
    await tester.pumpAndSettle();
    expect(find.textContaining('수정: 2026년 12월 31일 23:59'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
