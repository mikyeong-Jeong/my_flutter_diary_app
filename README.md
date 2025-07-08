# Diary App

Flutter로 개발된 개인 일기 작성 애플리케이션입니다.

## 주요 기능

- 📝 일일 일기 작성 및 관리
- 🎨 감정 이모지 선택
- 🔍 일기 검색 기능
- 🌙 다크모드 지원
- 💾 백업 및 복원
- 📊 통계 확인
- 📱 홈 위젯 지원 (Android)

## 프로젝트 구조

```
lib/
├── core/
│   ├── models/       # 데이터 모델
│   ├── providers/    # 상태 관리
│   ├── services/     # 서비스 레이어
│   └── theme/        # 테마 설정
├── features/
│   ├── home/         # 홈 화면
│   ├── write/        # 일기 작성
│   ├── search/       # 검색
│   └── settings/     # 설정
└── main.dart
```

## 시작하기

### 요구사항

- Flutter SDK 3.0.0 이상
- Dart SDK 3.0.0 이상

### 설치

1. 저장소 클론
```bash
git clone https://github.com/your-username/diary_app.git
cd diary_app
```

2. 의존성 설치
```bash
flutter pub get
```

3. 코드 생성
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. 앱 실행
```bash
flutter run
```

## 사용된 패키지

- **provider**: 상태 관리
- **json_annotation & json_serializable**: JSON 직렬화
- **path_provider**: 로컬 저장소 경로
- **intl**: 날짜 포맷팅
- **table_calendar**: 캘린더 UI
- **share_plus**: 백업 파일 공유
- **file_selector**: 파일 선택
- **home_widget**: Android 홈 위젯

## 빌드

### Android APK
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다.
