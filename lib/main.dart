/**
 * 다이어리 앱의 메인 엔트리 포인트
 * 
 * 이 파일은 Flutter 다이어리 앱의 진입점으로서 다음과 같은 핵심 기능을 담당합니다:
 * - 앱의 전역 상태 관리 설정 (Provider 패턴)
 * - 테마 설정 (라이트/다크 모드)
 * - 다국어 지원 설정 (한국어/영어)
 * - 앱 내 라우팅 설정
 * - 앱의 전반적인 구조와 설정 초기화
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/diary_provider.dart';
import 'core/models/diary_entry.dart';
import 'core/theme/app_theme.dart';
import 'core/services/widget_service.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/write/presentation/screens/write_screen.dart';
import 'features/read/presentation/screens/read_screen.dart';
import 'features/search/presentation/screens/search_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';

/**
 * 앱의 메인 함수
 * 
 * Flutter 앱의 시작점으로, MyApp 위젯을 실행합니다.
 * 앱이 시작될 때 가장 먼저 호출되는 함수입니다.
 */
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 위젯 서비스 초기화
  final widgetService = WidgetService();
  await widgetService.initializeWidget();
  
  // 위젯 콜백을 통한 딥링크 처리 등록
  HomeWidget.registerInteractivityCallback(backgroundCallback);
  
  // 딥링크 처리를 위한 메서드 채널 설정
  const platform = MethodChannel('com.diary.app/deeplink');
  platform.setMethodCallHandler((call) async {
    if (call.method == 'onDeeplink' && call.arguments != null) {
      final uri = Uri.parse(call.arguments as String);
      _handleDeeplink(uri);
    }
  });
  
  runApp(const MyApp());
  
  // 앱 시작 시 pending deeplink 확인
  Future.delayed(const Duration(milliseconds: 500), () async {
    // DiaryProvider 로드를 기다림
    final context = MyApp.navigatorKey.currentContext;
    if (context != null) {
      final diaryProvider = context.read<DiaryProvider>();
      await diaryProvider.loadEntries();
      // 위젯 데이터 업데이트 (SingleMemoWidget 설정 화면용)
      await widgetService.updateWidget();
    }
    
    try {
      final String? deeplink = await platform.invokeMethod('getDeeplink');
      if (deeplink != null) {
        final uri = Uri.parse(deeplink);
        _handleDeeplink(uri);
      }
    } catch (e) {
      // 에러 무시
    }
  });
}

/// 위젯에서 앱으로의 딥링크 처리를 위한 백그라운드 콜백
/// 홈 화면 위젯이나 메모 위젯에서 버튼을 클릭했을 때 호출되는 함수
/// 
/// @param uri : 위젯에서 전달한 딥링크 URI
///   - openapp: 앱 열기
///   - newentry: 새 일기 작성
///   - viewmemo: 특정 메모 보기
///   - editmemo: 특정 메모 편집
///   - write: 일기 작성
/// 딥링크 처리 함수
/// MainActivity에서 전달받은 딥링크를 처리합니다.
void _handleDeeplink(Uri uri) {
  if (MyApp.navigatorKey.currentState != null) {
    if (uri.host == 'home') {
      // 홈 화면의 특정 탭으로 이동
      final tabIndex = uri.queryParameters['tab'];
      if (tabIndex != null) {
        final index = int.tryParse(tabIndex) ?? 0;
        // 홈 화면으로 이동하면서 탭 인덱스 전달
        MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/',
          (route) => false,
          arguments: {'tabIndex': index},
        );
      }
    } else if (uri.host == 'viewmemo') {
      // 메모 보기 - 특정 메모의 상세 화면으로 이동
      final memoId = uri.queryParameters['id'];
      if (memoId != null) {
        // DiaryProvider에서 메모를 찾아서 편집 화면으로 이동
        final context = MyApp.navigatorKey.currentContext;
        if (context != null) {
          final diaryProvider = context.read<DiaryProvider>();
          final entry = diaryProvider.entries.firstWhere(
            (e) => e.id == memoId,
            orElse: () => diaryProvider.entries.first,
          );
          
          // 읽기 화면으로 이동
          MyApp.navigatorKey.currentState?.pushNamed(
            '/read',
            arguments: entry,
          );
        }
      }
    } else if (uri.host == 'viewdate') {
      // 특정 날짜의 일기 보기
      final date = uri.queryParameters['date'];
      if (date != null) {
        final context = MyApp.navigatorKey.currentContext;
        if (context != null) {
          final diaryProvider = context.read<DiaryProvider>();
          // 해당 날짜의 일기 찾기
          final entry = diaryProvider.entries.firstWhere(
            (e) => e.date == date && e.type == EntryType.dated,
            orElse: () => DiaryEntry(
              date: date,
              title: '',
              content: '',
              type: EntryType.dated,
            ),
          );
          
          if (entry.id.isNotEmpty) {
            // 일기가 있으면 읽기 화면으로
            MyApp.navigatorKey.currentState?.pushNamed(
              '/read',
              arguments: entry,
            );
          } else {
            // 일기가 없으면 작성 화면으로
            MyApp.navigatorKey.currentState?.pushNamed(
              '/write',
              arguments: entry,
            );
          }
        }
      }
    } else if (uri.host == 'write') {
      // 새 메모 작성
      final type = uri.queryParameters['type'];
      final date = uri.queryParameters['date'];
      
      if (type == 'general') {
        // 일반 메모 작성
        MyApp.navigatorKey.currentState?.pushNamed(
          '/write',
          arguments: DiaryEntry(
            title: '',
            content: '',
            type: EntryType.general,
          ),
        );
      } else {
        // 날짜별 일기 작성
        MyApp.navigatorKey.currentState?.pushNamed(
          '/write',
          arguments: DiaryEntry(
            date: date ?? _formatDate(DateTime.now()),
            title: '',
            content: '',
            type: EntryType.dated,
          ),
        );
      }
    }
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

@pragma('vm:entry-point')
void backgroundCallback(Uri? uri) async {
  if (uri != null && MyApp.navigatorKey.currentState != null) {
    final context = MyApp.navigatorKey.currentContext;
    if (context != null) {
      if (uri.host == 'openapp') {
        // 위젯 클릭으로 앱 열기 - 홈 화면으로 이동
        MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
      } else if (uri.host == 'newentry') {
        // 새 일기 작성 버튼 클릭 - 작성 화면으로 이동
        MyApp.navigatorKey.currentState?.pushNamed('/write');
      } else if (uri.host == 'viewmemo') {
        // 메모 보기 - 특정 메모로 이동
        final memoId = uri.queryParameters['id'];
        if (memoId != null) {
          // 홈 화면으로 이동 후 특정 메모 선택
          MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/',
            (route) => false,
            arguments: {'viewMemoId': memoId},
          );
        }
      } else if (uri.host == 'editmemo') {
        // 메모 편집 - 편집 화면으로 이동
        final memoId = uri.queryParameters['id'];
        if (memoId != null) {
          // 편집 화면으로 이동 시 메모 ID 전달
          MyApp.navigatorKey.currentState?.pushNamed(
            '/write',
            arguments: {'editMemoId': memoId},
          );
        }
      } else if (uri.host == 'write') {
        // 새 일기 작성
        MyApp.navigatorKey.currentState?.pushNamed('/write');
      }
    }
  }
}

