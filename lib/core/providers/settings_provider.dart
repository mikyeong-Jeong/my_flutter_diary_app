import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';

class SettingsProvider with ChangeNotifier {
  final StorageService _storageService = StorageService.instance;
  
  AppSettings _settings = AppSettings();
  bool _isLoading = false;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  // Theme getters
  bool get isDarkMode => _settings.isDarkMode;
  bool get isSystemTheme => _settings.isSystemTheme;
  ThemeMode get themeMode {
    if (_settings.isSystemTheme) return ThemeMode.system;
    return _settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  // Lock getters
  bool get isLockEnabled => _settings.isLockEnabled;
  String? get lockPassword => _settings.lockPassword;

  // Custom data getters
  List<String> get customIcons => _settings.customIcons;
  List<String> get customTags => _settings.customTags;

  // Load settings
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _storageService.loadAppSettings();
    } catch (e) {
      // Use default settings on error
      _settings = AppSettings();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update theme settings
  Future<void> updateThemeSettings({bool? isDarkMode, bool? isSystemTheme}) async {
    _settings = _settings.copyWith(
      isDarkMode: isDarkMode,
      isSystemTheme: isSystemTheme,
    );
    
    await _saveSettings();
  }

  // Update lock settings
  Future<void> updateLockSettings({bool? isLockEnabled, String? lockPassword}) async {
    _settings = _settings.copyWith(
      isLockEnabled: isLockEnabled,
      lockPassword: lockPassword,
    );
    
    await _saveSettings();
  }

  // Add custom icon
  Future<void> addCustomIcon(String icon) async {
    if (!_settings.customIcons.contains(icon)) {
      final updatedIcons = List<String>.from(_settings.customIcons)..add(icon);
      _settings = _settings.copyWith(customIcons: updatedIcons);
      await _saveSettings();
    }
  }

  // Remove custom icon
  Future<void> removeCustomIcon(String icon) async {
    final updatedIcons = List<String>.from(_settings.customIcons)..remove(icon);
    _settings = _settings.copyWith(customIcons: updatedIcons);
    await _saveSettings();
  }

  // Add custom tag
  Future<void> addCustomTag(String tag) async {
    if (!_settings.customTags.contains(tag)) {
      final updatedTags = List<String>.from(_settings.customTags)..add(tag);
      _settings = _settings.copyWith(customTags: updatedTags);
      await _saveSettings();
    }
  }

  // Remove custom tag
  Future<void> removeCustomTag(String tag) async {
    final updatedTags = List<String>.from(_settings.customTags)..remove(tag);
    _settings = _settings.copyWith(customTags: updatedTags);
    await _saveSettings();
  }

  // Export backup
  Future<String> exportBackup() async {
    try {
      return await _storageService.exportBackup();
    } catch (e) {
      throw Exception('백업 내보내기 실패: $e');
    }
  }

  // Import backup
  Future<void> importBackup(String backupData) async {
    try {
      await _storageService.importBackup(backupData);
      await loadSettings();
    } catch (e) {
      throw Exception('백업 가져오기 실패: $e');
    }
  }

  // Private method to save settings
  Future<void> _saveSettings() async {
    try {
      await _storageService.saveAppSettings(_settings);
      notifyListeners();
    } catch (e) {
      throw Exception('설정 저장 실패: $e');
    }
  }

  // Get default emotion icons
  static List<String> get defaultEmotionIcons => [
    '😊', '😢', '😡', '😴', '🤔', 
    '💪', '❤️', '🎉', '📚', '🏃‍♂️',
    '🍕', '☕', '🎵', '🌟', '🔥'
  ];

  // Get default tags
  static List<String> get defaultTags => [
    '자기계발', '운동', '독서', '업무', '가족',
    '친구', '여행', '요리', '영화', '음악',
    '건강', '취미', '공부', '휴식', '감사'
  ];

  // Get all available icons (default + custom)
  List<String> get allAvailableIcons => [
    ...defaultEmotionIcons,
    ...customIcons,
  ];

  // Get all available tags (default + custom)
  List<String> get allAvailableTags => [
    ...defaultTags,
    ...customTags,
  ];
}
