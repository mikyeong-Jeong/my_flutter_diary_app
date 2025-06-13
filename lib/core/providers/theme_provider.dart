import 'package:flutter/material.dart';
import 'package:diary_app/core/models/app_settings.dart';
import 'package:diary_app/core/services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings();
  
  AppSettings get settings => _settings;
  
  ThemeMode get themeMode {
    if (_settings.isSystemTheme) {
      return ThemeMode.system;
    }
    return _settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDarkMode => _settings.isDarkMode;
  bool get isSystemTheme => _settings.isSystemTheme;
  bool get isLockEnabled => _settings.isLockEnabled;
  String? get lockPassword => _settings.lockPassword;
  List<String> get customIcons => _settings.customIcons;
  List<String> get customTags => _settings.customTags;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _settings = await StorageService.instance.loadSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }
  }

  Future<void> toggleDarkMode() async {
    _settings = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
    await _saveSettings();
  }

  Future<void> setSystemTheme(bool value) async {
    _settings = _settings.copyWith(isSystemTheme: value);
    await _saveSettings();
  }

  Future<void> setLockEnabled(bool value) async {
    _settings = _settings.copyWith(isLockEnabled: value);
    await _saveSettings();
  }

  Future<void> setLockPassword(String? password) async {
    _settings = _settings.copyWith(lockPassword: password);
    await _saveSettings();
  }

  Future<void> addCustomIcon(String icon) async {
    if (!_settings.customIcons.contains(icon)) {
      final newIcons = List<String>.from(_settings.customIcons)..add(icon);
      _settings = _settings.copyWith(customIcons: newIcons);
      await _saveSettings();
    }
  }

  Future<void> removeCustomIcon(String icon) async {
    final newIcons = List<String>.from(_settings.customIcons)..remove(icon);
    _settings = _settings.copyWith(customIcons: newIcons);
    await _saveSettings();
  }

  Future<void> addCustomTag(String tag) async {
    if (!_settings.customTags.contains(tag)) {
      final newTags = List<String>.from(_settings.customTags)..add(tag);
      _settings = _settings.copyWith(customTags: newTags);
      await _saveSettings();
    }
  }

  Future<void> removeCustomTag(String tag) async {
    final newTags = List<String>.from(_settings.customTags)..remove(tag);
    _settings = _settings.copyWith(customTags: newTags);
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    try {
      await StorageService.instance.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  // 기본 아이콘들
  List<String> get defaultIcons => [
    '😊', '😢', '😡', '😍', '🤔',
    '💪', '📖', '🏃', '🍔', '☕',
    '🌞', '🌙', '⭐', '❤️', '👍',
    '💼', '🎵', '🎬', '🎮', '📱',
  ];

  // 기본 태그들
  List<String> get defaultTags => [
    '자기계발', '운동', '독서', '일기',
    '감정', '회고', '계획', '목표',
    '가족', '친구', '직장', '취미',
    '건강', '여행', '음식', '공부',
  ];

  // 모든 아이콘 (기본 + 커스텀)
  List<String> get allIcons => [...defaultIcons, ...customIcons];

  // 모든 태그 (기본 + 커스텀)
  List<String> get allTags => [...defaultTags, ...customTags];

  // Get default emotion icons
  static List<String> get defaultEmotionIcons => [
    '😊', '😢', '😡', '😴', '🤔', 
    '💪', '❤️', '🎉', '📚', '🏃‍♂️',
    '🍕', '☕', '🎵', '🌟', '🔥'
  ];

  // Get all available icons (default + custom) - 별칭
  List<String> get allAvailableIcons => allIcons;

  // Get all available tags (default + custom) - 별칭
  List<String> get allAvailableTags => allTags;

  // Export backup
  Future<String> exportBackup() async {
    try {
      return await StorageService.instance.exportBackup();
    } catch (e) {
      throw Exception('백업 내보내기 실패: $e');
    }
  }

  // Import backup
  Future<void> importBackup(String backupData) async {
    try {
      await StorageService.instance.importBackup(backupData);
      await _loadSettings();
    } catch (e) {
      throw Exception('백업 가져오기 실패: $e');
    }
  }
}
