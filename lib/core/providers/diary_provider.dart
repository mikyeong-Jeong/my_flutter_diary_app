import 'package:flutter/material.dart';
import 'package:diary_app/core/models/diary_entry.dart';
import 'package:diary_app/core/services/storage_service.dart';
// import 'package:diary_app/core/services/widget_service.dart';

class DiaryProvider extends ChangeNotifier {
  List<DiaryEntry> _entries = [];
  List<DiaryEntry> _filteredEntries = [];
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  List<String> _selectedTags = [];
  bool _isLoading = false;
  
  // final WidgetService _widgetService = WidgetService();

  List<DiaryEntry> get entries => _entries;
  List<DiaryEntry> get filteredEntries => _searchQuery.isNotEmpty || _selectedTags.isNotEmpty 
      ? _filteredEntries 
      : _entries;
  DateTime get selectedDate => _selectedDate;
  String get searchQuery => _searchQuery;
  List<String> get selectedTags => _selectedTags;
  bool get isLoading => _isLoading;

  // 날짜별 메모만 가져오기
  List<DiaryEntry> get datedEntries => _entries.where((e) => e.type == EntryType.dated).toList();
  
  // 일반 메모만 가져오기
  List<DiaryEntry> get generalNotes => _entries.where((e) => e.type == EntryType.general).toList();

  DiaryProvider() {
    loadEntries();
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _entries = await StorageService.instance.loadAllEntries();
      _sortEntries();
      _applyFilters();
    } catch (e) {
      debugPrint('Failed to load entries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  DiaryEntry? getEntryForDate(DateTime date) {
    final dateString = _formatDate(date);
    try {
      return _entries.where((entry) => 
        entry.type == EntryType.dated && entry.date == dateString
      ).first;
    } catch (e) {
      return null;
    }
  }

  List<DiaryEntry> getEntriesForMonth(DateTime month) {
    return _entries.where((entry) {
      if (entry.type != EntryType.dated || entry.date == null) return false;
      final entryDate = DateTime.parse(entry.date!);
      return entryDate.year == month.year && entryDate.month == month.month;
    }).toList();
  }

  Future<void> addEntry(DiaryEntry entry) async {
    try {
      // 날짜별 메모의 경우 하루에 1개만 허용 (UI에서 처리하므로 여기서는 단순 추가)
      await StorageService.instance.saveEntry(entry);
      _entries.add(entry);
      _sortEntries();
      _applyFilters();
      notifyListeners();
      
      // 날짜별 메모인 경우에만 위젯 업데이트
      // if (entry.type == EntryType.dated) {
      //   await _widgetService.updateWidget();
      // }
    } catch (e) {
      debugPrint('Failed to add entry: $e');
      rethrow;
    }
  }

  Future<void> updateEntry(DiaryEntry entry) async {
    try {
      await StorageService.instance.saveEntry(entry);
      
      // ID로 기존 엔트리 찾아서 업데이트
      final existingIndex = _entries.indexWhere((e) => e.id == entry.id);
      if (existingIndex != -1) {
        _entries[existingIndex] = entry;
      }
      
      _sortEntries();
      _applyFilters();
      notifyListeners();
      
      // 날짜별 메모인 경우에만 위젯 업데이트
      // if (entry.type == EntryType.dated) {
      //   await _widgetService.updateWidget();
      // }
    } catch (e) {
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
      
      // 날짜별 메모인 경우에만 위젯 업데이트
      // if (entry.type == EntryType.dated) {
      //   await _widgetService.updateWidget();
      // }
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
      // await _widgetService.updateWidget();
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
