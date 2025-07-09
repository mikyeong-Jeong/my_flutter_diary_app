import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/diary_provider.dart';
import '../../../../core/models/diary_entry.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiaryProvider>().setSelectedDate(_selectedDay!);
    });
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
                    // 헤더
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
                            setState(() {
                              _focusedDay = DateTime(selectedYear, selectedMonth, 1);
                              // 선택된 날짜 업데이트
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
                    
                    // 년도/월 피커
                    Expanded(
                      child: Row(
                        children: [
                          // 년도 선택
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
                                      initialItem: selectedYear - 2020,
                                    ),
                                    onSelectedItemChanged: (index) {
                                      setDialogState(() {
                                        selectedYear = 2020 + index;
                                      });
                                    },
                                    childDelegate: ListWheelChildBuilderDelegate(
                                      builder: (context, index) {
                                        final year = 2020 + index;
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
                                      childCount: 11, // 2020-2030
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 20),
                          
                          // 월 선택
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
            // 커스텀 헤더와 달력을 SliverToBoxAdapter로 고정
            SliverToBoxAdapter(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  children: [
                    // 커스텀 헤더
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 이전 달 버튼
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                              });
                            },
                          ),
                          
                          // 년도 월 표시 (클릭 가능)
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
                          
                          // 다음 달 버튼
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
                    
                    // 달력
                    TableCalendar<DiaryEntry>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      eventLoader: (day) {
                        return _getEntriesForDay(day, entries);
                      },
                      startingDayOfWeek: StartingDayOfWeek.sunday,
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        weekendTextStyle: TextStyle(color: Colors.red[400]),
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
                      headerStyle: const HeaderStyle(
                        titleCentered: false,
                        formatButtonVisible: false,
                        leftChevronVisible: false,
                        rightChevronVisible: false,
                        headerPadding: EdgeInsets.zero,
                        headerMargin: EdgeInsets.zero,
                        titleTextStyle: TextStyle(fontSize: 0, height: 0),
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
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                      },
                    ),
                    
                    // 형식 변경 버튼
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _calendarFormat = _calendarFormat == CalendarFormat.month
                                    ? CalendarFormat.twoWeeks
                                    : _calendarFormat == CalendarFormat.twoWeeks
                                        ? CalendarFormat.week
                                        : CalendarFormat.month;
                              });
                            },
                            icon: Icon(
                              _calendarFormat == CalendarFormat.month
                                  ? Icons.calendar_view_month
                                  : _calendarFormat == CalendarFormat.twoWeeks
                                      ? Icons.view_week
                                      : Icons.view_agenda,
                              size: 20,
                            ),
                            label: Text(
                              _calendarFormat == CalendarFormat.month
                                  ? '월간'
                                  : _calendarFormat == CalendarFormat.twoWeeks
                                      ? '2주간'
                                      : '주간',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              foregroundColor: Theme.of(context).primaryColor,
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 구분선
            const SliverToBoxAdapter(
              child: SizedBox(height: 8.0),
            ),
            
            // 메모 목록을 SliverList로 구성
            selectedDayEntries.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_add,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${DateFormat('M월 d일').format(_selectedDay!)}의 일기가 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '새로운 일기를 작성해보세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
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
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/write',
                                  arguments: entry,
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 제목과 이모지
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            entry.title.isEmpty ? '제목 없음' : entry.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (entry.allEmojis.isNotEmpty)
                                          Wrap(
                                            spacing: 4,
                                            children: entry.allEmojis
                                                .map<Widget>((emoji) => Text(emoji, style: const TextStyle(fontSize: 20)))
                                                .toList(),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // 전체 내용 표시
                                    Text(
                                      entry.content,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    if (entry.tags.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 4,
                                        children: entry.tags
                                            .map<Widget>((tag) => Chip(
                                                  label: Text(tag),
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ))
                                            .toList(),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      '작성: ${entry.formattedCreatedAt}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
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
