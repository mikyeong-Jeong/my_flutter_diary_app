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
    // 저장소 서비스 초기화
  }

  // 일기 항목 저장
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
      throw Exception('일기 저장에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  // 모든 항목을 localStorage에 저장
  void _saveAllEntries(List<DiaryEntry> entries) {
    try {
      final jsonString = jsonEncode({
        'entries': entries.map((e) => e.toJson()).toList(),
      });
      html.window.localStorage[_entriesKey] = jsonString;
    } catch (e) {
      throw Exception('데이터 저장에 실패했습니다.');
    }
  }

  // ID로 일기 항목 로드
  Future<DiaryEntry?> loadDiaryEntryById(String id) async {
    try {
      final entries = await loadAllEntries();
      return entries.firstWhere(
        (e) => e.id == id,
        orElse: () => throw Exception('해당 일기를 찾을 수 없습니다.'),
      );
    } catch (e) {
      return null;
    }
  }

  // loadEntry 메서드 (loadDiaryEntryById의 별칭)
  Future<DiaryEntry?> loadEntry(String id) async {
    return loadDiaryEntryById(id);
  }

  // 특정 날짜의 일기 항목 로드 (날짜별 메모용)
  Future<DiaryEntry?> loadDiaryEntry(String date) async {
    try {
      final entries = await loadAllEntries();
      return entries.firstWhere(
        (e) => e.type == EntryType.dated && e.date == date,
        orElse: () => throw Exception('해당 일기를 찾을 수 없습니다.'),
      );
    } catch (e) {
      return null;
    }
  }

  // 모든 일기 항목 로드
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

  // ID로 일기 항목 삭제
  Future<void> deleteEntry(String id) async {
    try {
      final entries = await loadAllEntries();
      entries.removeWhere((entry) => entry.id == id);
      _saveAllEntries(entries);
    } catch (e) {
      throw Exception('일기 삭제에 실패했습니다.');
    }
  }

  // 일기 항목 검색
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

  // 앱 설정 저장
  Future<void> saveSettings(AppSettings settings) async {
    return saveAppSettings(settings);
  }

  // 앱 설정 로드
  Future<AppSettings> loadSettings() async {
    return loadAppSettings();
  }

  // 앱 설정 저장
  Future<void> saveAppSettings(AppSettings settings) async {
    try {
      final jsonString = jsonEncode(settings.toJson());
      html.window.localStorage[_settingsKey] = jsonString;
    } catch (e) {
      throw Exception('설정 저장에 실패했습니다.');
    }
  }

  // 앱 설정 로드
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

  // 백업 내보내기
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
      throw Exception('백업 내보내기에 실패했습니다.');
    }
  }

  // 백업 가져오기
  Future<void> importBackup(String backupJson) async {
    try {
      final backupData = jsonDecode(backupJson) as Map<String, dynamic>;
      
      // 항목 가져오기
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
      
      // 설정 가져오기
      if (backupData['settings'] != null) {
        final settings = AppSettings.fromJson(backupData['settings'] as Map<String, dynamic>);
        await saveAppSettings(settings);
      }
    } catch (e) {
      throw Exception('백업 가져오기에 실패했습니다.');
    }
  }

  // 특정 월의 항목 가져오기 (날짜별 메모만)
  Future<List<DiaryEntry>> getEntriesForMonth(int year, int month) async {
    final allEntries = await loadAllEntries();
    
    return allEntries.where((entry) {
      if (entry.type != EntryType.dated || entry.date == null) return false;
      final entryDate = DateTime.parse(entry.date!);
      return entryDate.year == year && entryDate.month == month;
    }).toList();
  }

  // 특정 날짜에 항목이 있는지 확인
  Future<bool> hasEntryForDate(String date) async {
    final entries = await loadAllEntries();
    return entries.any((e) => e.type == EntryType.dated && e.date == date);
  }
}
