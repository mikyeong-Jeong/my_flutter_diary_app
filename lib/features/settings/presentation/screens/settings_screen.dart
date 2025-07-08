import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:typed_data';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/diary_provider.dart';
import '../../../../core/models/diary_entry.dart';
import '../../../../core/utils/download_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          // 테마 설정
          _buildSection(
            title: '테마',
            children: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return ListTile(
                    leading: const Icon(Icons.brightness_6),
                    title: const Text('다크 모드'),
                    subtitle: Text(
                      themeProvider.themeMode == ThemeMode.dark
                          ? '다크 모드 사용 중'
                          : themeProvider.themeMode == ThemeMode.light
                              ? '라이트 모드 사용 중'
                              : '시스템 설정 따름',
                    ),
                    trailing: Switch(
                      value: themeProvider.themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          
          // 데이터 관리
          _buildSection(
            title: '데이터 관리',
            children: [
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('백업'),
                subtitle: const Text('일기 데이터를 백업 파일로 저장'),
                onTap: () => _exportBackup(context),
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('복원'),
                subtitle: const Text('백업 파일에서 일기 데이터 복원'),
                onTap: () => _importBackup(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('모든 데이터 삭제'),
                subtitle: const Text('모든 일기를 영구적으로 삭제'),
                onTap: () => _deleteAllData(context),
              ),
            ],
          ),
          
          // 통계
          _buildSection(
            title: '통계',
            children: [
              Consumer<DiaryProvider>(
                builder: (context, diaryProvider, child) {
                  final entries = diaryProvider.entries;
                  final totalEntries = entries.length;
                  final thisMonth = entries.where((e) {
                    if (e.date == null) return false;
                    final now = DateTime.now();
                    final entryDate = DateTime.parse(e.date!);
                    return entryDate.year == now.year && entryDate.month == now.month;
                  }).length;
                  final streak = _calculateStreak(entries);
                  
                  return Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.book),
                        title: const Text('총 일기 수'),
                        trailing: Text(
                          '$totalEntries개',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('이번 달 일기'),
                        trailing: Text(
                          '$thisMonth개',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.local_fire_department),
                        title: const Text('연속 작성일'),
                        trailing: Text(
                          '$streak일',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          
          // 앱 정보
          _buildSection(
            title: '앱 정보',
            children: [
              const ListTile(
                leading: Icon(Icons.info),
                title: Text('버전'),
                trailing: Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('오픈소스 라이선스'),
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: '나의 다이어리',
                    applicationVersion: '1.0.0',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }
  
  int _calculateStreak(List<DiaryEntry> entries) {
    if (entries.isEmpty) return 0;
    
    final sortedEntries = entries
        .where((e) => e.date != null)
        .toList()
      ..sort((a, b) => b.date!.compareTo(a.date!));
    
    if (sortedEntries.isEmpty) return 0;
    
    int streak = 0;
    DateTime? lastDate;
    
    for (final entry in sortedEntries) {
      final entryDateTime = DateTime.parse(entry.date!);
      final entryDate = DateTime(entryDateTime.year, entryDateTime.month, entryDateTime.day);
      
      if (lastDate == null) {
        // 첫 번째 엔트리
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        
        if (entryDate == todayDate || 
            entryDate == todayDate.subtract(const Duration(days: 1))) {
          streak = 1;
          lastDate = entryDate;
        } else {
          break;
        }
      } else {
        // 연속된 날짜인지 확인
        if (lastDate.subtract(const Duration(days: 1)) == entryDate) {
          streak++;
          lastDate = entryDate;
        } else {
          break;
        }
      }
    }
    
    return streak;
  }
  
  Future<void> _exportBackup(BuildContext context) async {
    try {
      final diaryProvider = context.read<DiaryProvider>();
      final backupData = await diaryProvider.exportBackup();
      
      final fileName = 'diary_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      
      if (kIsWeb) {
        // 웹에서는 다운로드로 처리
        downloadFile(fileName, backupData);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('백업 파일이 다운로드되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 모바일에서는 공유
        await Share.shareXFiles(
          [XFile.fromData(
            Uint8List.fromList(backupData.codeUnits),
            name: fileName,
            mimeType: 'application/json',
          )],
          subject: '다이어리 백업',
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('백업 파일이 생성되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('백업 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _importBackup(BuildContext context) async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'JSON files',
        extensions: ['json'],
      );
      
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      
      if (file != null) {
        final String content = await file.readAsString();
        
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('백업 복원'),
              content: const Text(
                '백업을 복원하시겠습니까?\n'
                '현재 모든 데이터가 백업 파일의 데이터로 교체됩니다.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    
                    try {
                      await context.read<DiaryProvider>().importBackup(content);
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('백업이 성공적으로 복원되었습니다'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('복원 실패: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('복원'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('파일 선택 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _deleteAllData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('모든 데이터 삭제'),
        content: const Text(
          '정말로 모든 일기를 삭제하시겠습니까?\n'
          '이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              
              // 확인 다이얼로그
              showDialog(
                context: context,
                builder: (ctx2) => AlertDialog(
                  title: const Text('최종 확인'),
                  content: const Text('정말로 삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx2),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<DiaryProvider>().deleteAllEntries();
                        Navigator.pop(ctx2);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('모든 데이터가 삭제되었습니다'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
