/**
 * 다이어리 데이터 관리 Provider 클래스
 * 
 * 다이어리 앱의 핵심 비즈니스 로직과 상태 관리를 담당하는 Provider 클래스입니다.
 * ChangeNotifier를 상속받아 상태 변경 시 UI에 자동으로 알림을 제공합니다.
 * 
 * 주요 기능:
 * - 일기 항목의 CRUD 작업 (생성, 읽기, 수정, 삭제)
 * - 날짜별 일기와 일반 메모 관리
 * - 검색 및 필터링 기능
 * - 백업 및 복원 기능
 * - 통계 정보 제공
 * - 로컬 스토리지와의 연동
 */

import 'package:flutter/material.dart';
import 'package:diary_app/core/models/diary_entry.dart';
import 'package:diary_app/core/services/storage_service.dart';
import 'package:diary_app/core/services/widget_service.dart';

/**
 * 다이어리 Provider 클래스
 * 
 * 앱의 모든 일기 데이터와 관련 상태를 관리하는 중앙 집중식 상태 관리자입니다.
 * Provider 패턴을 사용하여 위젯 트리 전체에 데이터를 공유합니다.
 */
class DiaryProvider extends ChangeNotifier {
  /// 모든 일기 항목을 저장하는 메인 리스트
  List<DiaryEntry> _entries = [];
  
  /// 검색 및 필터링 결과를 저장하는 리스트
  List<DiaryEntry> _filteredEntries = [];
  
  /// 현재 선택된 날짜 (캘린더에서 사용)
  DateTime _selectedDate = DateTime.now();
  
  /// 현재 검색어
  String _searchQuery = '';
  
  /// 현재 선택된 태그 필터 목록
  List<String> _selectedTags = [];
  
  /// 데이터 로딩 상태 플래그
  bool _isLoading = false;
  
  /// 위젯 서비스 (홈 화면 위젯 업데이트용)
  final WidgetService _widgetService = WidgetService();

  /**
   * 모든 일기 항목을 반환하는 getter
   * @return List<DiaryEntry> : 전체 일기 항목 목록
   */
  List<DiaryEntry> get entries => _entries;
  
  /**
   * 필터링된 일기 항목을 반환하는 getter
   * 검색어나 태그 필터가 적용된 경우 필터링된 결과를, 그렇지 않으면 전체 목록을 반환
   * @return List<DiaryEntry> : 필터링된 일기 항목 목록
   */
  List<DiaryEntry> get filteredEntries => _searchQuery.isNotEmpty || _selectedTags.isNotEmpty 
      ? _filteredEntries 
      : _entries;
      
  /**
   * 현재 선택된 날짜를 반환하는 getter
   * @return DateTime : 현재 선택된 날짜
   */
  DateTime get selectedDate => _selectedDate;
  
  /**
   * 현재 검색어를 반환하는 getter
   * @return String : 현재 검색어
   */
  String get searchQuery => _searchQuery;
  
  /**
   * 현재 선택된 태그 목록을 반환하는 getter
   * @return List<String> : 선택된 태그 목록
   */
  List<String> get selectedTags => _selectedTags;
  
  /**
   * 데이터 로딩 상태를 반환하는 getter
   * @return bool : 로딩 중이면 true, 아니면 false
   */
  bool get isLoading => _isLoading;

  /**
   * 날짜별 일기만 필터링하여 반환하는 getter
   * 특정 날짜에 작성된 일기들만 가져옵니다.
   * @return List<DiaryEntry> : 날짜별 일기 목록
   */
  List<DiaryEntry> get datedEntries => _entries.where((e) => e.type == EntryType.dated).toList();
  
  /**
   * 일반 메모만 필터링하여 반환하는 getter
   * 날짜에 구애받지 않는 일반 메모들만 가져옵니다.
   * @return List<DiaryEntry> : 일반 메모 목록
   */
  List<DiaryEntry> get generalNotes => _entries.where((e) => e.type == EntryType.general).toList();

  /**
   * DiaryProvider 생성자
   * 
   * Provider가 생성될 때 자동으로 저장된 일기 데이터를 로드합니다.
   * 앱 시작 시 기존 데이터를 복원하는 역할을 합니다.
   */
  DiaryProvider() {
    loadEntries();
  }

