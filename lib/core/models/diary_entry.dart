import 'package:json_annotation/json_annotation.dart';

part 'diary_entry.g.dart';

@JsonSerializable()
class DiaryEntry {
  final String date;
  final String title;
  final String content;
  final List<String> tags;
  final List<String> icons;
  final String lastModified;

  DiaryEntry({
    required this.date,
    required this.title,
    required this.content,
    required this.tags,
    required this.icons,
    required this.lastModified,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) =>
      _$DiaryEntryFromJson(json);

  Map<String, dynamic> toJson() => _$DiaryEntryToJson(this);

  DiaryEntry copyWith({
    String? date,
    String? title,
    String? content,
    List<String>? tags,
    List<String>? icons,
    String? lastModified,
  }) {
    return DiaryEntry(
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      icons: icons ?? this.icons,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  // Helper method to get formatted date
  String get formattedDate {
    final dateTime = DateTime.parse(date);
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일';
  }

  // Helper method to get summary (first 50 characters)
  String get summary {
    if (content.length <= 50) return content;
    return '${content.substring(0, 50)}...';
  }
}
