/**
 * 캘린더 탭 위젯
 * 
 * 월간 캘린더 뷰를 제공하여 날짜별 일기 작성 현황을 시각적으로 표시하고
 * 특정 날짜를 선택하여 해당 날짜의 일기를 조회하거나 작성할 수 있습니다.
 * 
 * 주요 기능:
 * - 월간 캘린더 표시
 * - 일기가 있는 날짜에 마커 표시
 * - 공휴일 표시 (빨간색)
 * - 토요일 표시 (파란색)
 * - 날짜 선택 시 해당 날짜 일기 미리보기
 * - 선택된 날짜의 일기 작성/수정 버튼
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/diary_provider.dart';
import '../../../../core/models/diary_entry.dart';
import '../../../../core/services/calendar_service.dart';

/**
 * 캘린더 탭 StatefulWidget
 * 
 * table_calendar 패키지를 사용하여 월간 캘린더를 구현합니다.
 */
class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

/**
 * 캘린더 탭 State 클래스
 * 
 * 캘린더 상태 관리와 날짜 선택 로직을 처리합니다.
 */
class _CalendarTabState extends State<CalendarTab> {
  /// 현재 캘린더에서 포커스된 날짜 (표시되는 월)
  DateTime _focusedDay = DateTime.now();
  
  /// 사용자가 선택한 날짜
  DateTime? _selectedDay;
  
  /// 캘린더 표시 형식 (월간/주간)
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  /// 공휴일 정보를 제공하는 캘린더 서비스
  final CalendarService _calendarService = CalendarService.instance;

  /// 캘린더에서 표시할 첫 번째 날짜
  final DateTime _firstDay = DateTime.utc(1902, 1, 1);
  
