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
/// 입력 내용은 바뀔 때마다 자동 저장됩니다. (아무것도 입력하지 않은 새 계산은 저장하지 않음)
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
  /// 화면을 닫을 때(dispose)도 사용하기 위해 보관
  late final CalculatorProvider _provider;
  late final TextEditingController _titleController;
  late final TextEditingController _budgetController;

  /// 예산 (원 단위, 0이면 미입력)
  int _budget = 0;

  /// 줄별 입력 컨트롤러 (id 기준)
  final Map<String, TextEditingController> _itemControllers = {};
  final Map<String, TextEditingController> _amountControllers = {};

  /// 줄별 항목 입력칸 포커스 (행 추가 시 새 줄로 바로 이동)
  final Map<String, FocusNode> _itemFocusNodes = {};

  @override
  void initState() {
    super.initState();
    _sheet = widget.sheet ?? CalculatorSheet();
    // 이미 저장된 계산인지로 수정 여부 판단
    _provider = context.read<CalculatorProvider>();
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
    // 내용을 모두 지우고 나가면 빈 계산이 목록에 남지 않도록 삭제
    // (dispose 중에는 위젯 트리가 잠겨 있으므로 목록 갱신은 다음 마이크로태스크에서)
    if (_isEmpty(_currentSheet()) && _provider.contains(_sheet.id)) {
      final provider = _provider;
      final id = _sheet.id;
      Future.microtask(() => provider.deleteSheet(id));
    }
    _titleController.dispose();
    _budgetController.dispose();
    for (final controller in [..._itemControllers.values, ..._amountControllers.values]) {
      controller.dispose();
    }
    for (final focusNode in _itemFocusNodes.values) {
      focusNode.dispose();
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
    _autoSave();
  }

  void _addRow() {
    final row = _newRow();
    setState(() => _rows = [..._rows, row]);
    // 새 줄의 항목 입력칸으로 커서 이동 (포커스되면 화면에 보이도록 자동 스크롤)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _itemFocusNodes[row.id]?.requestFocus();
    });
  }

  void _deleteRow(CalculatorRow row) {
    _itemControllers.remove(row.id)?.dispose();
    _amountControllers.remove(row.id)?.dispose();
    _itemFocusNodes.remove(row.id)?.dispose();
    setState(() => _rows = _rows.where((r) => r.id != row.id).toList());
    _autoSave();
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

  /// 저장할 계산 데이터 (항목도 금액도 없는 빈 줄은 제외)
  CalculatorSheet _currentSheet() {
    return _sheet.copyWith(
      title: _titleController.text.trim(),
      budget: _budget,
      rows: _rows.where((r) => r.item.trim().isNotEmpty || r.amount != 0).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// 제목·예산·내용이 모두 비어 있는지 여부
  bool _isEmpty(CalculatorSheet sheet) =>
      sheet.title.isEmpty && sheet.budget == 0 && sheet.rows.isEmpty;

  /// 자동 저장 (입력이 바뀔 때마다 호출)
  ///
  /// 아무것도 입력하지 않은 새 계산은 목록에 만들지 않습니다.
  void _autoSave() {
    final sheet = _currentSheet();
    if (_isEmpty(sheet) && !_provider.contains(sheet.id)) return;
    _provider.saveSheet(sheet);
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
    // 자동 저장으로 목록에 생기면 삭제 버튼 표시
    final isSaved = context.watch<CalculatorProvider>().contains(_sheet.id);

    return Scaffold(
      appBar: AppBar(
        // 입력 내용은 자동 저장되므로 별도 저장 버튼 없음
        title: Text(isSaved ? '계산 수정' : '새 계산'),
        actions: [
          if (isSaved)
            IconButton(icon: const Icon(Icons.delete), tooltip: '삭제', onPressed: _delete),
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
                    onChanged: (_) => _autoSave(),
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
                      _autoSave();
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
                      // 마지막 줄 바로 아래, 표의 빈 줄처럼 보이는 행 추가 버튼
                      _buildAddRowButton(context),
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

  /// 행 추가 버튼: 입력 줄과 같은 높이/폭의 빈 줄 형태
  Widget _buildAddRowButton(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 40),
      child: Material(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          key: const Key('calculator_add_row'),
          onTap: _addRow,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 20, color: color),
                const SizedBox(width: 6),
                Text(
                  '행 추가',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
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
              focusNode: _itemFocusNodes.putIfAbsent(row.id, () => FocusNode()),
              textInputAction: TextInputAction.next,
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
