// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => AppSettings(
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      isSystemTheme: json['isSystemTheme'] as bool? ?? true,
      isLockEnabled: json['isLockEnabled'] as bool? ?? false,
      lockPassword: json['lockPassword'] as String?,
      customIcons: (json['customIcons'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      customTags: (json['customTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$AppSettingsToJson(AppSettings instance) =>
    <String, dynamic>{
      'isDarkMode': instance.isDarkMode,
      'isSystemTheme': instance.isSystemTheme,
      'isLockEnabled': instance.isLockEnabled,
      'lockPassword': instance.lockPassword,
      'customIcons': instance.customIcons,
      'customTags': instance.customTags,
    };
