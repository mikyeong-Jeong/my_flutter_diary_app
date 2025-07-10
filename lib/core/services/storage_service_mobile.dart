import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/diary_entry.dart';
import '../models/app_settings.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;
  StorageService._internal();
  
  static const String _settingsFileName = 'app_settings.json';
  static const String _entriesFileName = 'diary_entries.json';
  
  Future<void> initialize() async {
    // Initialize storage service
  }
  
  // Get app directory
  Future<Directory> get _appDirectory async {
    final directory = await getApplicationDocumentsDirectory();
    final appDir = Directory('${directory.path}/diary_app');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  // Save diary entry
  Future<void> saveEntry(DiaryEntry entry) async {
    try {
      final entries = await loadAllEntries();
      
      // ID로 기존 엔트리 찾기
      final existingIndex = entries.indexWhere((e) => e.id == entry.id);
      if (existingIndex != -1) {
        entries[existingIndex] = entry;
      } else {
        entries.add(entry);
      }
      
      // 모든 엔트리 저장
      await _saveAllEntries(entries);
    } catch (e) {
      throw Exception('Failed to save diary entry: $e');
    }
  }

  // Save all entries to file
  Future<void> _saveAllEntries(List<DiaryEntry> entries) async {
    try {
      final directory = await _appDirectory;
      final file = File('${directory.path}/$_entriesFileName');
      final jsonString = jsonEncode({
        'entries': entries.map((e) => e.toJson()).toList(),
      });
      await file.writeAsString(jsonString, encoding: utf8);
    } catch (e) {
      throw Exception('Failed to save entries: $e');
    }
  }

  // Load diary entry by ID
  Future<DiaryEntry?> loadDiaryEntryById(String id) async {
    try {
      final entries = await loadAllEntries();
      return entries.firstWhere(
        (e) => e.id == id,
        orElse: () => throw Exception('Entry not found'),
      );
    } catch (e) {
      return null;
    }
  }

  // Load diary entry for specific date (날짜별 메모용)
  Future<DiaryEntry?> loadDiaryEntry(String date) async {
    try {
      final entries = await loadAllEntries();
      return entries.firstWhere(
        (e) => e.type == EntryType.dated && e.date == date,
        orElse: () => throw Exception('Entry not found'),
      );
    } catch (e) {
      return null;
    }
  }

  // Load all diary entries
  Future<List<DiaryEntry>> loadAllEntries() async {
    try {
      final directory = await _appDirectory;
      final file = File('${directory.path}/$_entriesFileName');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString(encoding: utf8);
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        final entriesData = jsonData['entries'] as List;
        
        final entries = entriesData
            .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        
        // 정렬: 날짜별 메모는 날짜순, 일반 메모는 수정시간순
        entries.sort((a, b) {
          if (a.type == EntryType.dated && b.type == EntryType.dated) {
            return b.date!.compareTo(a.date!);
          } else if (a.type == EntryType.general && b.type == EntryType.general) {
            return b.updatedAt.compareTo(a.updatedAt);
          } else {
            return a.type == EntryType.dated ? -1 : 1;
          }
        });
        
        return entries;
      }
      return [];
    } catch (e) {
      // 마이그레이션: 기존 개별 파일 방식에서 단일 파일 방식으로
      return await _migrateOldEntries();
    }
  }

  // Migrate old entries from individual files
  Future<List<DiaryEntry>> _migrateOldEntries() async {
    try {
      final directory = await _appDirectory;
      final files = directory.listSync()
          .where((file) => file.path.endsWith('.json') && 
                         !file.path.endsWith(_settingsFileName) &&
                         !file.path.endsWith(_entriesFileName))
          .cast<File>();

      final entries = <DiaryEntry>[];
      
      for (final file in files) {
        try {
          final jsonString = await file.readAsString();
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          
          // 기존 데이터에 새 필드 추가
          if (!jsonData.containsKey('id')) {
            jsonData['id'] = DateTime.now().millisecondsSinceEpoch.toString();
          }
          if (!jsonData.containsKey('type')) {
            jsonData['type'] = 'dated';
          }
          if (!jsonData.containsKey('createdAt')) {
            jsonData['createdAt'] = jsonData['lastModified'] ?? DateTime.now().toIso8601String();
          }
          if (!jsonData.containsKey('updatedAt')) {
            jsonData['updatedAt'] = jsonData['lastModified'] ?? DateTime.now().toIso8601String();
          }
          
          entries.add(DiaryEntry.fromJson(jsonData));
          
          // 마이그레이션 후 기존 파일 삭제
          await file.delete();
        } catch (e) {
          print('Skipping invalid file: ${file.path}');
        }
      }

      // 새 형식으로 저장
      if (entries.isNotEmpty) {
        await _saveAllEntries(entries);
      }

      return entries;
    } catch (e) {
      return [];
    }
  }

  // Delete diary entry by ID
  Future<void> deleteEntry(String id) async {
    try {
      final entries = await loadAllEntries();
      entries.removeWhere((entry) => entry.id == id);
      await _saveAllEntries(entries);
    } catch (e) {
      throw Exception('Failed to delete diary entry: $e');
    }
  }

  // Search diary entries
  Future<List<DiaryEntry>> searchEntries(String query, {List<String>? tags}) async {
    final allEntries = await loadAllEntries();
    
    return allEntries.where((entry) {
      final titleMatch = entry.title.toLowerCase().contains(query.toLowerCase());
      final contentMatch = entry.content.toLowerCase().contains(query.toLowerCase());
      final tagMatch = tags == null || tags.isEmpty || 
          tags.any((tag) => entry.tags.contains(tag));
      
      return (titleMatch || contentMatch) && tagMatch;
    }).toList();
  }

  // Save app settings
  Future<void> saveSettings(AppSettings settings) async {
    return saveAppSettings(settings);
  }

  // Load app settings
  Future<AppSettings> loadSettings() async {
    return loadAppSettings();
  }

  // Save app settings
  Future<void> saveAppSettings(AppSettings settings) async {
    try {
      final directory = await _appDirectory;
      final file = File('${directory.path}/$_settingsFileName');
      final jsonString = jsonEncode(settings.toJson());
      await file.writeAsString(jsonString, encoding: utf8);
    } catch (e) {
      throw Exception('Failed to save app settings: $e');
    }
  }

  // Load app settings
  Future<AppSettings> loadAppSettings() async {
    try {
      final directory = await _appDirectory;
      final file = File('${directory.path}/$_settingsFileName');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString(encoding: utf8);
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        return AppSettings.fromJson(jsonData);
      }
      
      // Return default settings if file doesn't exist
      return AppSettings();
    } catch (e) {
      // Return default settings on error
      return AppSettings();
    }
  }

  // Export backup
  Future<String> exportBackup() async {
    try {
      final entries = await loadAllEntries();
      final settings = await loadAppSettings();
      
      final backupData = {
        'entries': entries.map((e) => e.toJson()).toList(),
        'settings': settings.toJson(),
        'exportDate': DateTime.now().toIso8601String(),
        'version': '2.0', // 새 버전
      };
      
      return jsonEncode(backupData);
    } catch (e) {
      throw Exception('Failed to export backup: $e');
    }
  }

  // Import backup
  Future<void> importBackup(String backupJson) async {
    try {
      final backupData = jsonDecode(backupJson) as Map<String, dynamic>;
      
      // Import entries
      if (backupData['entries'] != null) {
        final entriesData = backupData['entries'] as List;
        final entries = <DiaryEntry>[];
        
        for (final entryData in entriesData) {
          final data = entryData as Map<String, dynamic>;
          
          // 구버전 호환성
          if (!data.containsKey('id')) {
            data['id'] = DateTime.now().millisecondsSinceEpoch.toString();
          }
          if (!data.containsKey('type')) {
            data['type'] = 'dated';
          }
          if (!data.containsKey('createdAt')) {
            data['createdAt'] = data['lastModified'] ?? DateTime.now().toIso8601String();
          }
          if (!data.containsKey('updatedAt')) {
            data['updatedAt'] = data['lastModified'] ?? DateTime.now().toIso8601String();
          }
          
          entries.add(DiaryEntry.fromJson(data));
        }
        
        await _saveAllEntries(entries);
      }
      
      // Import settings
      if (backupData['settings'] != null) {
        final settings = AppSettings.fromJson(backupData['settings'] as Map<String, dynamic>);
        await saveAppSettings(settings);
      }
    } catch (e) {
      throw Exception('Failed to import backup: $e');
    }
  }

  // Get entries for specific month (날짜별 메모만)
  Future<List<DiaryEntry>> getEntriesForMonth(int year, int month) async {
    final allEntries = await loadAllEntries();
    
    return allEntries.where((entry) {
      if (entry.type != EntryType.dated || entry.date == null) return false;
      final entryDate = DateTime.parse(entry.date!);
      return entryDate.year == year && entryDate.month == month;
    }).toList();
  }

  // Check if entry exists for date
  Future<bool> hasEntryForDate(String date) async {
    final entries = await loadAllEntries();
    return entries.any((e) => e.type == EntryType.dated && e.date == date);
  }
}
