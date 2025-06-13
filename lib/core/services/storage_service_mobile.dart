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
      final directory = await _appDirectory;
      final file = File('${directory.path}/${entry.date}.json');
      final jsonString = jsonEncode(entry.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('Failed to save diary entry: $e');
    }
  }

  // Load diary entry for specific date
  Future<DiaryEntry?> loadDiaryEntry(String date) async {
    try {
      final directory = await _appDirectory;
      final file = File('${directory.path}/$date.json');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        return DiaryEntry.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load diary entry: $e');
    }
  }

  // Load all diary entries
  Future<List<DiaryEntry>> loadAllEntries() async {
    try {
      final directory = await _appDirectory;
      final files = directory.listSync()
          .where((file) => file.path.endsWith('.json') && 
                         !file.path.endsWith(_settingsFileName))
          .cast<File>();

      final entries = <DiaryEntry>[];
      
      for (final file in files) {
        try {
          final jsonString = await file.readAsString();
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          entries.add(DiaryEntry.fromJson(jsonData));
        } catch (e) {
          // Skip invalid files
          print('Skipping invalid file: ${file.path}');
        }
      }

      // Sort by date descending
      entries.sort((a, b) => b.date.compareTo(a.date));
      return entries;
    } catch (e) {
      throw Exception('Failed to load diary entries: $e');
    }
  }

  // Delete diary entry
  Future<void> deleteEntry(String date) async {
    try {
      final directory = await _appDirectory;
      final file = File('${directory.path}/$date.json');
      
      if (await file.exists()) {
        await file.delete();
      }
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
      await file.writeAsString(jsonString);
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
        final jsonString = await file.readAsString();
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
    final directory = await _appDirectory;
    final file = File('${directory.path}/$date.json');
    return await file.exists();
  }
}