/**
 * 앱의 루트 위젯 클래스
 * 
 * 앱의 전체적인 구조를 정의하고, 전역 설정들을 초기화합니다.
 * StatelessWidget을 상속받아 앱의 전체 구조를 담당합니다.
 * 
 * 주요 역할:
 * - Provider를 통한 전역 상태 관리 설정
 * - MaterialApp을 통한 앱의 기본 설정
 * - 라우팅 시스템 구축
 * - 테마 및 다국어 설정
 */
class MyApp extends StatelessWidget {
  /**
   * MyApp 생성자
   * 
   * @param key : 위젯 식별을 위한 키 (선택사항)
   */
  const MyApp({super.key});

  // 전역 네비게이터 키 (딥링크 처리용)
  // 위젯에서 앱을 열 때 특정 화면으로 이동하기 위해 사용
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /**
   * 위젯 빌드 메서드
   * 
   * 앱의 전체 구조를 구성하고 반환합니다.
   * MultiProvider로 전역 상태를 관리하고, MaterialApp으로 앱의 기본 설정을 구성합니다.
   * 
   * @param context : 빌드 컨텍스트
   * @return Widget : 앱의 루트 위젯
   * 
   * 구성 요소:
   * 1. MultiProvider: 전역 상태 관리를 위한 Provider 설정
   *    - ThemeProvider: 테마 관리 (라이트/다크 모드)
   *    - DiaryProvider: 다이어리 데이터 관리
   * 
   * 2. Consumer<ThemeProvider>: 테마 변경 사항을 감지하고 반영
   * 
   * 3. MaterialApp: 앱의 기본 설정
   *    - 제목, 테마, 다국어, 라우팅 등을 설정
   */
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // 전역 상태 관리를 위한 Provider 목록
      providers: [
        // 테마 관리 Provider - 라이트/다크 모드 전환을 담당
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // 다이어리 데이터 관리 Provider - 일기 작성, 수정, 삭제 등을 담당
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
      ],
      // 테마 변경사항을 실시간으로 반영하기 위한 Consumer
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            // 전역 네비게이터 키 설정 (딥링크 처리용)
            navigatorKey: navigatorKey,
            
            // 앱 제목 (작업 관리자 등에서 표시)
            title: '나의 다이어리',
            
            // 라이트 테마 설정
            theme: AppTheme.lightTheme,
            // 다크 테마 설정
            darkTheme: AppTheme.darkTheme,
            // 현재 테마 모드 (ThemeProvider에서 관리)
            themeMode: themeProvider.themeMode,
            
            // 다국어 지원을 위한 로컬라이제이션 델리게이트 설정
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,    // Material 디자인 관련 다국어
              GlobalWidgetsLocalizations.delegate,     // 위젯 관련 다국어
              GlobalCupertinoLocalizations.delegate,   // iOS 스타일 위젯 다국어
            ],
            
            // 지원하는 언어 목록
            supportedLocales: const [
              Locale('ko', 'KR'),  // 한국어
              Locale('en', 'US'),  // 영어
            ],
            
            // 기본 로케일을 한국어로 설정
            locale: const Locale('ko', 'KR'),
            
            // 앱 시작 시 초기 라우트
            initialRoute: '/',
            
            // 앱 내 화면 라우팅 정의
            routes: {
              '/': (context) => const HomeScreen(),        // 홈 화면 (캘린더, 일기 목록)
              '/write': (context) => const WriteScreen(),  // 일기 작성 화면
              '/read': (context) => const ReadScreen(),    // 일기 읽기 화면
              '/search': (context) => const SearchScreen(), // 일기 검색 화면
              '/settings': (context) => const SettingsScreen(), // 설정 화면
            },
          );
        },
      ),
    );
  }
}