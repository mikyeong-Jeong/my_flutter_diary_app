import 'package:json_annotation/json_annotation.dart';

part 'diary_entry.g.dart';

enum EntryType { dated, general }

@JsonSerializable()
class DiaryEntry {
  final String id;
  final String? date; // 일반 메모의 경우 null
  final String title;
  final String content;
  final List<String> moods; // 다중 기분 이모지 지원
  final List<String> tags;
  final List<String> customEmojis; // 사용자 지정 이모지
  final DateTime createdAt;
  final DateTime updatedAt;
  final EntryType type;

  DiaryEntry({
    String? id,
    this.date,
    required this.title,
    required this.content,
    List<String>? moods,
    List<String>? tags,
    List<String>? customEmojis,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.type = EntryType.dated,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        moods = moods ?? [],
        tags = tags ?? [],
        customEmojis = customEmojis ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // 이전 mood 필드 호환성을 위한 getter
  String get mood => moods.isNotEmpty ? moods.first : '';
  List<String> get icons => customEmojis; // 기존 icons 필드 호환성

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    // 이전 버전 호환성 처리
    final entry = _$DiaryEntryFromJson(json);
    
    // 이전 mood 필드가 있는 경우 moods로 변환
    if (json.containsKey('mood') && json['mood'] is String && json['mood'].isNotEmpty) {
      final oldMood = json['mood'] as String;
      if (!entry.moods.contains(oldMood)) {
        return entry.copyWith(moods: [oldMood, ...entry.moods]);
      }
    }
    
    // 이전 icons 필드가 있는 경우 customEmojis로 변환
    if (json.containsKey('icons') && json['icons'] is List) {
      final oldIcons = (json['icons'] as List).cast<String>();
      return entry.copyWith(customEmojis: oldIcons);
    }
    
    return entry;
  }

  Map<String, dynamic> toJson() => _$DiaryEntryToJson(this);

  DiaryEntry copyWith({
    String? id,
    String? date,
    String? title,
    String? content,
    List<String>? moods,
    List<String>? tags,
    List<String>? customEmojis,
    DateTime? createdAt,
    DateTime? updatedAt,
    EntryType? type,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      moods: moods ?? this.moods,
      tags: tags ?? this.tags,
      customEmojis: customEmojis ?? this.customEmojis,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      type: type ?? this.type,
    );
  }

  String get formattedDate {
    if (date == null) return '날짜 없음';
    final dateTime = DateTime.parse(date!);
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일';
  }

  String get formattedCreatedAt {
    return '${createdAt.year}년 ${createdAt.month}월 ${createdAt.day}일 ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedUpdatedAt {
    return '${updatedAt.year}년 ${updatedAt.month}월 ${updatedAt.day}일 ${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}';
  }

  String get summary {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  String get lastModified {
    return updatedAt.toIso8601String();
  }

  // 모든 이모지 반환 (기분 + 사용자 지정)
  List<String> get allEmojis => [...moods, ...customEmojis];
}
