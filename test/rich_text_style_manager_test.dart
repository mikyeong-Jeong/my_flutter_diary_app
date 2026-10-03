import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/features/write/presentation/widgets/rich_text_style_manager.dart';

void main() {
  group('RichTextStyleManager.adjustRangesForTextChange', () {
    late RichTextStyleManager manager;

    setUp(() {
      manager = RichTextStyleManager();
      // [5, 10) 구간에 굵게 적용
      manager.applyBoldToSelection(5, 10, true);
    });

    List<List<int>> ranges() =>
        manager.styleRanges.map((r) => [r.start, r.end]).toList();

    test('범위 앞에 입력하면 범위가 뒤로 이동한다', () {
      manager.adjustRangesForTextChange(0, 0, 3);
      expect(ranges(), [[8, 13]]);
    });

    test('범위 뒤에 입력하면 범위가 그대로 유지된다', () {
      manager.adjustRangesForTextChange(12, 0, 3);
      expect(ranges(), [[5, 10]]);
    });

    test('범위 안쪽에 입력하면 범위가 늘어난다', () {
      manager.adjustRangesForTextChange(7, 0, 2);
      expect(ranges(), [[5, 12]]);
    });

    test('범위 앞쪽 일부를 지우면 남은 부분만 유지된다', () {
      // [3, 7) 삭제 → 원래 [7, 10)이 [3, 6)으로 이동
      manager.adjustRangesForTextChange(3, 4, 0);
      expect(ranges(), [[3, 6]]);
    });

    test('범위 전체를 지우면 범위가 제거된다', () {
      manager.adjustRangesForTextChange(4, 8, 0);
      expect(ranges(), isEmpty);
    });
  });
}
