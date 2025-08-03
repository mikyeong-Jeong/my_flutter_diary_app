# Diary App

Flutter로 개발된 개인 일기 작성 애플리케이션입니다.

## 주요 기능

- 📝 **일일 일기 작성 및 관리** - 날짜별 일기와 자유 메모 작성
- 🎨 **감정 이모지 선택** - 8가지 기본 감정과 커스텀 이모지 지원
- 🏷️ **태그 시스템** - 일기 분류를 위한 태그 기능
- 🔍 **강력한 검색 기능** - 제목, 내용, 태그, 날짜 범위로 검색
- 🌙 **다크모드 지원** - 라이트/다크 테마 자동 전환
- 💾 **백업 및 복원** - JSON 형식 백업, 클립보드 지원
- 📊 **통계 확인** - 작성 현황 및 태그/이모지 통계
- 📱 **홈 위젯 지원** (Android) - 최근 일기 표시 및 빠른 작성
- 🌐 **크로스 플랫폼** - Android, iOS, Web 지원

## 스크린샷

| 홈 화면 | 일기 작성 | 검색 |
|---------|-----------|------|
| 캘린더와 일기 목록 | 이모지와 태그 | 고급 필터링 |

## 프로젝트 구조

```
lib/
├── core/
│   ├── models/           # 데이터 모델 (DiaryEntry, AppSettings)
│   ├── providers/        # 상태 관리 (DiaryProvider, ThemeProvider)
│   ├── services/         # 서비스 레이어
│   │   ├── storage_service_mobile.dart    # 모바일 저장소
│   │   ├── storage_service_web.dart       # 웹 저장소
│   │   ├── widget_service.dart            # 위젯 관리
│   │   ├── calendar_service.dart          # 공휴일 관리
│   │   └── import_service.dart            # 외부 파일 가져오기
│   ├── theme/            # 테마 설정
│   └── utils/            # 유틸리티 (텍스트 정제, 다운로드 헬퍼)
├── features/
│   ├── home/             # 홈 화면 (캘린더, 일기 목록, 메모)
│   ├── write/            # 일기 작성 (이모지, 태그, 날짜 선택)
│   ├── search/           # 검색 (텍스트, 태그, 날짜 범위)
│   └── settings/         # 설정 (백업/복원, 통계, 테마)
├── main.dart             # 앱 진입점
└── android/
    └── app/src/main/kotlin/com/diary/app/
        ├── DiaryAppWidget.kt      # 메인 홈 위젯
        ├── MemoWidget.kt          # 메모 위젯
        └── WidgetUtils.kt         # 위젯 유틸리티
```

## 시작하기

### 요구사항

- Flutter SDK 3.7.0 이상
- Dart SDK 2.19.0 이상
- Android Studio / VS Code (개발 시)

### 설치

1. **저장소 클론**
```bash
git clone https://github.com/your-username/diary_app.git
cd diary_app
```

2. **의존성 설치**
```bash
flutter pub get
```

3. **코드 생성** (JSON 직렬화)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **앱 실행**
```bash
flutter run
```

### 개발 환경 설정

#### Android 위젯 개발
```bash
# Android Studio에서 android/ 폴더 열기
# Kotlin 파일 수정 후 Flutter 앱 재빌드
flutter clean
flutter build apk
```

#### 웹 개발
```bash
# 웹 서버 실행
flutter run -d chrome
```

## 사용된 패키지

### 핵심 패키지
- **provider**: ^6.1.1 - 상태 관리
- **json_annotation**: ^4.8.1 & **json_serializable**: ^6.7.1 - JSON 직렬화
- **path_provider**: ^2.1.5 - 로컬 저장소 경로 관리

### UI/UX 패키지
- **table_calendar**: ^3.0.9 - 캘린더 UI 컴포넌트
- **intl**: ^0.20.2 - 날짜 포맷팅 및 다국어 지원
- **cupertino_icons**: ^1.0.6 - iOS 스타일 아이콘

### 기능 패키지
- **share_plus**: ^7.2.2 - 백업 파일 공유
- **file_selector**: ^1.0.3 - 파일 선택 (웹/데스크톱)
- **permission_handler**: ^12.0.1 - 권한 관리
- **home_widget**: ^0.7.0 - Android 홈 위젯

### 개발 도구
- **build_runner**: ^2.4.7 - 코드 생성
- **flutter_lints**: ^3.0.0 - 코드 스타일 검사

## 주요 기능 상세

### 📝 일기 작성
- **날짜별 일기**: 하루에 하나씩 작성 (중복 체크)
- **일반 메모**: 날짜 제한 없이 자유 작성
- **이모지 선택**: 8가지 기본 감정 + 커스텀 이모지
- **태그 시스템**: 10가지 기본 태그 + 사용자 정의 태그

### 🔍 검색 기능
- **텍스트 검색**: 제목과 내용에서 키워드 검색
- **태그 필터**: 특정 태그로 필터링
- **날짜 범위**: 기간별 일기 검색
- **타입 분리**: 날짜별 일기와 일반 메모 구분 검색

### 💾 백업 시스템
- **내보내기**: JSON 형식으로 모든 데이터 백업
- **가져오기**: 백업 파일에서 데이터 복원
- **클립보드 지원**: 백업 데이터 복사/붙여넣기
- **파일 공유**: 메신저, 클라우드 등으로 백업 공유

### 📱 Android 위젯
- **메인 위젯**: 최근 일기 3개 표시 + 빠른 작성
- **메모 위젯**: 특정 메모 내용 표시 (소형/중형/대형)
- **딥링크**: 위젯에서 앱 내 특정 화면으로 이동

## 빌드

### Android
```bash
# Debug APK
flutter build apk

# Release APK (최적화)
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release
```

### iOS
```bash
# iOS 앱 빌드
flutter build ios --release

# 시뮬레이터용
flutter build ios --debug
```

### Web
```bash
# 웹 빌드
flutter build web --release

# 웹 서버 실행
flutter run -d chrome
```

### 데스크톱 (실험적)
```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

## 문제 해결

### 일반적인 문제
1. **빌드 오류**: `flutter clean && flutter pub get` 실행
2. **코드 생성 오류**: `flutter pub run build_runner clean` 후 재생성
3. **위젯 오류**: Android 위젯 권한 확인

### Android 위젯 문제
```bash
# 위젯 데이터 초기화
adb shell am broadcast -a android.appwidget.action.APPWIDGET_UPDATE
```

### iOS 관련
- iOS에서는 홈 위젯이 지원되지 않습니다
- 파일 시스템 접근이 제한적입니다

## 기여하기

1. 이슈 등록 또는 기능 제안
2. Fork 후 feature 브랜치 생성
3. 코드 작성 및 테스트
4. Pull Request 제출

### 코드 스타일
- Flutter/Dart 공식 가이드 준수
- `flutter analyze` 통과 필수
- 한글 주석 권장

## 로드맵

- [ ] **iOS 위젯 지원** - iOS 14+ 위젯 구현
- [ ] **클라우드 동기화** - Firebase/iCloud 연동
- [ ] **다국어 지원 확장** - 영어, 일본어 추가
- [ ] **이미지 첨부** - 사진과 함께 일기 작성
- [ ] **음성 메모** - 오디오 녹음 기능
- [ ] **AI 감정 분석** - 텍스트 기반 감정 자동 분석

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 문의

- 이슈: [GitHub Issues](https://github.com/your-username/diary_app/issues)
- 이메일: your-email@example.com

---

**Made with ❤️ using Flutter**