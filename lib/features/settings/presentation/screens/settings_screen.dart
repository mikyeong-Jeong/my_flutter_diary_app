import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
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
        // 모바일에서는 다양한 저장 옵션 제공
        await _showBackupOptionsDialog(context, fileName, backupData);
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

  Future<void> _showBackupOptionsDialog(BuildContext context, String fileName, String backupData) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('백업 저장 방법 선택'),
        content: const Text('백업 파일을 어떻게 저장하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _saveToDownloads(context, fileName, backupData);
            },
            child: const Text('다운로드 폴더'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _shareBackupFile(context, fileName, backupData);
            },
            child: const Text('외부 앱으로 공유'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _saveToCloud(context, fileName, backupData);
            },
            child: const Text('클라우드 저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToDownloads(BuildContext context, String fileName, String backupData) async {
    try {
      Directory? directory;
      
      if (Platform.isAndroid) {
        // Android: Downloads 폴더 사용
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // 권한이 없거나 경로가 다른 경우 Documents 폴더 사용
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        // iOS: Documents 폴더 사용 (Downloads는 접근 불가)
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(backupData, encoding: utf8);

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('백업 완료'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('백업 파일이 저장되었습니다:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      file.path,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('확인'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _shareBackupFile(context, fileName, backupData);
                  },
                  child: const Text('추가 공유'),
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
            content: Text('다운로드 폴더 저장 실패: $e\n외부 공유를 이용해주세요'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        // 실패 시 공유 기능으로 대체
        await _shareBackupFile(context, fileName, backupData);
      }
    }
  }

  Future<void> _shareBackupFile(BuildContext context, String fileName, String backupData) async {
    try {
      // 임시 파일 생성
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(backupData, encoding: utf8);

      // 파일 공유
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: '다이어리 백업',
        text: '다이어리 백업 파일입니다. 안전한 곳에 보관해주세요.',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('백업 파일이 공유되었습니다\n카카오톡, 구글드라이브 등으로 저장하세요'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('공유 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveToCloud(BuildContext context, String fileName, String backupData) async {
    try {
      // 클라우드 저장을 위한 옵션들
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('클라우드 저장'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('다음 방법 중 하나를 선택하세요:'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('공유를 통한 클라우드 저장'),
                subtitle: const Text('구글드라이브, OneDrive 등'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _shareBackupFile(context, fileName, backupData);
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_copy),
                title: const Text('파일 앱으로 저장'),
                subtitle: const Text('파일 관리자를 통한 저장'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _saveToFiles(context, fileName, backupData);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('클라우드 저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveToFiles(BuildContext context, String fileName, String backupData) async {
    try {
      // 시스템 파일 선택기를 통한 저장
      final FileSaveLocation? saveLocation = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'JSON files',
            extensions: ['json'],
          ),
        ],
      );

      if (saveLocation != null) {
        final file = File(saveLocation.path);
        await file.writeAsString(backupData, encoding: utf8);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('백업이 저장되었습니다:\n${file.path}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('파일 저장 실패: $e\n공유 기능을 이용해주세요'),
            backgroundColor: Colors.orange,
          ),
        );
        // 실패 시 공유 기능으로 대체
        await _shareBackupFile(context, fileName, backupData);
      }
    }
  }
  
  Future<void> _importBackup(BuildContext context) async {
    try {
      if (kIsWeb) {
        // 웹에서는 파일 선택기 사용
        await _selectFileForRestore(context);
      } else {
        // 모바일에서는 복원 옵션 선택
        await _showRestoreOptionsDialog(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('복원 준비 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRestoreOptionsDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('복원 방법 선택'),
        content: const Text('백업 파일을 어떤 방법으로 선택하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _restoreFromLocalFiles(context);
            },
            child: const Text('앱 저장 파일'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _selectFileForRestore(context);
            },
            child: const Text('파일 선택'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _restoreFromClipboard(context);
            },
            child: const Text('클립보드'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreFromLocalFiles(BuildContext context) async {
    try {
      // Downloads 폴더와 Documents 폴더에서 백업 파일 찾기
      final backupFiles = <File>[];
      
      // Downloads 폴더 확인 (Android)
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          final files = downloadDir
              .listSync()
              .where((file) => file.path.endsWith('.json') && file.path.contains('diary_backup'))
              .cast<File>()
              .toList();
          backupFiles.addAll(files);
        }
      }
      
      // Documents 폴더 확인
      final documentsDir = await getApplicationDocumentsDirectory();
      final docFiles = documentsDir
          .listSync()
          .where((file) => file.path.endsWith('.json') && file.path.contains('diary_backup'))
          .cast<File>()
          .toList();
      backupFiles.addAll(docFiles);

      if (context.mounted) {
        if (backupFiles.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('저장된 백업 파일을 찾을 수 없습니다\n파일 선택을 이용해주세요'),
              backgroundColor: Colors.orange,
            ),
          );
          await _selectFileForRestore(context);
        } else {
          await _showBackupFilesList(context, backupFiles);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로컬 파일 검색 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showBackupFilesList(BuildContext context, List<File> backupFiles) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('백업 파일 선택'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('복원할 백업 파일을 선택하세요:'),
              const SizedBox(height: 16),
              ...backupFiles.map((file) {
                final fileName = file.path.split('/').last;
                final fileDate = file.lastModifiedSync();
                final fileSize = file.lengthSync();
                return ListTile(
                  title: Text(fileName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('날짜: ${DateFormat('yyyy-MM-dd HH:mm').format(fileDate)}'),
                      Text('크기: ${(fileSize / 1024).toStringAsFixed(1)} KB'),
                    ],
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final content = await file.readAsString(encoding: utf8);
                    await _processImport(context, content);
                  },
                );
              }).toList(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('다른 파일 선택'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _selectFileForRestore(context);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFileForRestore(BuildContext context) async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'JSON files',
        extensions: ['json'],
      );
      
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      
      if (file != null) {
        final String content = await file.readAsString();
        await _processImport(context, content);
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

  Future<void> _restoreFromClipboard(BuildContext context) async {
    try {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('클립보드에서 복원'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '백업 데이터를 클립보드에 복사한 후 아래 버튼을 눌러주세요.\n\n'
                '카카오톡이나 다른 앱에서 백업 파일을 열어 내용을 복사할 수 있습니다.',
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  // 클립보드 데이터 읽기는 플랫폼별로 구현 필요
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('클립보드 기능은 추후 업데이트 예정입니다\n파일 선택을 이용해주세요'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  await _selectFileForRestore(context);
                },
                icon: const Icon(Icons.content_paste),
                label: const Text('클립보드에서 가져오기'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('클립보드 복원 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _processImport(BuildContext context, String content) async {
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
