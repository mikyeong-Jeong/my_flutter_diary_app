import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/core/models/diary_entry.dart';
import 'package:diary_app/core/navigation/deeplink_router.dart';

void main() {
  final diary = DiaryEntry(id: 'd1', date: '2026-10-03', title: '일기', content: '내용');
  final todo = DiaryEntry(
    id: 't1',
    date: '2026-10-03',
    title: '할 일',
    content: '□ 청소',
    type: EntryType.datedNote,
  );
  final memo = DiaryEntry(id: 'm1', title: '메모', content: '내용', type: EntryType.general);
  final entries = [diary, todo, memo];
  final now = DateTime(2026, 10, 3);

  List<RouteSettingsSummary> resolve(String link) => DeeplinkRouter.resolve(
        Uri.parse(link),
        entries,
        now: now,
      ).map(RouteSettingsSummary.new).toList();

  test('viewmemo: 일기/메모는 읽기 화면, 할 일은 할 일 화면으로 바로 이동', () {
    expect(resolve('diaryapp://viewmemo?id=d1').single.name, '/read');
    expect(resolve('diaryapp://viewmemo?id=m1').single.entry, memo);
    expect(resolve('diaryapp://viewmemo?id=t1').single.name, '/dated_note');
  });

  test('viewmemo: 항목이 없으면 홈의 메모 탭으로 이동', () {
    final routes = resolve('diaryapp://viewmemo?id=none');
    expect(routes.single.name, '/');
    expect(routes.single.arguments, {'tabIndex': 2});
  });

  test('viewdate: 일기가 있으면 읽기, 없으면 해당 날짜로 작성', () {
    expect(resolve('diaryapp://viewdate?date=2026-10-03').single.entry, diary);

    final write = resolve('diaryapp://viewdate?date=2026-10-05').single;
    expect(write.name, '/write');
    expect(write.entry!.date, '2026-10-05');
    expect(write.entry!.type, EntryType.dated);
  });

  test('write/newentry: 작성 화면으로 이동', () {
    final general = resolve('diaryapp://write?type=general').single;
    expect(general.name, '/write');
    expect(general.entry!.type, EntryType.general);

    expect(resolve('diaryapp://write?date=2026-10-07').single.entry!.date, '2026-10-07');
    expect(resolve('diaryapp://newentry').single.entry!.date, '2026-10-03');
  });

  test('home: 지정한 탭으로 홈 화면 열기, openapp은 이동 없음', () {
    final home = resolve('diaryapp://home?tab=3').single;
    expect(home.name, '/');
    expect(home.arguments, {'tabIndex': 3});

    expect(resolve('diaryapp://openapp'), isEmpty);
  });
}

/// 테스트 비교용 RouteSettings 요약
class RouteSettingsSummary {
  RouteSettingsSummary(dynamic settings)
      : name = settings.name as String?,
        arguments = settings.arguments;

  final String? name;
  final Object? arguments;

  DiaryEntry? get entry => arguments is DiaryEntry ? arguments as DiaryEntry : null;
}
