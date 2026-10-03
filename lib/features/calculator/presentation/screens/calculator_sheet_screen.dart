import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/calculator_row.dart';
import '../../../../core/models/calculator_sheet.dart';
import '../../../../core/providers/calculator_provider.dart';

/// 계산 작성/수정 화면
///
/// 상단에 제목과 예산을 입력하고, 한 줄에 날짜·항목·금액(지출)을 입력합니다.
/// 행을 추가/삭제할 수 있고 하단에 지출 총액과 남은 금액(예산 - 지출)이 고정 표시됩니다.
/// 우측 상단 저장 버튼을 눌러야 저장됩니다. (할 일/메모 작성 화면과 동일)
class CalculatorSheetScreen extends StatefulWidget {
  const CalculatorSheetScreen({super.key, this.sheet});

  /// 수정할 계산 (null이면 새 계산)
  final CalculatorSheet? sheet;

  @override
  State<CalculatorSheetScreen> createState() => _CalculatorSheetScreenState();
}

class _CalculatorSheetScreenState extends State<CalculatorSheetScreen> {
  static final NumberFormat _amountFormat = NumberFormat('#,###');

  late CalculatorSheet _sheet;
  late List<CalculatorRow> _rows;
  late bool _isEditing;
  late final TextEditingController _titleController;
  late final TextEditingController _budgetController;

  /// 예산 (원 단위, 0이면 미입력)
  int _budget = 0;

  /// 줄별 입력 컨트롤러 (id 기준)
  final Map<String, TextEditingController> _itemControllers = {};
  final Map<String, TextEditingController> _amountControllers = {};

  @override
  void initState() {
    super.initState();
    _sheet = widget.sheet ?? CalculatorSheet();
    // 이미 저장된 계산인지로 수정 여부 판단
    _isEditing = context.read<CalculatorProvider>().contains(_sheet.id);
    _titleController = TextEditingController(text: _sheet.title);
    _budget = _sheet.budget;
    _budgetController = TextEditingController(
      text: _budget == 0 ? '' : _amountFormat.format(_budget),
    );
    // 새 계산은 빈 줄 하나로 시작
    _rows = _sheet.rows.isEmpty ? [_newRow()] : List.of(_sheet.rows);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _budgetController.dispose();
    for (final controller in [..._itemControllers.values, ..._amountControllers.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  CalculatorRow _newRow() {
    return CalculatorRow(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
  }

  void _updateRow(CalculatorRow row) {
    setState(() {
      _rows = [for (final r in _rows) r.id == row.id ? row : r];
    });
  }

  void _addRow() {
    setState(() => _rows = [..._rows, _newRow()]);
  }

  void _deleteRow(CalculatorRow row) {
    _itemControllers.remove(row.id)?.dispose();
    _amountControllers.remove(row.id)?.dispose();
    setState(() => _rows = _rows.where((r) => r.id != row.id).toList());
  }

  Future<void> _selectDate(CalculatorRow row) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(row.date) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _updateRow(_findRow(row.id).copyWith(date: DateFormat('yyyy-MM-dd').format(picked)));
    }
  }

  /// 저장
  Future<void> _save() async {
    final title = _titleController.text.trim();
    // 항목도 금액도 없는 빈 줄은 저장하지 않음
    final rows = _rows.where((r) => r.item.trim().isNotEmpty || r.amount != 0).toList();

    if (title.isEmpty && rows.isEmpty && _budget == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목이나 내용을 입력해주세요'), backgroundColor: Colors.orange),
      );
      return;
    }

    await context.read<CalculatorProvider>().saveSheet(
          _sheet.copyWith(title: title, budget: _budget, rows: rows, updatedAt: DateTime.now()),
        );
    if (mounted) Navigator.pop(context);
  }

  /// 삭제
  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('계산 삭제'),
        content: const Text('이 계산을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              context.read<CalculatorProvider>().deleteSheet(_sheet.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  TextEditingController _itemController(CalculatorRow row) {
    return _itemControllers.putIfAbsent(row.id, () => TextEditingController(text: row.item));
  }

  TextEditingController _amountController(CalculatorRow row) {
    return _amountControllers.putIfAbsent(
      row.id,
      () => TextEditingController(text: row.amount == 0 ? '' : _amountFormat.format(row.amount)),
    );
  }

  /// 최신 줄 데이터 조회 (입력 콜백이 오래된 row를 참조하지 않도록)
  CalculatorRow _findRow(String id) => _rows.firstWhere((r) => r.id == id);

  @override
  Widget build(BuildContext context) {
    final total = CalculatorRow.totalOf(_rows);
    final remaining = _budget - total;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '계산 수정' : '새 계산'),
        actions: [
          if (_isEditing)
            IconButton(icon: const Icon(Icons.delete), tooltip: '삭제', onPressed: _delete),
          IconButton(icon: const Icon(Icons.check), tooltip: '저장', onPressed: _save),
        ],
      ),
      body: Column(
        children: [
          // 제목·예산·머리글·입력 줄은 함께 스크롤 (하단 합계 영역만 고정)
          Expanded(
            child: ListView(
              key: const Key('calculator_scroll'),
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                // 제목
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: '제목',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),

                // 예산
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    key: const Key('calculator_budget'),
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandsSeparatorFormatter(_amountFormat)],
                    decoration: InputDecoration(
                      labelText: '예산',
                      hintText: '0',
                      suffixText: '원',
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) {
                      setState(() => _budget = int.tryParse(value.replaceAll(',', '')) ?? 0);
                    },
                  ),
                ),

