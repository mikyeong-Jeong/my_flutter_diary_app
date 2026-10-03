/// 계산기 탭의 한 줄 (날짜, 항목, 금액)
class CalculatorRow {
  /// 고유 식별자
  final String id;

  /// 날짜 (yyyy-MM-dd)
  final String date;

  /// 항목 이름
  final String item;

  /// 금액 (원 단위 정수)
  final int amount;

  const CalculatorRow({
    required this.id,
    required this.date,
    this.item = '',
    this.amount = 0,
  });

  CalculatorRow copyWith({String? date, String? item, int? amount}) {
    return CalculatorRow(
      id: id,
      date: date ?? this.date,
      item: item ?? this.item,
      amount: amount ?? this.amount,
    );
  }

  factory CalculatorRow.fromJson(Map<String, dynamic> json) {
    return CalculatorRow(
      id: json['id'] as String,
      date: json['date'] as String,
      item: json['item'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'item': item,
        'amount': amount,
      };

  /// 여러 줄의 금액 합계
  static int totalOf(List<CalculatorRow> rows) =>
      rows.fold(0, (sum, row) => sum + row.amount);
}
