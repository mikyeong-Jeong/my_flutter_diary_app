import 'dart:convert';
import '../models/diary_entry.dart';
import '../models/app_settings.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;
  StorageService._internal();
  
  // 웹 환경용 메모리 저장소
  final Map<String, DiaryEntry> _webEntries = {};
  AppSettings _webSettings = AppSettings();
  
  Future<void> initialize() async {
    // Initialize storage service
  }

  // Save diary entry
  Future<void> saveEntry(DiaryEntry entry) async {
    _webEntries[entry.date] = entry;
  }

  // Load diary entry for specific date
  Future<DiaryEntry?> loadDiaryEntry(String date) async {
    return _webEntries[date];
  }

  // Load all diary entries
  Future<List<DiaryEntry>> loadAllEntries() async {
    final entries = _webEntries.values.toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  // Delete diary entry
  Future<void> deleteEntry(String date) async {
    _webEntries.remove(date);
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
    _webSettings = settings;
  }

  // Load app settings
  Future<AppSettings> loadAppSettings() async {
    return _webSettings;
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
        for (final entryData in entriesData) {
          final entry = DiaryEntry.fromJson(entryData as Map<String, dynamic>);
          await saveEntry(entry);
        }
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

  // Get entries for specific month
  Future<List<DiaryEntry>> getEntriesForMonth(int year, int month) async {
    final allEntries = await loadAllEntries();
    
    return allEntries.where((entry) {
      final entryDate = DateTime.parse(entry.date);
      return entryDate.year == year && entryDate.month == month;
    }).toList();
  }

  // Check if entry exists for date
  Future<bool> hasEntryForDate(String date) async {
    return _webEntries.containsKey(date);
  }
}
