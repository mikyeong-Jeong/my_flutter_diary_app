import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/diary_provider.dart';
import '../widgets/backup_restore_section.dart';
import '../widgets/security_section.dart';
import '../widgets/customization_section.dart';
import '../widgets/app_info_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 테마 설정
            _buildThemeSection(context),
            
            const Divider(),
            
            // 백업 & 복원
            const BackupRestoreSection(),
            
            const Divider(),
            
            // 보안 설정
            const SecuritySection(),
            
            const Divider(),
            
            // 커스터마이징
            const CustomizationSection(),
            
            const Divider(),
            
            // 앱 정보
            const AppInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('테마 설정'),
              subtitle: Text(_getThemeModeText(themeProvider.themeMode)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('시스템 설정 따르기'),
                    value: ThemeMode.system,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setThemeMode(value);
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('라이트 모드'),
                    value: ThemeMode.light,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setThemeMode(value);
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('다크 모드'),
                    value: ThemeMode.dark,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setThemeMode(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '시스템 설정 따르기';
      case ThemeMode.light:
        return '라이트 모드';
      case ThemeMode.dark:
        return '다크 모드';
    }
  }
}
