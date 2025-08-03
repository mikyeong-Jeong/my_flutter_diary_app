/**
 * 다이어리 항목 모델 클래스
 * 
 * 다이어리 앱의 핵심 데이터 모델로, 일기 항목의 모든 정보를 담고 있습니다.
 * JSON 직렬화/역직렬화를 지원하여 로컬 스토리지에 저장하거나 불러올 수 있습니다.
 * 
 * 지원 기능:
 * - 날짜별 일기와 일반 메모 구분
 * - 다중 기분 이모지 지원
 * - 태그 시스템
 * - 사용자 지정 이모지
 * - 이전 버전과의 호환성
 */

import 'package:json_annotation/json_annotation.dart';

part 'diary_entry.g.dart';

/**
 * 다이어리 항목 타입 열거형
 * 
 * dated: 특정 날짜에 작성된 일기
 * general: 날짜에 구애받지 않는 일반 메모
 */
enum EntryType { dated, general }

/**
 * 다이어리 항목 클래스
 * 
 * 일기 항목의 모든 데이터를 관리하는 모델 클래스입니다.
 * JSON 직렬화를 지원하여 데이터 저장/로드가 가능합니다.
 */
@JsonSerializable()
class DiaryEntry {
  /// 고유 식별자 - 타임스탬프 기반으로 생성
  final String id;
  
  /// 일기 날짜 - 일반 메모의 경우 null
  final String? date;
  
  /// 일기 제목
  final String title;
  
  /// 일기 내용
  final String content;
  
  /// 다중 기분 이모지 목록 - 여러 기분을 동시에 표현 가능
  final List<String> moods;
  
  /// 태그 목록 - 일기 분류 및 검색을 위한 태그
  final List<String> tags;
  
  /// 사용자 지정 이모지 목록 - 기분 외의 추가 이모지
  final List<String> customEmojis;
  
  /// 생성 일시
  final DateTime createdAt;
  
  /// 최종 수정 일시
  final DateTime updatedAt;
  
  /// 항목 타입 (dated/general)
  final EntryType type;

  /**
   * DiaryEntry 생성자
   * 
   * @param id : 고유 식별자 (선택사항, 미제공시 타임스탬프로 자동 생성)
   * @param date : 일기 날짜 (일반 메모의 경우 null)
   * @param title : 일기 제목 (필수)
   * @param content : 일기 내용 (필수)
   * @param moods : 기분 이모지 목록 (선택사항, 기본값: 빈 리스트)
   * @param tags : 태그 목록 (선택사항, 기본값: 빈 리스트)
   * @param customEmojis : 사용자 지정 이모지 목록 (선택사항, 기본값: 빈 리스트)
   * @param createdAt : 생성 일시 (선택사항, 기본값: 현재 시간)
   * @param updatedAt : 수정 일시 (선택사항, 기본값: 현재 시간)
   * @param type : 항목 타입 (선택사항, 기본값: EntryType.dated)
   */
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

  /**
   * 이전 버전 호환성을 위한 mood getter
   * 
   * 기존 단일 mood 필드를 사용하던 코드와의 호환성을 위해 제공됩니다.
   * moods 리스트의 첫 번째 항목을 반환하거나, 비어있으면 빈 문자열을 반환합니다.
   * 
   * @return String : 첫 번째 기분 이모지 또는 빈 문자열
   */
  String get mood => moods.isNotEmpty ? moods.first : '';
  
  /**
   * 이전 버전 호환성을 위한 icons getter
   * 
   * 기존 icons 필드를 사용하던 코드와의 호환성을 위해 제공됩니다.
   * customEmojis와 동일한 값을 반환합니다.
   * 
   * @return List<String> : 사용자 지정 이모지 목록
   */
  List<String> get icons => customEmojis;

  /**
   * JSON에서 DiaryEntry 객체를 생성하는 팩토리 메서드
   * 
   * 이전 버전과의 호환성을 처리하여 안전하게 객체를 생성합니다.
   * - 이전 mood 필드가 있으면 moods 배열로 변환
   * - 이전 icons 필드가 있으면 customEmojis 배열로 변환
   * 
   * @param json : JSON 데이터 맵
   * @return DiaryEntry : 생성된 다이어리 항목 객체
   */
  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    // 기본 JSON 역직렬화 수행
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

