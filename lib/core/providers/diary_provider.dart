import 'package:flutter/material.dart';
import 'package:diary_app/core/models/diary_entry.dart';
import 'package:diary_app/core/services/storage_service.dart';

class DiaryProvider extends ChangeNotifier {
  List<DiaryEntry> _entries = [];
  List<DiaryEntry> _filteredEntries = [];
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  List<String> _selectedTags = [];
  bool _isLoading = false;

  List<DiaryEntry> get entries => _entries;
  List<DiaryEntry> get filteredEntries => _filteredEntries;
  DateTime get selectedDate => _selectedDate;
  String get searchQuery => _searchQuery;
  List<String> get selectedTags => _selectedTags;
  bool get isLoading => _isLoading;

  DiaryProvider() {
    loadEntries();
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _entries = await StorageService.instance.loadAllEntries();
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
      return _entries.where((entry) => entry.date == dateString).first;
    } catch (e) {
      return null;
    }
  }

  List<DiaryEntry> getEntriesForMonth(DateTime month) {
    return _entries.where((entry) {
      final entryDate = DateTime.parse(entry.date);
      return entryDate.year == month.year && entryDate.month == month.month;
    }).toList();
  }

  Future<void> saveEntry(DiaryEntry entry) async {
    try {
      await StorageService.instance.saveEntry(entry);
      
      // 기존 엔트리 업데이트 또는 새 엔트리 추가
      final existingIndex = _entries.indexWhere((e) => e.date == entry.date);
      if (existingIndex != -1) {
        _entries[existingIndex] = entry;
      } else {
        _entries.add(entry);
      }
      
      // 날짜순으로 정렬
      _entries.sort((a, b) => b.date.compareTo(a.date));
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save entry: $e');
      rethrow;
    }
  }

  Future<void> deleteEntry(String date) async {
    try {
      await StorageService.instance.deleteEntry(date);
      _entries.removeWhere((entry) => entry.date == date);
      _applyFilters();
      notifyListeners();
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 통계 정보
  int get totalEntries => _entries.length;
  
  int get thisMonthEntries {
    final now = DateTime.now();
    return _entries.where((entry) {
      final entryDate = DateTime.parse(entry.date);
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
}