  /**
   * 저장된 모든 일기 항목을 로드하는 비동기 메서드
   * 
   * 로컬 스토리지에서 모든 일기 데이터를 읽어와 메모리에 로드합니다.
   * 로딩 중에는 isLoading 플래그를 true로 설정하여 UI에 로딩 상태를 알립니다.
   * 로드 완료 후 데이터를 정렬하고 필터를 적용합니다.
   * 
   * @throws Exception : 스토리지 읽기 실패 시 예외 발생
   */
  Future<void> loadEntries() async {
    // 로딩 상태 활성화 및 UI 업데이트
    _isLoading = true;
    notifyListeners();
    
    try {
      // 스토리지 서비스를 통해 모든 일기 항목 로드
      _entries = await StorageService.instance.loadAllEntries();
      // 데이터 정렬 적용
      _sortEntries();
      // 현재 활성화된 필터 적용
      _applyFilters();
    } catch (e) {
      // 로드 실패 시 에러 로그 출력
      debugPrint('Failed to load entries: $e');
    } finally {
      // 로딩 상태 비활성화 및 UI 업데이트
      _isLoading = false;
      notifyListeners();
      
      // 위젯 업데이트 (날짜별 메모 데이터가 변경되었을 수 있음)
      // 항상 전체 데이터를 업데이트하여 SingleMemoWidget 설정 화면에서 사용
      await _widgetService.updateWidget();
    }
  }

  /**
   * 선택된 날짜를 설정하는 메서드
   * 
   * 캘린더에서 날짜를 선택했을 때 호출되며, 선택된 날짜를 업데이트하고 UI에 알립니다.
   * 해당 날짜의 일기를 조회하거나 새 일기를 작성할 때 사용됩니다.
   * 
   * @param date : 선택할 날짜
   */
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /**
   * 특정 날짜의 일기 항목을 조회하는 메서드
   * 
   * 지정된 날짜에 작성된 일기가 있는지 확인하고 반환합니다.
   * 날짜별 일기는 하루에 하나만 작성 가능하므로 첫 번째 매치 항목을 반환합니다.
   * 
   * @param date : 조회할 날짜
   * @return DiaryEntry? : 해당 날짜의 일기 (없으면 null)
   */
  DiaryEntry? getEntryForDate(DateTime date) {
    // 날짜를 문자열 형식으로 변환
    final dateString = _formatDate(date);
    try {
      // 날짜별 일기 중에서 해당 날짜와 매치되는 항목 찾기
      return _entries.where((entry) => 
        entry.type == EntryType.dated && entry.date == dateString
      ).first;
    } catch (e) {
      // 해당 날짜의 일기가 없으면 null 반환
      return null;
    }
  }

  /**
   * 특정 월의 모든 일기 항목을 조회하는 메서드
   * 
   * 지정된 월에 작성된 날짜별 일기들을 모두 가져옵니다.
   * 캘린더 뷰에서 해당 월의 일기 표시나 월별 통계에 사용됩니다.
   * 
   * @param month : 조회할 월 (DateTime 객체)
   * @return List<DiaryEntry> : 해당 월의 일기 목록
   */
  List<DiaryEntry> getEntriesForMonth(DateTime month) {
    return _entries.where((entry) {
      // 날짜별 일기이고 날짜가 설정된 항목만 필터링
      if (entry.type != EntryType.dated || entry.date == null) return false;
      // 일기 날짜를 파싱하여 년도와 월이 일치하는지 확인
      final entryDate = DateTime.parse(entry.date!);
      return entryDate.year == month.year && entryDate.month == month.month;
    }).toList();
  }

  /**
   * 새로운 일기 항목을 추가하는 비동기 메서드
   * 
   * 새 일기나 메모를 생성하여 로컬 스토리지에 저장하고 메모리 목록에 추가합니다.
   * 저장 후 자동으로 정렬과 필터링을 적용하여 UI를 업데이트합니다.
   * 
   * @param entry : 추가할 일기 항목
   * @throws Exception : 저장 실패 시 예외 발생
   */
  Future<void> addEntry(DiaryEntry entry) async {
    try {
      // 스토리지 서비스를 통해 일기 항목 저장
      // 날짜별 메모의 경우 하루에 1개만 허용 (UI에서 처리하므로 여기서는 단순 추가)
      await StorageService.instance.saveEntry(entry);
      
      // 메모리 목록에 새 항목 추가
      _entries.add(entry);
      
      // 목록 재정렬 (날짜순/수정시간순)
      _sortEntries();
      
      // 현재 필터 조건 다시 적용
      _applyFilters();
      
      // UI 업데이트 알림
      notifyListeners();
      
      // 위젯 업데이트 (날짜별 메모와 일반 메모 모두 업데이트)
      await _widgetService.updateWidget();
    } catch (e) {
      // 추가 실패 시 에러 로그 출력 후 예외 재발생
      debugPrint('Failed to add entry: $e');
      rethrow;
    }
  }

