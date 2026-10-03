import 'calculator_row.dart';

/// 계산기 탭에 저장되는 계산 한 건 (제목 + 날짜/항목/금액 줄 목록)
class CalculatorSheet {
  /// 고유 식별자
  final String id;

  /// 제목
  final String title;

  /// 예산 (원 단위, 0이면 미입력)
  final int budget;

  /// 입력 줄 목록 (지출)
  final List<CalculatorRow> rows;

  /// 생성 일시
  final DateTime createdAt;

  /// 최종 수정 일시
  final DateTime updatedAt;

  CalculatorSheet({
    String? id,
    this.title = '',
    this.budget = 0,
    List<CalculatorRow>? rows,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        rows = rows ?? const [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 지출 총액
  int get total => CalculatorRow.totalOf(rows);

  /// 남은 금액 (예산 - 지출, 예산 초과 시 음수)
  int get remaining => budget - total;

  /// 예산이 입력되었는지 여부
  bool get hasBudget => budget > 0;

  CalculatorSheet copyWith({
    String? title,
    int? budget,
    List<CalculatorRow>? rows,
    DateTime? updatedAt,
  }) {
    return CalculatorSheet(
      id: id,
      title: title ?? this.title,
      budget: budget ?? this.budget,
      rows: rows ?? this.rows,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CalculatorSheet.fromJson(Map<String, dynamic> json) {
    return CalculatorSheet(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      budget: (json['budget'] as num?)?.toInt() ?? 0,
      rows: (json['rows'] as List? ?? [])
          .map((e) => CalculatorRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'budget': budget,
        'rows': rows.map((r) => r.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
