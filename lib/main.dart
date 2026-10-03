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
import 'core/services/storage_service.dart';
import 'core/navigation/deeplink_router.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/write/presentation/screens/write_screen.dart';
import 'features/read/presentation/screens/read_screen.dart';
import 'features/search/presentation/screens/search_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/write/presentation/screens/dated_note_screen.dart';
import 'features/read/presentation/screens/dated_note_read_screen.dart';

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

  // 위젯을 눌러 앱이 시작된 경우, 첫 화면을 그리기 전에 딥링크를 확인해
  // 달력(홈)을 거치지 않고 바로 해당 항목 화면으로 시작
  const platform = MethodChannel('com.diary.app/deeplink');
  final initialRoutes = await _loadInitialRoutes(platform);

  // 앱 실행 중에 위젯을 누른 경우 (MainActivity.onNewIntent에서 전달)
  platform.setMethodCallHandler((call) async {
    if (call.method == 'onDeeplink' && call.arguments != null) {
      final uri = Uri.parse(call.arguments as String);
      _handleDeeplink(uri);
    }
  });

  runApp(MyApp(initialRoutes: initialRoutes));

  // 위젯 데이터 업데이트 (SingleMemoWidget 설정 화면용)
  Future.delayed(const Duration(milliseconds: 500), () async {
    final context = MyApp.navigatorKey.currentContext;
    if (context != null) {
      final diaryProvider = context.read<DiaryProvider>();
      await diaryProvider.loadEntries();
      await widgetService.updateWidget();
    }
  });
}

/// 앱 시작 시 전달된 딥링크로 초기 화면 목록을 만듦
///
/// 딥링크가 없거나 확인할 수 없으면(웹 등) null을 반환해 기본 홈 화면으로 시작합니다.
Future<List<RouteSettings>?> _loadInitialRoutes(MethodChannel platform) async {
  try {
    final String? deeplink = await platform.invokeMethod('getDeeplink');
    if (deeplink == null) return null;

    // 항목을 찾기 위해 저장된 데이터를 미리 로드
    final entries = await StorageService.instance.loadAllEntries();
    final routes = DeeplinkRouter.resolve(Uri.parse(deeplink), entries);
    if (routes.isEmpty) return null;

    // 뒤로 가기 시 홈으로 돌아갈 수 있도록 항상 홈을 맨 아래에 둠
    return routes.first.name == '/'
        ? routes
        : [const RouteSettings(name: '/'), ...routes];
  } catch (e) {
    // 딥링크 채널이 없는 플랫폼(웹 등)이거나 로드 실패 시 기본 시작
    return null;
  }
}

/// 실행 중인 앱에 전달된 딥링크 처리
/// MainActivity에서 전달받은 딥링크를 해당 화면으로 이동합니다.
void _handleDeeplink(Uri uri) {
  final navigator = MyApp.navigatorKey.currentState;
  final context = MyApp.navigatorKey.currentContext;
  if (navigator == null || context == null) return;

  final entries = context.read<DiaryProvider>().entries;
  final routes = DeeplinkRouter.resolve(uri, entries);
  if (routes.isEmpty) return;

  var toPush = routes;
  if (routes.first.name == '/') {
    // 홈 화면을 새로 열어 지정된 탭으로 이동
    navigator.pushNamedAndRemoveUntil('/', (route) => false, arguments: routes.first.arguments);
    toPush = routes.sublist(1);
  }
  for (final route in toPush) {
    navigator.pushNamed(route.name!, arguments: route.arguments);
  }
}

@pragma('vm:entry-point')
void backgroundCallback(Uri? uri) async {
  if (uri != null && MyApp.navigatorKey.currentState != null) {
    final context = MyApp.navigatorKey.currentContext;
    if (context != null) {
      if (uri.host == 'openapp') {
        // 위젯 클릭으로 앱 열기 - 홈 화면으로 이동
        MyApp.navigatorKey.currentState
            ?.pushNamedAndRemoveUntil('/', (route) => false);
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
  const MyApp({super.key, this.initialRoutes});

  /// 위젯 딥링크로 시작할 때의 초기 화면 목록 (null이면 홈 화면으로 시작)
  final List<RouteSettings>? initialRoutes;

  /// 앱 내 화면 라우팅 정의
  static final Map<String, WidgetBuilder> appRoutes = {
    // 홈 화면 (달력, 일기/메모/할 일 목록) - arguments로 시작 탭 지정 가능
    '/': (context) => HomeScreen(
          initialTabIndex: _homeTabFromArguments(ModalRoute.of(context)?.settings.arguments),
        ),
    '/write': (context) => const WriteScreen(), // 일기 작성 화면
    '/read': (context) => const ReadScreen(), // 일기 읽기 화면
    '/search': (context) => const SearchScreen(), // 일기 검색 화면
    '/settings': (context) => const SettingsScreen(), // 설정 화면
    '/dated_note': (context) => const DatedNoteReadScreen(), // 할 일 읽기 화면
    '/write/dated_note': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as DiaryEntry?;
      return DatedNoteScreen(entry: args);
    }, // 할 일 편집 화면
  };

  /// 홈 화면 arguments(tabIndex / viewMemoId)에서 시작 탭 인덱스를 계산
  static int _homeTabFromArguments(Object? arguments) {
    if (arguments is Map) {
      if (arguments['viewMemoId'] != null) return 2; // 메모 탭
      final tabIndex = arguments['tabIndex'];
      if (tabIndex is int && tabIndex >= 0 && tabIndex < 4) return tabIndex;
    }
    return 0;
  }

  // 전역 네비게이터 키 (딥링크 처리용)
  // 위젯에서 앱을 열 때 특정 화면으로 이동하기 위해 사용
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

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
              GlobalMaterialLocalizations.delegate, // Material 디자인 관련 다국어
              GlobalWidgetsLocalizations.delegate, // 위젯 관련 다국어
              GlobalCupertinoLocalizations.delegate, // iOS 스타일 위젯 다국어
            ],

            // 지원하는 언어 목록
            supportedLocales: const [
              Locale('ko', 'KR'), // 한국어
              Locale('en', 'US'), // 영어
            ],

            // 기본 로케일을 한국어로 설정
            locale: const Locale('ko', 'KR'),

            // 앱 시작 시 초기 라우트
            initialRoute: '/',

            // 앱 내 화면 라우팅 정의
            routes: appRoutes,

            // 위젯 딥링크로 시작한 경우 홈 위에 대상 화면을 쌓은 상태로 바로 시작
            onGenerateInitialRoutes: (initialRoute) {
              final settingsList = initialRoutes ?? [RouteSettings(name: initialRoute)];
              return settingsList
                  .map<Route<dynamic>>((settings) => MaterialPageRoute(
                        settings: settings,
                        builder: appRoutes[settings.name] ?? appRoutes['/']!,
                      ))
                  .toList();
            },
          );
        },
      ),
    );
  }
}
