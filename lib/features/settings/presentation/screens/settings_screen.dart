import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/diary_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _passwordController = TextEditingController();
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 테마 설정
          _buildThemeSettings(),
          const SizedBox(height: 20),
          
          // 보안 설정
          _buildSecuritySettings(),
          const SizedBox(height: 20),
          
          // 백업 및 복원
          _buildBackupSettings(),
          const SizedBox(height: 20),
          
          // 사용자 정의 설정
          _buildCustomSettings(),
          const SizedBox(height: 20),
          
          // 앱 정보
          _buildAppInfo(),
        ],
      ),
    );
  }

  Widget _buildThemeSettings() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '테마 설정',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                SwitchListTile(
                  title: const Text('시스템 테마 사용'),
                  subtitle: const Text('시스템 설정에 따라 자동으로 테마가 변경됩니다'),
                  value: themeProvider.isSystemTheme,
                  onChanged: (value) {
                    themeProvider.setSystemTheme(value);
                  },
                ),
                
                if (!themeProvider.isSystemTheme)
                  SwitchListTile(
                    title: const Text('다크 모드'),
                    subtitle: const Text('어두운 테마를 사용합니다'),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleDarkMode();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecuritySettings() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '보안 설정',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                SwitchListTile(
                  title: const Text('앱 잠금'),
                  subtitle: const Text('앱 실행 시 비밀번호를 요구합니다'),
                  value: themeProvider.isLockEnabled,
                  onChanged: (value) {
                    if (value) {
                      _showPasswordSetupDialog();
                    } else {
                      themeProvider.setLockEnabled(false);
                      themeProvider.setLockPassword(null);
                    }
                  },
                ),
                
                if (themeProvider.isLockEnabled)
                  ListTile(
                    title: const Text('비밀번호 변경'),
                    subtitle: const Text('앱 잠금 비밀번호를 변경합니다'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _showPasswordSetupDialog,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackupSettings() {
    return Consumer<DiaryProvider>(
      builder: (context, diaryProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '백업 및 복원',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('백업 내보내기'),
                  subtitle: const Text('모든 일기와 설정을 파일로 저장합니다'),
                  trailing: _isExporting 
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_ios),
                  onTap: _isExporting ? null : () => _exportBackup(diaryProvider),
                ),
                
                const Divider(),
                
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('백업 가져오기'),
                  subtitle: const Text('이전에 저장한 백업 파일을 불러옵니다'),
                  trailing: _isImporting 
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_ios),
                  onTap: _isImporting ? null : () => _importBackup(diaryProvider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomSettings() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '사용자 정의',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                ListTile(
                  leading: const Icon(Icons.emoji_emotions),
                  title: const Text('감정 아이콘 관리'),
                  subtitle: Text('${themeProvider.customIcons.length}개의 커스텀 아이콘'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showCustomIconsDialog(themeProvider),
                ),
                
                const Divider(),
                
                ListTile(
                  leading: const Icon(Icons.label),
                  title: const Text('태그 관리'),
                  subtitle: Text('${themeProvider.customTags.length}개의 커스텀 태그'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showCustomTagsDialog(themeProvider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '앱 정보',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            Consumer<DiaryProvider>(
              builder: (context, diaryProvider, child) {
                return Column(
                  children: [
                    _buildInfoRow('총 일기 수', '${diaryProvider.totalEntries}개'),
                    _buildInfoRow('이번 달 일기', '${diaryProvider.thisMonthEntries}개'),
                    _buildInfoRow('앱 버전', '1.0.0'),
                    _buildInfoRow('개발자', 'Diary App Team'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showPasswordSetupDialog() {
    _passwordController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비밀번호 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('앱 잠금에 사용할 비밀번호를 입력하세요.'),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
              maxLength: 20,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final password = _passwordController.text.trim();
              if (password.length >= 4) {
                context.read<ThemeProvider>().setLockPassword(password);
                context.read<ThemeProvider>().setLockEnabled(true);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('비밀번호가 설정되었습니다')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('비밀번호는 최소 4자리 이상이어야 합니다')),
                );
              }
            },
            child: const Text('설정'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(DiaryProvider diaryProvider) async {
    setState(() {
      _isExporting = true;
    });

    try {
      final backupData = await diaryProvider.exportBackup();
      
      if (kIsWeb) {
        // 웹에서는 다운로드 링크 제공
        
        // 사용자에게 백업 데이터를 보여주는 다이얼로그
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('백업 데이터'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: SingleChildScrollView(
                  child: SelectableText(
                    backupData,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('백업 데이터를 복사하여 저장하세요')),
                    );
                  },
                  child: const Text('복사'),
                ),
              ],
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('백업이 완료되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('백업 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _importBackup(DiaryProvider diaryProvider) async {
    setState(() {
      _isImporting = true;
    });

    try {
      if (kIsWeb) {
        // 웹에서는 텍스트 입력 다이얼로그
        final controller = TextEditingController();
        
        final backupData = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('백업 데이터 입력'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: '백업 JSON 데이터를 붙여넣으세요',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('가져오기'),
              ),
            ],
          ),
        );

        if (backupData != null && backupData.isNotEmpty) {
          // 백업 데이터 검증
          try {
            final jsonData = jsonDecode(backupData);
            if (jsonData['entries'] == null && jsonData['settings'] == null) {
              throw const FormatException('Invalid backup format');
            }
          } catch (e) {
            throw const FormatException('Invalid backup file');
          }

          await diaryProvider.importBackup(backupData);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('백업을 성공적으로 가져왔습니다')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모바일에서만 파일 선택이 가능합니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('백업 가져오기 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  void _showCustomIconsDialog(ThemeProvider themeProvider) {
    final iconController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('커스텀 아이콘 관리'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              // 아이콘 추가
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: iconController,
                      decoration: const InputDecoration(
                        hintText: '이모지 입력',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          themeProvider.addCustomIcon(value.trim());
                          iconController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final icon = iconController.text.trim();
                      if (icon.isNotEmpty) {
                        themeProvider.addCustomIcon(icon);
                        iconController.clear();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 커스텀 아이콘 목록
              Expanded(
                child: themeProvider.customIcons.isEmpty
                    ? const Center(
                        child: Text('커스텀 아이콘이 없습니다'),
                      )
                    : ListView.builder(
                        itemCount: themeProvider.customIcons.length,
                        itemBuilder: (context, index) {
                          final icon = themeProvider.customIcons[index];
                          return ListTile(
                            leading: Text(
                              icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                            title: Text(icon),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                themeProvider.removeCustomIcon(icon);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              iconController.dispose();
              Navigator.pop(context);
            },
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showCustomTagsDialog(ThemeProvider themeProvider) {
    final tagController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('커스텀 태그 관리'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              // 태그 추가
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tagController,
                      decoration: const InputDecoration(
                        hintText: '태그 입력',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          themeProvider.addCustomTag(value.trim());
                          tagController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final tag = tagController.text.trim();
                      if (tag.isNotEmpty) {
                        themeProvider.addCustomTag(tag);
                        tagController.clear();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 커스텀 태그 목록
              Expanded(
                child: themeProvider.customTags.isEmpty
                    ? const Center(
                        child: Text('커스텀 태그가 없습니다'),
                      )
                    : ListView.builder(
                        itemCount: themeProvider.customTags.length,
                        itemBuilder: (context, index) {
                          final tag = themeProvider.customTags[index];
                          return ListTile(
                            leading: const Icon(Icons.label),
                            title: Text(tag),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                themeProvider.removeCustomTag(tag);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              tagController.dispose();
              Navigator.pop(context);
            },
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
