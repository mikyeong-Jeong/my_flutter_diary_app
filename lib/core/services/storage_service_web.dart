import 'dart:convert';
import 'dart:html' as html;
import '../models/diary_entry.dart';
import '../models/app_settings.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;
  StorageService._internal();
  
  static const String _entriesKey = 'diary_entries';
  static const String _settingsKey = 'app_settings';
  
  Future<void> initialize() async {
    // Initialize storage service
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
      
      // LocalStorage에 저장
      _saveAllEntries(entries);
    } catch (e) {
      throw Exception('Failed to save diary entry: $e');
    }
  }

  // Save all entries to localStorage
  void _saveAllEntries(List<DiaryEntry> entries) {
    try {
      final jsonString = jsonEncode({
        'entries': entries.map((e) => e.toJson()).toList(),
      });
      html.window.localStorage[_entriesKey] = jsonString;
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
      final jsonString = html.window.localStorage[_entriesKey];
      if (jsonString != null) {
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
      return [];
    }
  }

  // Delete diary entry by ID
  Future<void> deleteEntry(String id) async {
    try {
      final entries = await loadAllEntries();
      entries.removeWhere((entry) => entry.id == id);
      _saveAllEntries(entries);
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
      final jsonString = jsonEncode(settings.toJson());
      html.window.localStorage[_settingsKey] = jsonString;
    } catch (e) {
      throw Exception('Failed to save app settings: $e');
    }
  }

  // Load app settings
  Future<AppSettings> loadAppSettings() async {
    try {
      final jsonString = html.window.localStorage[_settingsKey];
      if (jsonString != null) {
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        return AppSettings.fromJson(jsonData);
      }
      return AppSettings();
    } catch (e) {
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
        'version': '2.0',
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
        
        _saveAllEntries(entries);
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