                // 머리글
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      SizedBox(width: 84, child: Text('날짜', style: _headerStyle(context))),
                      const SizedBox(width: 8),
                      Expanded(child: Text('항목', style: _headerStyle(context))),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 104,
                        child: Text('금액', style: _headerStyle(context), textAlign: TextAlign.right),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // 입력 줄 목록 + 행 추가 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final row in _rows) _buildRow(context, row),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _addRow,
                        icon: const Icon(Icons.add),
                        label: const Text('행 추가'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 하단 고정 영역: 지출 총액, 남은 금액 (예산 - 지출)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSummaryRow(
                    context,
                    label: '지출 총액',
                    value: '${_amountFormat.format(total)}원',
                    valueKey: const Key('calculator_total'),
                  ),
                  const SizedBox(height: 6),
                  _buildSummaryRow(
                    context,
                    label: '남은 금액',
                    // 예산 미입력 시 '-', 예산 초과 시 음수(빨간색)
                    value: _budget == 0 ? '-' : '${_formatSigned(remaining)}원',
                    valueKey: const Key('calculator_remaining'),
                    valueColor: _budget != 0 && remaining < 0 ? Colors.red : null,
                    emphasize: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 음수는 앞에 '-'를 붙여 표시
  String _formatSigned(int value) =>
      value < 0 ? '-${_amountFormat.format(-value)}' : _amountFormat.format(value);

  Widget _buildSummaryRow(
    BuildContext context, {
    required String label,
    required String value,
    required Key valueKey,
    Color? valueColor,
    bool emphasize = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(label, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(
          value,
          key: valueKey,
          style: (emphasize ? textTheme.titleLarge : textTheme.titleMedium)?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? (emphasize ? Theme.of(context).primaryColor : null),
          ),
        ),
      ],
    );
  }

  TextStyle? _headerStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold);
  }

  Widget _buildRow(BuildContext context, CalculatorRow row) {
    final date = DateTime.tryParse(row.date);
    return Padding(
      key: ValueKey(row.id),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // 날짜 (탭하면 날짜 선택)
          SizedBox(
            width: 84,
            child: OutlinedButton(
              onPressed: () => _selectDate(row),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              ),
              child: Text(
                date != null ? DateFormat('yy.MM.dd').format(date) : row.date,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 항목
          Expanded(
            child: TextField(
              controller: _itemController(row),
              decoration: const InputDecoration(
                hintText: '항목',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _updateRow(_findRow(row.id).copyWith(item: value)),
            ),
          ),
          const SizedBox(width: 8),

          // 금액 (숫자만, 천 단위 콤마 자동)
          SizedBox(
            width: 104,
            child: TextField(
              controller: _amountController(row),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              inputFormatters: [_ThousandsSeparatorFormatter(_amountFormat)],
              decoration: const InputDecoration(
                hintText: '0',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final amount = int.tryParse(value.replaceAll(',', '')) ?? 0;
                _updateRow(_findRow(row.id).copyWith(amount: amount));
              },
            ),
          ),

          // 행 삭제
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.grey,
              tooltip: '행 삭제',
              onPressed: () => _deleteRow(row),
            ),
          ),
        ],
      ),
    );
  }
}

/// 숫자만 입력받고 천 단위 콤마를 붙이는 입력 포맷터
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  _ThousandsSeparatorFormatter(this._format);

  final NumberFormat _format;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();

    // 너무 큰 수 방지 (최대 15자리)
    final trimmed = digits.length > 15 ? digits.substring(0, 15) : digits;
    final formatted = _format.format(int.parse(trimmed));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