  /**
   * DiaryEntry 객체를 JSON으로 변환하는 메서드
   * 
   * 객체의 모든 필드를 JSON 형태로 직렬화합니다.
   * 
   * @return Map<String, dynamic> : JSON 데이터 맵
   */
  Map<String, dynamic> toJson() => _$DiaryEntryToJson(this);

  /**
   * 객체의 일부 필드를 변경한 새 인스턴스를 생성하는 메서드
   * 
   * 불변 객체 패턴을 따라 기존 객체를 수정하지 않고 새 객체를 생성합니다.
   * updatedAt은 자동으로 현재 시간으로 설정됩니다.
   * 
   * @param id : 새로운 ID (선택사항)
   * @param date : 새로운 날짜 (선택사항)
   * @param title : 새로운 제목 (선택사항)
   * @param content : 새로운 내용 (선택사항)
   * @param moods : 새로운 기분 목록 (선택사항)
   * @param tags : 새로운 태그 목록 (선택사항)
   * @param customEmojis : 새로운 사용자 지정 이모지 목록 (선택사항)
   * @param createdAt : 새로운 생성 일시 (선택사항)
   * @param updatedAt : 새로운 수정 일시 (선택사항)
   * @param type : 새로운 항목 타입 (선택사항)
   * @return DiaryEntry : 수정된 새 다이어리 항목 객체
   */
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

  /**
   * 날짜를 한국어 형식으로 포맷팅하는 getter
   * 
   * 일기 날짜를 "YYYY년 MM월 DD일" 형식으로 변환합니다.
   * 날짜가 null인 경우 '날짜 없음'을 반환합니다.
   * 
   * @return String : 포맷된 날짜 문자열
   */
  String get formattedDate {
    if (date == null) return '날짜 없음';
    final dateTime = DateTime.parse(date!);
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일';
  }

  /**
   * 생성 일시를 한국어 형식으로 포맷팅하는 getter
   * 
   * 생성 일시를 "YYYY년 MM월 DD일 HH:MM" 형식으로 변환합니다.
   * 
   * @return String : 포맷된 생성 일시 문자열
   */
  String get formattedCreatedAt {
    return '${createdAt.year}년 ${createdAt.month}월 ${createdAt.day}일 ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /**
   * 수정 일시를 한국어 형식으로 포맷팅하는 getter
   * 
   * 수정 일시를 "YYYY년 MM월 DD일 HH:MM" 형식으로 변환합니다.
   * 
   * @return String : 포맷된 수정 일시 문자열
   */
  String get formattedUpdatedAt {
    return '${updatedAt.year}년 ${updatedAt.month}월 ${updatedAt.day}일 ${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}';
  }

  /**
   * 일기 내용의 요약을 제공하는 getter
   * 
   * 일기 내용이 100자를 초과하는 경우 앞의 100자만 표시하고 '...'을 추가합니다.
   * 리스트 뷰나 미리보기에서 사용됩니다.
   * 
   * @return String : 요약된 내용 (최대 100자 + '...')
   */
  String get summary {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  /**
   * 최종 수정 시간을 ISO 8601 형식으로 반환하는 getter
   * 
   * 데이터 동기화나 백업 시 사용할 수 있는 표준 시간 포맷을 제공합니다.
   * 
   * @return String : ISO 8601 형식의 수정 시간
   */
  String get lastModified {
    return updatedAt.toIso8601String();
  }

  /**
   * 모든 이모지를 반환하는 getter
   * 
   * 기분 이모지와 사용자 지정 이모지를 합쳐서 반환합니다.
   * 일기 항목에 연결된 모든 이모지를 한 번에 조회할 때 사용됩니다.
   * 
   * @return List<String> : 모든 이모지 목록 (기분 + 사용자 지정)
   */
  List<String> get allEmojis => [...moods, ...customEmojis];
}
