import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/diary_provider.dart';
import '../../../../core/models/diary_entry.dart';
import '../../../../core/utils/download_helper.dart';
import '../../../../core/utils/json_utils.dart';
import '../../../../core/services/widget_service.dart';

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
          
          // 위젯 설정
          _buildSection(
            title: '위젯 설정',
            children: [
              ListTile(
                leading: const Icon(Icons.widgets),
                title: const Text('위젯 정보'),
                subtitle: const Text('홈 화면 위젯 사용 안내'),
                onTap: () => _showWidgetInfo(context),
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

  // 위젯 정보 다이얼로그
  void _showWidgetInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('홈 화면 위젯 정보'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('이 앱은 3가지 종류의 홈 화면 위젯을 제공합니다:\n'),
              Text('1. 일기 위젯', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('   - 최근 작성한 일기 3개를 목록으로 표시\n'),
              Text('2. 메모 위젯', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('   - 최근 작성한 메모 3개를 목록으로 표시\n'),
              Text('3. 단일 메모 위젯', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('   - 선택한 특정 메모 하나를 전체 표시'),
              Text('   - 위젯 추가 시 표시할 메모를 선택 가능\n'),
              Text('위젯 추가 방법:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('1. 홈 화면 길게 누르기'),
              Text('2. 위젯 추가 메뉴 선택'),
              Text('3. "나의 다이어리" 앱 찾기'),
              Text('4. 원하는 위젯 선택 및 추가'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 메모 위젯 설정 다이얼로그 (더 이상 사용되지 않음)
  void _showMemoWidgetConfig(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메모 위젯 설정'),
        content: const SizedBox(
          width: double.maxFinite,
          child: Text('위젯에 표시할 메모를 선택하세요.\n\n'
              '현재는 수동으로 위젯 ID를 입력하여 설정해야 합니다.\n'
              '향후 버전에서 더 편리한 UI를 제공할 예정입니다.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showMemoSelectionDialog(context);
            },
            child: const Text('메모 선택'),
          ),
        ],
      ),
    );
  }

  // 메모 선택 다이얼로그
  void _showMemoSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer<DiaryProvider>(
        builder: (context, provider, child) {
          final allEntries = provider.generalNotes.toList();
          
          return AlertDialog(
            title: const Text('메모 선택'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: allEntries.isEmpty
                  ? const Center(child: Text('표시할 메모가 없습니다.'))
                  : ListView.builder(
                      itemCount: allEntries.length,
                      itemBuilder: (context, index) {
                        final entry = allEntries[index];
                        final date = entry.date != null
                            ? DateFormat('yyyy-MM-dd').format(DateTime.parse(entry.date!))
                            : DateFormat('yyyy-MM-dd').format(entry.updatedAt);
                        
                        return ListTile(
                          title: Text(
                            entry.title.isEmpty ? '제목 없음' : entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: entry.type == EntryType.dated 
                                          ? Colors.blue.withOpacity(0.1)
                                          : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: entry.type == EntryType.dated 
                                            ? Colors.blue.withOpacity(0.3)
                                            : Colors.green.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      entry.type == EntryType.dated ? '날짜별' : '일반',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: entry.type == EntryType.dated 
                                            ? Colors.blue[700]
                                            : Colors.green[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(date)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: entry.type == EntryType.dated 
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (entry.moods.isNotEmpty)
                                      Text(entry.moods.join(' ')),
                                    if (entry.customEmojis.isNotEmpty)
                                      Text(entry.customEmojis.join(' ')),
                                  ],
                                )
                              : null,
                          onTap: () {
                            Navigator.of(context).pop();
                            _showWidgetIdDialog(context, entry);
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
            ],
          );
        },
      ),
    );
  }

  // 위젯 ID 입력 다이얼로그
  void _showWidgetIdDialog(BuildContext context, DiaryEntry entry) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('위젯 ID 입력'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('선택한 메모: ${entry.title.isEmpty ? "제목 없음" : entry.title}'),
            const SizedBox(height: 16),
            const Text('위젯 ID를 입력하세요 (예: 1, 2, 3...)'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '위젯 ID',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final widgetIdText = controller.text.trim();
              if (widgetIdText.isNotEmpty) {
                final widgetId = int.tryParse(widgetIdText);
                if (widgetId != null) {
                  // 이 기능은 더 이상 사용되지 않습니다.
                  // 단일 메모 위젯은 자체 설정 화면이 있습니다.
                  // final widgetService = WidgetService();
                  // await widgetService.setMemoForWidget(widgetId, entry.id);
                  
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('이 기능은 더 이상 사용되지 않습니다.\n홈 화면에서 단일 메모 위젯을 추가하여 메모를 선택하세요.'),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('올바른 숫자를 입력하세요.'),
                    ),
                  );
                }
              }
            },
            child: const Text('설정'),
          ),
        ],
      ),
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
              // 클립보드에 복사
              await Clipboard.setData(ClipboardData(text: backupData));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('백업 데이터가 클립보드에 복사되었습니다\n메신저나 메모 앱에 붙여넣기 할 수 있습니다'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            child: const Text('클립보드 복사'),
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
        
        // UTF-8 바이트로 변환 (BOM 포함)
        final bytes = JsonUtils.toUtf8Bytes(backupData, includeBom: true);
        await file.writeAsBytes(bytes);

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
      
      // UTF-8 바이트로 변환 (BOM 포함)
      final bytes = JsonUtils.toUtf8Bytes(backupData, includeBom: true);
      await tempFile.writeAsBytes(bytes);

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
        
        // UTF-8 바이트로 변환 (BOM 포함)
        final bytes = JsonUtils.toUtf8Bytes(backupData, includeBom: true);
        await file.writeAsBytes(bytes);

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
                    // 바이트로 읽어서 안전하게 디코딩
                    final bytes = await file.readAsBytes();
                    final jsonData = JsonUtils.decodeFromBytes(bytes);
                    final content = jsonEncode(jsonData); // 정규화된 JSON 문자열
                    
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
        // 바이트로 읽어서 안전하게 디코딩
        final bytes = await file.readAsBytes();
        final jsonData = JsonUtils.decodeFromBytes(bytes);
        final content = jsonEncode(jsonData); // 정규화된 JSON 문자열
        
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
                  // 클립보드에서 데이터 읽기
                  try {
                    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                    if (clipboardData != null && clipboardData.text != null) {
                      final backupData = clipboardData.text!;
                      
                      // 백업 데이터 유효성 검사
                      try {
                        final decoded = JsonUtils.tryDecode(backupData);
                        if (decoded == null) {
                          throw const FormatException('잘못된 백업 파일 형식입니다.');
                        }
                        
                        final hasEntries = decoded.containsKey('entries');
                        final hasSettings = decoded.containsKey('settings');
                        
                        if (!hasEntries || !hasSettings) {
                          throw const FormatException('잘못된 백업 파일 형식입니다.');
                        }
                        
                        // 백업 가져오기 확인 다이얼로그
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('백업 복원'),
                            content: const Text('클립보드의 백업 데이터로 복원하시겠습니까?\n\n현재 데이터는 모두 삭제됩니다.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('복원'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirmed == true) {
                          // 프로그레스 표시
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                          
                          await context.read<DiaryProvider>().importBackup(backupData);
                          await context.read<ThemeProvider>().importBackup(backupData);
                          
                          Navigator.pop(context); // 프로그레스 닫기
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('백업이 성공적으로 복원되었습니다'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('복원 실패: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('클립보드가 비어있습니다'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('클립보드 읽기 실패: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
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
      // JSON 유효성 검사
      try {
        // 잘못된 인코딩으로 인한 문제 방지
        final cleanContent = content.trim();
        
        // JSON 파싱 테스트
        final testParse = jsonDecode(cleanContent);
        if (testParse is! Map<String, dynamic>) {
          throw const FormatException('잘못된 백업 파일 형식입니다.');
        }
        
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
                    await context.read<DiaryProvider>().importBackup(cleanContent);
                    
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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('백업 파일 형식이 올바르지 않습니다: $e'),
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
