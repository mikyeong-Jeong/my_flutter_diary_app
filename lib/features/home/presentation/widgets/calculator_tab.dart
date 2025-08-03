import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 계산기 탭 위젯
/// 
/// 엑셀과 같은 스프레드시트 스타일의 계산기를 제공합니다.
/// 여러 값을 입력하고 합계, 평균, 최대값, 최소값 등을 계산할 수 있습니다.
class CalculatorTab extends StatefulWidget {
  const CalculatorTab({super.key});

  @override
  State<CalculatorTab> createState() => _CalculatorTabState();
}

class _CalculatorTabState extends State<CalculatorTab> {
  // 셀 데이터를 저장하는 리스트 (각 행은 Map으로 표현)
  final List<Map<String, dynamic>> _rows = [
    {'label': '', 'formula': '', 'value': 0.0, 'controller': TextEditingController()},
  ];

  // 계산 결과
  double _sum = 0.0;
  double _average = 0.0;
  double _max = 0.0;
  double _min = 0.0;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _calculateResults();
  }

  @override
  void dispose() {
    // 모든 TextEditingController 해제
    for (var row in _rows) {
      row['controller'].dispose();
    }
    super.dispose();
  }

  // 새 행 추가
  void _addRow() {
    setState(() {
      _rows.add({
        'label': '',
        'formula': '',
        'value': 0.0,
        'controller': TextEditingController(),
      });
    });
  }

  // 행 삭제
  void _deleteRow(int index) {
    if (_rows.length > 1) {
      setState(() {
        _rows[index]['controller'].dispose();
        _rows.removeAt(index);
        _calculateResults();
      });
    }
  }

  // 모든 행 초기화
  void _clearAll() {
    setState(() {
      for (var row in _rows) {
        row['controller'].dispose();
      }
      _rows.clear();
      _rows.add({
        'label': '',
        'formula': '',
        'value': 0.0,
        'controller': TextEditingController(),
      });
      _calculateResults();
    });
  }

  // 수식 계산
  double? _evaluateFormula(String formula) {
    if (formula.isEmpty) return null;
    
    try {
      // 기본적인 수식 파싱 및 계산
      // 공백 제거
      formula = formula.replaceAll(' ', '');
      
      // ÷ 기호를 / 로 변환
      formula = formula.replaceAll('÷', '/');
      
      // 간단한 사칙연산 처리
      // 더 복잡한 수식을 위해서는 별도의 파서가 필요합니다
      
      // 숫자와 연산자 분리
      final RegExp regex = RegExp(r'(\d+\.?\d*)([+\-*/]?)');
      final matches = regex.allMatches(formula).toList();
      
      if (matches.isEmpty) return null;
      
      double result = double.tryParse(matches[0].group(1)!) ?? 0;
      
      for (int i = 0; i < matches.length - 1; i++) {
        String operator = matches[i].group(2) ?? '';
        double nextValue = double.tryParse(matches[i + 1].group(1)!) ?? 0;
        
        switch (operator) {
          case '+':
            result += nextValue;
            break;
          case '-':
            result -= nextValue;
            break;
          case '*':
            result *= nextValue;
            break;
          case '/':
            if (nextValue != 0) {
              result /= nextValue;
            } else {
              return null; // 0으로 나누기 방지
            }
            break;
        }
      }
      
      return result;
    } catch (e) {
      return null;
    }
  }

  // 결과 계산
  void _calculateResults() {
    if (_rows.isEmpty) {
      _sum = 0.0;
      _average = 0.0;
      _max = 0.0;
      _min = 0.0;
      _count = 0;
      return;
    }

    List<double> values = _rows
        .where((row) => row['value'] != 0.0)
        .map<double>((row) => row['value'] as double)
        .toList();

    if (values.isEmpty) {
      _sum = 0.0;
      _average = 0.0;
      _max = 0.0;
      _min = 0.0;
      _count = 0;
    } else {
      _sum = values.reduce((a, b) => a + b);
      _average = _sum / values.length;
      _max = values.reduce((a, b) => a > b ? a : b);
      _min = values.reduce((a, b) => a < b ? a : b);
      _count = values.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        children: [
        // 툴바
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: _addRow,
                tooltip: '행 추가',
              ),
              IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: _clearAll,
                tooltip: '모두 지우기',
              ),
              const Spacer(),
              Text(
                '사칙연산 지원: +, -, *, /, ÷',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              Text(
                '항목 수: $_count',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        
        // 스프레드시트 영역
        Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Column(
            children: [
                // 헤더
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          '항목',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '수식/값',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '결과',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 48), // 삭제 버튼 공간
                    ],
                  ),
                ),
                
                // 데이터 행들
                ..._rows.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> row = entry.value;
                  
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: Row(
                        children: [
                          // 라벨 입력
                          Expanded(
                            flex: 1,
                            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  row['label'] = value;
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: '항목명',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                              ),
                            ),
                          ),
                          
                          // 수식/값 입력
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: row['controller'],
                              textAlign: TextAlign.center,
                              onChanged: (value) {
                                setState(() {
                                  row['formula'] = value;
                                  // 수식 계산 시도
                                  double? result = _evaluateFormula(value);
                                  if (result != null) {
                                    row['value'] = result;
                                  } else {
                                    // 수식이 아닌 경우 단순 숫자 파싱 시도
                                    row['value'] = double.tryParse(value) ?? 0.0;
                                  }
                                  _calculateResults();
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: '예: 10+5*2 또는 20÷4',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                              ),
                            ),
                          ),
                          
                          // 결과 표시
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                row['value'] == row['value'].toInt() 
                                    ? row['value'].toInt().toString() 
                                    : row['value'].toStringAsFixed(2),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                          
                          // 삭제 버튼
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: _rows.length > 1 ? () => _deleteRow(index) : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
        ),
        
        // 계산 결과
        Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildResultRow('합계', _sum),
              const SizedBox(height: 8),
              _buildResultRow('평균', _average),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildResultRow('최대값', _max)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildResultRow('최소값', _min)),
                ],
              ),
            ],
          ),
        ),
        
        // 키보드가 올라올 때를 위한 여백
        SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value == value.toInt() 
              ? value.toInt().toString() 
              : value.toStringAsFixed(2),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}