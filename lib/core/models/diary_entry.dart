import 'package:json_annotation/json_annotation.dart';

part 'diary_entry.g.dart';

enum EntryType { dated, general }

@JsonSerializable()
class DiaryEntry {
  final String id; // 고유 ID 추가
  final String? date; // 일반 메모의 경우 null 가능
  final String title;
  final String content;
  final String mood; // 기분/감정 이모지
  final List<String> tags;
  final List<String> icons;
  final DateTime createdAt;
  final DateTime updatedAt;
  final EntryType type;

  DiaryEntry({
    String? id,
    this.date,
    required this.title,
    required this.content,
    this.mood = '',
    List<String>? tags,
    List<String>? icons,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.type = EntryType.dated,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        tags = tags ?? [],
        icons = icons ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory DiaryEntry.fromJson(Map<String, dynamic> json) =>
      _$DiaryEntryFromJson(json);

  Map<String, dynamic> toJson() => _$DiaryEntryToJson(this);

  DiaryEntry copyWith({
    String? id,
    String? date,
    String? title,
    String? content,
    String? mood,
    List<String>? tags,
    List<String>? icons,
    DateTime? createdAt,
    DateTime? updatedAt,
    EntryType? type,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      icons: icons ?? this.icons,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(), // 수정 시 항상 현재 시간으로 업데이트
      type: type ?? this.type,
    );
  }

  // Helper method to get formatted date
  String get formattedDate {
    if (date == null) return '날짜 없음';
    final dateTime = DateTime.parse(date!);
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일';
  }

  // Helper method to get summary (first 100 characters for better preview)
  String get summary {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  // 마지막 수정 시간 포맷
  String get lastModified {
    return updatedAt.toIso8601String();
  }
}
