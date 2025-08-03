# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter diary application written in Korean that supports cross-platform deployment (Android, iOS, Web). The app allows users to write diary entries, general notes, and includes Android home widgets for quick access.

## Development Commands

### Core Development
```bash
# Install dependencies
flutter pub get

# Generate code (JSON serialization)
flutter pub run build_runner build --delete-conflicting-outputs

# Clean generated files and rebuild
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Run with hot reload
flutter run --hot

# Run on specific device
flutter run -d chrome  # Web
flutter run -d android # Android
flutter run -d ios     # iOS
```

### Testing and Quality
```bash
# Analyze code (lint checks)
flutter analyze

# Run tests
flutter test

# Clean project
flutter clean
```

### Building
```bash
# Android
flutter build apk                    # Debug APK
flutter build apk --release          # Release APK
flutter build appbundle --release    # App Bundle for Play Store

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Android Widget Development
When modifying Android widgets (Kotlin files), you need to rebuild the entire app:
```bash
flutter clean
flutter build apk
```

## Architecture

### Core Architecture Pattern
- **State Management**: Provider pattern with ChangeNotifier
- **Data Layer**: Repository pattern with platform-specific storage services
- **UI Layer**: Feature-based folder structure
- **Models**: JSON serializable data classes with code generation

### Key Components

#### State Management (Provider Pattern)
- `DiaryProvider`: Main business logic and data management
- `ThemeProvider`: Theme switching (light/dark mode)

#### Platform-Specific Storage
- **Mobile**: File system storage (`storage_service_mobile.dart`)  
- **Web**: localStorage storage (`storage_service_web.dart`)
- **Selection**: Conditional exports in `storage_service.dart`

#### Data Models
- `DiaryEntry`: Core data model with JSON serialization
- `AppSettings`: App configuration and preferences
- Uses `json_annotation` and `build_runner` for code generation

#### Android Widgets
Located in `android/app/src/main/kotlin/com/diary/app/`:
- `DiaryAppWidget.kt`: Main home widget showing recent entries
- `MemoWidget.kt`: Configurable memo display widget
- `WidgetUtils.kt`: Shared utility functions
- Uses Flutter's `home_widget` package for communication

### Feature Structure
```
lib/features/
├── home/        # Calendar, entry list, memo tab
├── write/       # Diary/memo creation and editing
├── search/      # Search and filtering functionality  
├── settings/    # Backup, statistics, theme settings
```

### Data Flow
1. **UI Layer** → `DiaryProvider` methods
2. **Provider** → Platform-specific `StorageService`
3. **Storage** → File system (mobile) or localStorage (web)
4. **Provider** → Notifies UI listeners for updates
5. **Widget Service** → Updates Android home widgets when needed

## Development Guidelines

### Working with Models
- Always run code generation after modifying model classes:
  ```bash
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
- Models use `copyWith()` pattern for immutable updates
- Backward compatibility maintained for legacy data fields

### State Management Rules
- Use `DiaryProvider` for all diary-related data operations
- Call `notifyListeners()` after state changes
- UI widgets should use `Consumer<DiaryProvider>` or `context.watch<DiaryProvider>()`

### Platform-Specific Code
- Storage service automatically selects correct implementation
- Use conditional imports pattern for platform-specific features
- Test both mobile and web builds when modifying storage

### Android Widget Development
- Widgets communicate with Flutter through `home_widget` package
- Update widget data via `WidgetService.updateWidget()`
- Test widget behavior after app rebuilds

### Localization
- Primary language is Korean (`ko_KR`)
- English support available (`en_US`)
- Use Korean comments and variable names for consistency

## Common Issues and Solutions

### Build Issues
```bash
# Code generation conflicts
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs

# General build issues
flutter clean && flutter pub get

# Widget not updating
flutter clean && flutter build apk
```

### Platform-Specific Issues
- **Android widgets**: Require full app rebuild after Kotlin changes
- **Web storage**: Limited to localStorage, check browser compatibility
- **iOS**: Home widgets not supported in current implementation

## Key Dependencies
- `provider ^6.1.1` - State management
- `json_annotation ^4.8.1` + `json_serializable ^6.7.1` - Model serialization
- `table_calendar ^3.0.9` - Calendar UI component
- `home_widget ^0.7.0` - Android widget integration
- `path_provider ^2.1.5` - File system access
- `share_plus ^7.2.2` - File sharing functionality

## Testing
- Entry point: `test/widget_test.dart`
- Focus on testing Provider logic and model serialization
- Use `flutter test` for unit tests
- Manual testing recommended for widget functionality