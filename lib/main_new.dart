import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/diary_provider.dart';
import 'core/providers/settings_provider.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/write/presentation/screens/write_screen.dart';
import 'features/search/presentation/screens/search_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DiaryProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()..loadSettings()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return MaterialApp(
          title: '나의 다이어리',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settingsProvider.themeMode,
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
