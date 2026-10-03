import 'package:flutter/widgets.dart';

import '../models/diary_entry.dart';

/// 위젯 딥링크(diaryapp://...)를 화면 이동 정보로 변환하는 클래스
///
/// 앱이 꺼진 상태에서 위젯으로 열 때(초기 라우트)와
/// 실행 중인 앱에 딥링크가 전달될 때 같은 규칙으로 이동하도록 한 곳에서 관리합니다.
class DeeplinkRouter {
  DeeplinkRouter._();

  /// 딥링크를 이동할 라우트 목록으로 변환
  ///
  /// - 첫 번째 항목이 '/'이면 홈 화면을 해당 arguments로 새로 연 뒤 나머지 화면을 쌓습니다.
  /// - 첫 번째 항목이 '/'가 아니면 현재 화면 위에 쌓습니다.
  /// - 빈 목록이면 화면 이동 없이 앱만 엽니다 (예: openapp).
  ///
  /// 지원 host: home, viewmemo, viewdate, newentry, write, openapp
  static List<RouteSettings> resolve(Uri uri, List<DiaryEntry> entries, {DateTime? now}) {
    final today = _formatDate(now ?? DateTime.now());

    switch (uri.host) {
      case 'home':
        // 홈 화면의 특정 탭으로 이동
        final tabIndex = int.tryParse(uri.queryParameters['tab'] ?? '') ?? 0;
        return [RouteSettings(name: '/', arguments: {'tabIndex': tabIndex})];

      case 'viewmemo':
        // 특정 항목 보기 (할 일은 전용 읽기 화면)
        final memoId = uri.queryParameters['id'];
        final matches = entries.where((e) => e.id == memoId);
        if (memoId == null || matches.isEmpty) {
          // 항목을 찾을 수 없으면 메모 탭으로 이동
          return const [RouteSettings(name: '/', arguments: {'tabIndex': 2})];
        }
        final entry = matches.first;
        return [
          RouteSettings(
            name: entry.type == EntryType.datedNote ? '/dated_note' : '/read',
            arguments: entry,
          ),
        ];

      case 'viewdate':
        // 특정 날짜의 일기 보기 (없으면 해당 날짜로 작성)
        final date = uri.queryParameters['date'];
        if (date == null) return const [];
        final diaries = entries.where((e) => e.date == date && e.type == EntryType.dated);
        if (diaries.isNotEmpty) {
          return [RouteSettings(name: '/read', arguments: diaries.first)];
        }
        return [
          RouteSettings(
            name: '/write',
            arguments: DiaryEntry(date: date, title: '', content: '', type: EntryType.dated),
          ),
        ];

      case 'newentry':
        // 일기 위젯의 '새 일기' 버튼 - 오늘 날짜 일기 작성
        return [
          RouteSettings(
            name: '/write',
            arguments: DiaryEntry(date: today, title: '', content: '', type: EntryType.dated),
          ),
        ];

      case 'write':
        // 새 메모(type=general) 또는 날짜별 일기 작성
        if (uri.queryParameters['type'] == 'general') {
          return [
            RouteSettings(
              name: '/write',
              arguments: DiaryEntry(title: '', content: '', type: EntryType.general),
            ),
          ];
        }
        return [
          RouteSettings(
            name: '/write',
            arguments: DiaryEntry(
              date: uri.queryParameters['date'] ?? today,
              title: '',
              content: '',
              type: EntryType.dated,
            ),
          ),
        ];

      default:
        // openapp 등: 앱만 열기
        return const [];
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
