import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/main.dart';

void main() {
  testWidgets('다이어리 앱 초기 화면 테스트', (WidgetTester tester) async {
    // 앱을 빌드하고 프레임을 트리거합니다.
    await tester.pumpWidget(const MyApp());

    // 앱 제목이 표시되는지 확인
    expect(find.text('나의 다이어리'), findsOneWidget);
    
    // 하단 네비게이션 바 아이템들이 있는지 확인
    expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    expect(find.byIcon(Icons.list), findsOneWidget);
    expect(find.byIcon(Icons.note), findsOneWidget);
    
    // FAB(플로팅 액션 버튼)이 있는지 확인
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
  
  testWidgets('새 일기 작성 버튼 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // FAB 버튼 탭
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    
    // 작성 화면으로 이동했는지 확인
    expect(find.text('새 일기'), findsOneWidget);
  });
  
  testWidgets('테마 변경 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // 설정 아이콘 찾기
    expect(find.byIcon(Icons.settings), findsOneWidget);
    
    // 설정 화면으로 이동
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    
    // 설정 화면 확인
    expect(find.text('설정'), findsOneWidget);
  });
}
