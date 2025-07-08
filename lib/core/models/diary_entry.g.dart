// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiaryEntry _$DiaryEntryFromJson(Map<String, dynamic> json) => DiaryEntry(
      id: json['id'] as String?,
      date: json['date'] as String?,
      title: json['title'] as String,
      content: json['content'] as String,
      mood: json['mood'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      icons:
          (json['icons'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      type: $enumDecodeNullable(_$EntryTypeEnumMap, json['type']) ??
          EntryType.dated,
    );

Map<String, dynamic> _$DiaryEntryToJson(DiaryEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'title': instance.title,
      'content': instance.content,
      'mood': instance.mood,
      'tags': instance.tags,
      'icons': instance.icons,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'type': _$EntryTypeEnumMap[instance.type]!,
    };

const _$EntryTypeEnumMap = {
  EntryType.dated: 'dated',
  EntryType.general: 'general',
};
