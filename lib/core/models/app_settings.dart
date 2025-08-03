/**
 * 앱 설정 모델 클래스
 * 
 * 다이어리 앱의 사용자 설정 정보를 관리하는 모델 클래스입니다.
 * JSON 직렬화/역직렬화를 지원하여 로컬 스토리지에 설정을 저장하고 불러올 수 있습니다.
 * 
 * 관리하는 설정:
 * - 테마 설정 (다크 모드, 시스템 테마 따르기)
 * - 앱 잠금 기능 (패스워드 보호)
 * - 사용자 지정 아이콘 및 태그
 */

import 'package:json_annotation/json_annotation.dart';

part 'app_settings.g.dart';

/**
 * 앱 설정 클래스
 * 
 * 사용자의 앱 설정 정보를 저장하고 관리하는 모델 클래스입니다.
 * JSON 직렬화를 통해 영구 저장이 가능합니다.
 */
@JsonSerializable()
class AppSettings {
  /// 다크 모드 활성화 여부
  final bool isDarkMode;
  
  /// 시스템 테마 따르기 여부 (시스템 설정에 맞춰 자동 변경)
  final bool isSystemTheme;
  
  /// 앱 잠금 기능 활성화 여부
  final bool isLockEnabled;
  
  /// 앱 잠금 패스워드 (null인 경우 잠금 비활성화)
  final String? lockPassword;
  
  /// 사용자 지정 아이콘 목록 (일기에서 사용할 수 있는 커스텀 이모지)
  final List<String> customIcons;
  
  /// 사용자 지정 태그 목록 (일기 분류용 커스텀 태그)
  final List<String> customTags;

  /**
   * AppSettings 생성자
   * 
   * @param isDarkMode : 다크 모드 활성화 여부 (기본값: false)
   * @param isSystemTheme : 시스템 테마 따르기 여부 (기본값: true)
   * @param isLockEnabled : 앱 잠금 기능 활성화 여부 (기본값: false)
   * @param lockPassword : 앱 잠금 패스워드 (선택사항)
   * @param customIcons : 사용자 지정 아이콘 목록 (기본값: 빈 리스트)
   * @param customTags : 사용자 지정 태그 목록 (기본값: 빈 리스트)
   */
  AppSettings({
    this.isDarkMode = false,
    this.isSystemTheme = true,
    this.isLockEnabled = false,
    this.lockPassword,
    this.customIcons = const [],
    this.customTags = const [],
  });

  /**
   * JSON에서 AppSettings 객체를 생성하는 팩토리 메서드
   * 
   * 저장된 JSON 데이터로부터 AppSettings 객체를 복원합니다.
   * 
   * @param json : JSON 데이터 맵
   * @return AppSettings : 생성된 앱 설정 객체
   */
  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  /**
   * AppSettings 객체를 JSON으로 변환하는 메서드
   * 
   * 설정 정보를 JSON 형태로 직렬화하여 저장할 수 있도록 합니다.
   * 
   * @return Map<String, dynamic> : JSON 데이터 맵
   */
  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);

  /**
   * 설정의 일부를 변경한 새 인스턴스를 생성하는 메서드
   * 
   * 불변 객체 패턴을 따라 기존 설정을 수정하지 않고 새로운 설정 객체를 생성합니다.
   * 변경하지 않을 설정은 기존 값을 유지합니다.
   * 
   * @param isDarkMode : 새로운 다크 모드 설정 (선택사항)
   * @param isSystemTheme : 새로운 시스템 테마 따르기 설정 (선택사항)
   * @param isLockEnabled : 새로운 앱 잠금 활성화 설정 (선택사항)
   * @param lockPassword : 새로운 잠금 패스워드 (선택사항)
   * @param customIcons : 새로운 사용자 지정 아이콘 목록 (선택사항)
   * @param customTags : 새로운 사용자 지정 태그 목록 (선택사항)
   * @return AppSettings : 수정된 새 앱 설정 객체
   */
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