  /**
   * 기존 일기 항목을 수정하는 비동기 메서드
   * 
   * 기존 일기의 내용을 수정하여 로컬 스토리지에 저장하고 메모리 목록을 업데이트합니다.
   * ID를 기준으로 기존 항목을 찾아 교체하며, 수정 후 자동으로 정렬과 필터링을 적용합니다.
   * 
   * @param entry : 수정된 일기 항목 (기존 ID 유지)
   * @throws Exception : 저장 실패 시 예외 발생
   */
  Future<void> updateEntry(DiaryEntry entry) async {
    try {
      // 스토리지 서비스를 통해 수정된 일기 항목 저장
      await StorageService.instance.saveEntry(entry);
      
      // ID로 기존 엔트리를 찾아서 업데이트
      final existingIndex = _entries.indexWhere((e) => e.id == entry.id);
      if (existingIndex != -1) {
        _entries[existingIndex] = entry;
      }
      
      // 목록 재정렬 (수정 시간 변경으로 인한 순서 조정)
      _sortEntries();
      
      // 현재 필터 조건 다시 적용
      _applyFilters();
      
      // UI 업데이트 알림
      notifyListeners();
      
      // 위젯 업데이트 (날짜별 메모와 일반 메모 모두 업데이트)
      await _widgetService.updateWidget();
    } catch (e) {
      // 수정 실패 시 에러 로그 출력 후 예외 재발생
      debugPrint('Failed to update entry: $e');
      rethrow;
    }
  }

  Future<void> saveEntry(DiaryEntry entry) async {
    // 기존 코드와의 호환성을 위해 유지
    if (_entries.any((e) => e.id == entry.id)) {
      await updateEntry(entry);
    } else {
      await addEntry(entry);
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      final entry = _entries.firstWhere((e) => e.id == id);
      await StorageService.instance.deleteEntry(id);
      _entries.removeWhere((entry) => entry.id == id);
      _applyFilters();
      notifyListeners();
      
      // 위젯 업데이트 (날짜별 메모와 일반 메모 모두 업데이트)
      await _widgetService.updateWidget();
    } catch (e) {
      debugPrint('Failed to delete entry: $e');
      rethrow;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setSelectedTags(List<String> tags) {
    _selectedTags = tags;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedTags = [];
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredEntries = _entries.where((entry) {
      // 검색어 필터
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        if (!entry.title.toLowerCase().contains(searchLower) &&
            !entry.content.toLowerCase().contains(searchLower)) {
          return false;
        }
      }
      
      // 태그 필터
      if (_selectedTags.isNotEmpty) {
        if (!_selectedTags.any((tag) => entry.tags.contains(tag))) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  void _sortEntries() {
    _entries.sort((a, b) {
      // 날짜별 메모는 날짜순으로, 일반 메모는 수정시간순으로 정렬
      if (a.type == EntryType.dated && b.type == EntryType.dated) {
        return b.date!.compareTo(a.date!);
      } else if (a.type == EntryType.general && b.type == EntryType.general) {
        return b.updatedAt.compareTo(a.updatedAt);
      } else {
        // 타입이 다른 경우 날짜별 메모를 먼저
        return a.type == EntryType.dated ? -1 : 1;
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 백업 및 복원
  Future<String> exportBackup() async {
    try {
      return await StorageService.instance.exportBackup();
    } catch (e) {
      debugPrint('Failed to export backup: $e');
      rethrow;
    }
  }

  Future<void> importBackup(String backupData) async {
    try {
      await StorageService.instance.importBackup(backupData);
      await loadEntries();
    } catch (e) {
      debugPrint('Failed to import backup: $e');
      rethrow;
    }
  }

  Future<void> deleteAllEntries() async {
    try {
      // 모든 엔트리 삭제
      for (final entry in _entries) {
        await StorageService.instance.deleteEntry(entry.id);
      }
      _entries.clear();
      _filteredEntries.clear();
      notifyListeners();
      
      // 위젯 업데이트
      await _widgetService.updateWidget();
    } catch (e) {
      debugPrint('Failed to delete all entries: $e');
      rethrow;
    }
  }

  // 통계 정보
  int get totalEntries => _entries.length;
  int get totalDatedEntries => datedEntries.length;
  int get totalGeneralNotes => generalNotes.length;
  
  int get thisMonthEntries {
    final now = DateTime.now();
    return datedEntries.where((entry) {
      if (entry.date == null) return false;
      final entryDate = DateTime.parse(entry.date!);
      return entryDate.year == now.year && entryDate.month == now.month;
    }).length;
  }

  Map<String, int> get tagFrequency {
    final frequency = <String, int>{};
    for (final entry in _entries) {
      for (final tag in entry.tags) {
        frequency[tag] = (frequency[tag] ?? 0) + 1;
      }
    }
    return frequency;
  }

  Map<String, int> get iconFrequency {
    final frequency = <String, int>{};
    for (final entry in _entries) {
      for (final icon in entry.icons) {
        frequency[icon] = (frequency[icon] ?? 0) + 1;
      }
    }
    return frequency;
  }
}
