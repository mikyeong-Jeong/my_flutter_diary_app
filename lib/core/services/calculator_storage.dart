import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/calculator_sheet.dart';

/// 계산기 탭 데이터 저장소
///
/// 계산 목록을 SharedPreferences에 JSON으로 저장합니다. (모바일/웹 공통)
class CalculatorStorage {
  CalculatorStorage._();

  static const String _key = 'calculator_sheets';

  /// 저장된 계산 목록 불러오기 (없거나 읽기 실패 시 빈 목록)
  static Future<List<CalculatorSheet>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      if (jsonString == null) return [];
      final list = jsonDecode(jsonString) as List;
      return list
          .map((e) => CalculatorSheet.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 계산 목록 저장
  static Future<void> save(List<CalculatorSheet> sheets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(sheets.map((s) => s.toJson()).toList()));
  }
}
