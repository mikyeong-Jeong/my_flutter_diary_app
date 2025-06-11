import 'package:json_annotation/json_annotation.dart';

part 'app_settings.g.dart';

@JsonSerializable()
class AppSettings {
  final bool isDarkMode;
  final bool isSystemTheme;
  final bool isLockEnabled;
  final String? lockPassword;
  final List<String> customIcons;
  final List<String> customTags;

  AppSettings({
    this.isDarkMode = false,
    this.isSystemTheme = true,
    this.isLockEnabled = false,
    this.lockPassword,
    this.customIcons = const [],
    this.customTags = const [],
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);

  AppSettings copyWith({
    bool? isDarkMode,
    bool? isSystemTheme,
    bool? isLockEnabled,
    String? lockPassword,
    List<String>? customIcons,
    List<String>? customTags,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isSystemTheme: isSystemTheme ?? this.isSystemTheme,
      isLockEnabled: isLockEnabled ?? this.isLockEnabled,
      lockPassword: lockPassword ?? this.lockPassword,
      customIcons: customIcons ?? this.customIcons,
      customTags: customTags ?? this.customTags,
    );
  }
}
