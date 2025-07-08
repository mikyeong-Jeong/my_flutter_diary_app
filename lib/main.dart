import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:home_widget/home_widget.dart';
import 'core/providers/diary_provider.dart';
import 'core/providers/theme_provider.dart';
// import 'core/services/widget_service.dart';
import 'core/services/import_service.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/write/presentation/screens/write_screen.dart';
import 'features/search/presentation/screens/search_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'core/theme/app_theme.dart';

// 공유된 백업 데이터를 저장할 전역 변수
String? _sharedBackupData;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Locale 데이터 초기화
  await initializeDateFormatting('ko_KR', null);

  // 위젯 초기화 - 임시로 비활성화
  // final widgetService = WidgetService();
  // await widgetService.initializeWidget();

  // 위젯 백그라운드 콜백 등록 - 임시로 비활성화
  // HomeWidget.widgetClicked.listen((uri) {
  //   // 위젯 클릭 처리
  // });

  // 공유된 데이터 확인
  final sharedData = await ImportService.checkSharedData();
  if (ImportService.isValidBackupData(sharedData)) {
    _sharedBackupData = sharedData;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => DiaryProvider()),
      ],
      child: const AppWrapper(),
    );
  }
}

// Settings 로딩을 위한 Wrapper 위젯
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 앱 시작 시 공유된 백업 데이터 처리
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_sharedBackupData != null) {
        _showImportDialog(_sharedBackupData!);
        _sharedBackupData = null;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 앱이 다시 활성화될 때 공유된 데이터 확인
    if (state == AppLifecycleState.resumed) {
      _checkForSharedData();
    }
  }

  Future<void> _checkForSharedData() async {
    final sharedData = await ImportService.checkSharedData();
    if (ImportService.isValidBackupData(sharedData)) {
      _showImportDialog(sharedData!);
    }
  }

  void _showImportDialog(String backupData) {
    final navigator = Navigator.of(context);
    final diaryProvider = context.read<DiaryProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('백업 파일 감지'),
        content: const Text(
          '백업 파일이 공유되었습니다.\n'
          '가져오시겠습니까?\n\n'
          '주의: 현재 데이터가 덮어씌워집니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await diaryProvider.importBackup(backupData);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('백업을 성공적으로 가져왔습니다'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('백업 가져오기 실패: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('가져오기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: '나의 다이어리',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: const Locale('ko', 'KR'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ko', 'KR'),
            Locale('en', 'US'),
          ],
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            '/write': (context) => const WriteScreen(),
            '/search': (context) => const SearchScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
