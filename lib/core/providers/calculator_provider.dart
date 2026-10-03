import 'package:flutter/foundation.dart';

import '../models/calculator_sheet.dart';
import '../services/calculator_storage.dart';
import '../services/widget_service.dart';

/// 계산기 탭의 계산 목록을 관리하는 Provider
class CalculatorProvider extends ChangeNotifier {
  List<CalculatorSheet> _sheets = [];
  final WidgetService _widgetService = WidgetService();
  bool _isLoading = true;

  CalculatorProvider() {
    loadSheets();
  }

  /// 계산 목록 (최근 수정순)
  List<CalculatorSheet> get sheets => List.unmodifiable(_sheets);

  bool get isLoading => _isLoading;

  /// 저장된 계산 목록 불러오기
  Future<void> loadSheets() async {
    _sheets = await CalculatorStorage.load();
    _sortSheets();
    _isLoading = false;
    notifyListeners();
    await _widgetService.updateCalculatorWidgets(_sheets);
  }

  /// 계산 저장 (같은 id가 있으면 수정, 없으면 추가)
  Future<void> saveSheet(CalculatorSheet sheet) async {
    final index = _sheets.indexWhere((s) => s.id == sheet.id);
    if (index != -1) {
      _sheets[index] = sheet;
    } else {
      _sheets.add(sheet);
    }
    _sortSheets();
    notifyListeners();
    await CalculatorStorage.save(_sheets);
    await _widgetService.updateCalculatorWidgets(_sheets);
  }

  /// 계산 삭제
  Future<void> deleteSheet(String id) async {
    _sheets.removeWhere((s) => s.id == id);
    notifyListeners();
    await CalculatorStorage.save(_sheets);
    await _widgetService.updateCalculatorWidgets(_sheets);
  }

  /// 저장된 계산인지 확인
  bool contains(String id) => _sheets.any((s) => s.id == id);

  void _sortSheets() {
    _sheets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}
