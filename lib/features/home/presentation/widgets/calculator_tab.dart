import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/calculator_sheet.dart';
import '../../../../core/providers/calculator_provider.dart';
import '../../../../core/theme/entry_colors.dart';

/// 계산기 탭 위젯
///
/// 저장된 계산 목록을 보여줍니다. (제목 + 지출/남은 금액)
/// 항목을 누르면 작성/수정 화면으로 이동하고, 새 계산은 + 버튼으로 추가합니다.
class CalculatorTab extends StatelessWidget {
  const CalculatorTab({super.key});

  static final NumberFormat _amountFormat = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final sheets = provider.sheets;
        if (sheets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calculate_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('작성된 계산이 없습니다', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text('+ 버튼으로 새 계산을 추가해보세요', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: sheets.length,
          itemBuilder: (context, index) => _buildSheetCard(context, sheets[index]),
        );
      },
    );
  }

  /// 음수는 앞에 '-'를 붙여 표시
  static String _formatSigned(int value) =>
      value < 0 ? '-${_amountFormat.format(-value)}' : _amountFormat.format(value);

  Widget _buildSheetCard(BuildContext context, CalculatorSheet sheet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      // 계산 색상(보라) 테두리 윤곽선
      shape: EntryColors.cardShape(EntryColors.calculator),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/calculator', arguments: sheet),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 목록에는 제목만 표시
              Text(
                sheet.title.isNotEmpty ? sheet.title : '제목 없음',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: sheet.title.isNotEmpty ? null : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              // 지출/남은 금액과 수정일 (좁은 화면에서는 줄바꿈)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    // 예산이 있으면 남은 금액도 함께 표시
                    sheet.hasBudget
                        ? '지출 ${_amountFormat.format(sheet.total)}원 · 남은 ${_formatSigned(sheet.remaining)}원'
                        : '지출 ${_amountFormat.format(sheet.total)}원',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sheet.hasBudget && sheet.remaining < 0
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    '수정 ${DateFormat('yyyy.MM.dd HH:mm').format(sheet.updatedAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
