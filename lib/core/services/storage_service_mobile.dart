/**
 * 모바일 플랫폼용 스토리지 서비스 구현
 * 
 * Android/iOS 플랫폼에서 파일 시스템을 사용하여 일기 데이터를 저장하고 관리하는 서비스입니다.
 * Singleton 패턴을 사용하여 앱 전체에서 하나의 인스턴스만 존재하도록 보장합니다.
 * 
 * 주요 기능:
 * - 일기 항목의 CRUD 작업 (생성, 읽기, 수정, 삭제)
 * - 앱 설정 저장 및 로드
 * - 백업 및 복원 기능
 * - 기존 버전과의 호환성 처리 (마이그레이션)
 * - JSON 형식의 데이터 저장
 * 
 * 저장 위치: 앱 전용 Documents 디렉토리
 * 파일 형식: UTF-8 인코딩된 JSON 파일
 */

import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/diary_entry.dart';
import '../models/app_settings.dart';

/**
 * 모바일용 스토리지 서비스 클래스
 * 
 * Singleton 패턴을 구현하여 앱 전체에서 동일한 인스턴스를 사용합니다.
 * 파일 시스템을 통해 JSON 형태로 데이터를 영구 저장합니다.
 */
class StorageService {
  /// Singleton 인스턴스
  static final StorageService _instance = StorageService._internal();
  
  /// 외부에서 접근 가능한 Singleton 인스턴스 getter
  static StorageService get instance => _instance;
  
  /// private 생성자 (Singleton 패턴)
  StorageService._internal();
  
  /// 앱 설정 파일명
  static const String _settingsFileName = 'app_settings.json';
  
  /// 일기 항목들을 저장하는 파일명
  static const String _entriesFileName = 'diary_entries.json';
  
  /**
   * 스토리지 서비스 초기화 메서드
   * 
   * 현재는 특별한 초기화 작업이 필요하지 않지만,
   * 향후 데이터베이스 연결이나 초기 설정이 필요할 때 사용할 수 있습니다.
   */
  Future<void> initialize() async {
    // 현재는 특별한 초기화 작업 없음
    // 향후 필요시 데이터베이스 연결, 마이그레이션 등을 수행
  }
  
  /**
   * 앱 전용 디렉토리를 반환하는 private getter
   * 
   * 시스템의 Documents 디렉토리 하위에 'diary_app' 폴더를 생성하고 반환합니다.
   * 폴더가 존재하지 않으면 자동으로 생성합니다.
   * 
   * @return Future<Directory> : 앱 전용 디렉토리
   * @throws Exception : 디렉토리 생성 실패 시
   */
  Future<Directory> get _appDirectory async {
    // 시스템 Documents 디렉토리 가져오기
    final directory = await getApplicationDocumentsDirectory();
    
    // 앱 전용 하위 디렉토리 경로 설정
    final appDir = Directory('${directory.path}/diary_app');
    
    // 디렉토리가 존재하지 않으면 생성
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    
    return appDir;
  }

  /**
   * 일기 항목을 저장하는 메서드
   * 
   * 새로운 일기를 추가하거나 기존 일기를 수정합니다.
   * ID를 기준으로 기존 항목 여부를 판단하여 추가 또는 수정을 결정합니다.
   * 
   * @param entry : 저장할 일기 항목
   * @throws Exception : 저장 실패 시 예외 발생
   * 
   * 처리 과정:
   * 1. 기존 모든 일기 항목 로드
   * 2. ID로 기존 항목 검색
   * 3. 기존 항목이 있으면 수정, 없으면 추가
   * 4. 전체 목록을 파일에 저장
   */
  Future<void> saveEntry(DiaryEntry entry) async {
    try {
      // 현재 저장된 모든 일기 항목 로드
      final entries = await loadAllEntries();
      
      // ID로 기존 엔트리 찾기
      final existingIndex = entries.indexWhere((e) => e.id == entry.id);
      if (existingIndex != -1) {
        // 기존 항목이 있으면 수정
        entries[existingIndex] = entry;
      } else {
        // 새로운 항목이면 추가
        entries.add(entry);
      }
      
      // 업데이트된 전체 목록을 파일에 저장
      await _saveAllEntries(entries);
    } catch (e) {
      throw Exception('일기 저장에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  // 모든 항목을 파일에 저장
  Future<void> _saveAllEntries(List<DiaryEntry> entries) async {
    try {
      final directory = await _appDirectory;
      final file = File('${directory.path}/$_entriesFileName');
      
      // 디버깅 코드 제거됨
      
      final jsonData = {
        'entries': entries.map((e) => e.toJson()).toList(),
      };
      
      // JSON 문자열 생성
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
      
      // JSON 문자열 생성 완료
      
      await file.writeAsString(jsonString, encoding: utf8);
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

  // 개별 파일에서 이전 항목 마이그레이션
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
          // 유효하지 않은 파일 건너뛰기
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

  // ID로 일기 항목 삭제
  Future<void> deleteEntry(String id) async {
    try {
      final entries = await loadAllEntries();
      entries.removeWhere((entry) => entry.id == id);
      await _saveAllEntries(entries);
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
      final directory = await _appDirectory;
      final file = File('${directory.path}/$_settingsFileName');
      final jsonString = jsonEncode(settings.toJson());
      await file.writeAsString(jsonString, encoding: utf8);
    } catch (e) {
      throw Exception('설정 저장에 실패했습니다.');
    }
  }

  // 앱 설정 로드
  Future<AppSettings> loadAppSettings() async {
    try {
      final directory = await _appDirectory;
      final file = File('${directory.path}/$_settingsFileName');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString(encoding: utf8);
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        return AppSettings.fromJson(jsonData);
      }
      
      // 파일이 없으면 기본 설정 반환
      return AppSettings();
    } catch (e) {
      // 오류 시 기본 설정 반환
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
        'version': '2.0', // 새 버전
      };
      
      // UTF-8 인코딩을 보장하기 위해 먼저 일반 JSON으로 변환 후
      // UTF-8 바이트로 변환했다가 다시 문자열로 변환
      final jsonString = json.encode(backupData);
      final utf8Bytes = utf8.encode(jsonString);
      final utf8String = utf8.decode(utf8Bytes);
      
      // Pretty print를 위한 재포맷팅
      final prettyJson = const JsonEncoder.withIndent('  ').convert(json.decode(utf8String));
      
      // 디버깅: 생성된 JSON 확인
      // 백업 데이터 준비 완료
      
      return prettyJson;
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
        
        await _saveAllEntries(entries);
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

  // 특정 월의 항목 가져오기 (날짜별 멤모만)
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
