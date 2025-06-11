// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiaryEntry _$DiaryEntryFromJson(Map<String, dynamic> json) => DiaryEntry(
      date: json['date'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      icons: (json['icons'] as List<dynamic>).map((e) => e as String).toList(),
      lastModified: json['lastModified'] as String,
    );

Map<String, dynamic> _$DiaryEntryToJson(DiaryEntry instance) =>
    <String, dynamic>{
      'date': instance.date,
      'title': instance.title,
      'content': instance.content,
      'tags': instance.tags,
      'icons': instance.icons,
      'lastModified': instance.lastModified,
    };
