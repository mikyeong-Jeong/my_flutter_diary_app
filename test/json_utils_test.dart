import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/core/utils/json_utils.dart';

void main() {
  group('JsonUtils 백업 인코딩', () {
    const json = '{"title":"오늘의 일기 😊","content":"한글 내용"}';

    test('UTF-8(BOM 포함)으로 저장한 백업의 한글이 그대로 복원된다', () {
      final bytes = JsonUtils.toUtf8Bytes(json, includeBom: true);
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);

      final decoded = JsonUtils.decodeFromBytes(bytes);
      expect(decoded['title'], '오늘의 일기 😊');
      expect(decoded['content'], '한글 내용');
    });

    test('BOM 없는 UTF-8 백업도 복원된다', () {
      final decoded = JsonUtils.decodeFromBytes(utf8.encode(json));
      expect(decoded['content'], '한글 내용');
    });

    test('UTF-16 LE/BE(BOM 포함) 백업도 복원된다', () {
      final le = <int>[0xFF, 0xFE];
      final be = <int>[0xFE, 0xFF];
      for (final unit in json.codeUnits) {
        le..add(unit & 0xFF)..add(unit >> 8);
        be..add(unit >> 8)..add(unit & 0xFF);
      }

      expect(JsonUtils.decodeFromBytes(le)['title'], '오늘의 일기 😊');
      expect(JsonUtils.decodeFromBytes(be)['title'], '오늘의 일기 😊');
    });

    test('UTF-8이 아닌 파일(EUC-KR 등)은 깨진 채 복원하지 않고 오류를 낸다', () {
      // EUC-KR로 인코딩된 '{"t":"한"}' (한 = 0xC7 0xD1)
      final eucKr = [...ascii.encode('{"t":"'), 0xC7, 0xD1, ...ascii.encode('"}')];

      expect(() => JsonUtils.decodeFromBytes(eucKr), throwsFormatException);
    });
  });
}