  /// 캘린더에서 표시할 마지막 날짜
  final DateTime _lastDay = DateTime.utc(2100, 12, 31);

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiaryProvider>().setSelectedDate(_selectedDay!);
      _initializeCalendarService();
    });
  }

  Future<void> _initializeCalendarService() async {
    await _calendarService.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadHolidays(int year) async {
    await _calendarService.loadHolidaysForYear(year);
    if (mounted) {
      setState(() {});
    }
  }

  bool _isHoliday(DateTime day) {
    return _calendarService.isHoliday(day);
  }

  List<DiaryEntry> _getEntriesForDay(DateTime day, List<DiaryEntry> allEntries) {
    return allEntries.where((entry) {
      if (entry.type != EntryType.dated || entry.date == null) return false;
      final entryDate = DateTime.parse(entry.date!);
      return isSameDay(entryDate, day);
    }).toList();
  }

  void _showYearMonthPicker() {
    int selectedYear = _focusedDay.year;
    int selectedMonth = _focusedDay.month;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              child: Container(
                width: 300,
                height: 400,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('취소'),
                        ),
                        const Text(
                          '날짜 선택',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _loadHolidays(selectedYear);
                            
                            setState(() {
                              _focusedDay = DateTime(selectedYear, selectedMonth, 1);
                              final lastDayOfMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
                              if (_selectedDay!.day > lastDayOfMonth) {
                                _selectedDay = DateTime(selectedYear, selectedMonth, lastDayOfMonth);
                              } else {
                                _selectedDay = DateTime(selectedYear, selectedMonth, _selectedDay!.day);
                              }
                            });
                            context.read<DiaryProvider>().setSelectedDate(_selectedDay!);
                            Navigator.pop(context);
                          },
                          child: const Text('완료'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  '년도',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: ListWheelScrollView.useDelegate(
                                    itemExtent: 50,
                                    perspective: 0.005,
                                    diameterRatio: 1.2,
                                    physics: const FixedExtentScrollPhysics(),
                                    controller: FixedExtentScrollController(
                                      initialItem: selectedYear - _firstDay.year,
                                    ),
                                    onSelectedItemChanged: (index) {
                                      setDialogState(() {
                                        selectedYear = _firstDay.year + index;
                                      });
                                    },
                                    childDelegate: ListWheelChildBuilderDelegate(
                                      builder: (context, index) {
                                        final year = _firstDay.year + index;
                                        final isSelected = year == selectedYear;
                                        return Center(
                                          child: Text(
                                            '$year년',
                                            style: TextStyle(
                                              fontSize: isSelected ? 20 : 16,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? Theme.of(context).primaryColor : Colors.black,
                                            ),
                                          ),
                                        );
                                      },
                                      childCount: _lastDay.year - _firstDay.year + 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  '월',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: ListWheelScrollView.useDelegate(
                                    itemExtent: 50,
                                    perspective: 0.005,
                                    diameterRatio: 1.2,
                                    physics: const FixedExtentScrollPhysics(),
                                    controller: FixedExtentScrollController(
                                      initialItem: selectedMonth - 1,
                                    ),
                                    onSelectedItemChanged: (index) {
                                      setDialogState(() {
                                        selectedMonth = index + 1;
                                      });
                                    },
                                    childDelegate: ListWheelChildBuilderDelegate(
                                      builder: (context, index) {
                                        final month = index + 1;
                                        final isSelected = month == selectedMonth;
                                        return Center(
                                          child: Text(
                                            '$month월',
                                            style: TextStyle(
                                              fontSize: isSelected ? 20 : 16,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? Theme.of(context).primaryColor : Colors.black,
                                            ),
                                          ),
                                        );
                                      },
                                      childCount: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DiaryProvider>(
      builder: (context, diaryProvider, child) {
        final entries = diaryProvider.datedEntries;
        final selectedDayEntries = _selectedDay != null 
            ? _getEntriesForDay(_selectedDay!, entries)
            : [];

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                              });
                            },
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: _showYearMonthPicker,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '${_focusedDay.year}년 ${_focusedDay.month}월',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() {
                                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0), // 좌우 패딩 추가
                      child: TableCalendar<DiaryEntry>(
                        locale: 'ko_KR',
                        firstDay: _firstDay,
                        lastDay: _lastDay,
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        eventLoader: (day) => _getEntriesForDay(day, entries),
                        startingDayOfWeek: StartingDayOfWeek.sunday,
                        daysOfWeekHeight: 45, // 요일 행 높이 설정
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
                          weekendStyle: TextStyle(fontWeight: FontWeight.bold), // 색상 제거 (dowBuilder에서 처리)
                        ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        weekendTextStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        holidayTextStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        dowBuilder: (context, day) {
                          final text = DateFormat.E('ko_KR').format(day);
                          return Container(
                            alignment: Alignment.center,
                            height: 40, // 고정 높이 설정
                            padding: const EdgeInsets.symmetric(vertical: 8), // 상하 패딩 추가
                            child: FittedBox(
                              fit: BoxFit.scaleDown, // 텍스트가 컨테이너를 초과하면 축소
                              child: Text(
                                text,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: day.weekday == DateTime.saturday ? Colors.blue[600] : 
                                         day.weekday == DateTime.sunday ? Colors.red[600] : null,
                                ),
                              ),
                            ),
                          );
                        },
                        defaultBuilder: (context, day, focusedDay) {
                          return Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: day.weekday == DateTime.saturday ? Colors.blue[600] : (day.weekday == DateTime.sunday || _isHoliday(day)) ? Colors.red[600] : null,
                              ),
                            ),
                          );
                        },
                        todayBuilder: (context, day, focusedDay) {
                          return Container(
                            margin: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          );
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          return Container(
                            margin: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                      headerStyle: HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        leftChevronVisible: false,  // 왼쪽 화살표 숨기기
                        rightChevronVisible: false, // 오른쪽 화살표 숨기기
                        titleTextFormatter: (date, locale) => '', // 제목 텍스트를 빈 문자열로
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        if (!isSameDay(_selectedDay, selectedDay)) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                          diaryProvider.setSelectedDate(selectedDay);
                        }
                      },
                      onFormatChanged: (format) {
                        if (_calendarFormat != format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        }
                      },
                      onPageChanged: (focusedDay) {
                        if (_focusedDay.year != focusedDay.year) {
                          _loadHolidays(focusedDay.year);
                        }
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                      },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8.0)),
            selectedDayEntries.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.note_add, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('${DateFormat('M월 d일').format(_selectedDay!)}의 일기가 없습니다', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          Text('새로운 일기를 작성해보세요', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = selectedDayEntries[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: InkWell(
                              onTap: () => Navigator.pushNamed(context, '/read', arguments: entry),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            entry.title.isEmpty ? '제목 없음' : entry.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                        if (entry.allEmojis.isNotEmpty)
                                          Wrap(
                                            spacing: 4,
                                            children: entry.allEmojis.map<Widget>((emoji) => Text(emoji, style: const TextStyle(fontSize: 20))).toList(),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(entry.content, style: const TextStyle(fontSize: 14)),
                                    if (entry.tags.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 4,
                                        children: entry.tags.map<Widget>((tag) => Chip(label: Text(tag), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)).toList(),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text('작성: ${entry.formattedCreatedAt}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: selectedDayEntries.length,
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }
}
