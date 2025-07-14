// import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  static CalendarService get instance => _instance;
  CalendarService._internal();

  // final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  // List<Calendar> _calendars = [];
  Set<DateTime> _holidays = {};
  bool _isInitialized = false;

  // 캘린더 권한 확인 및 요청
  Future<bool> requestCalendarPermission() async {
    final status = await Permission.calendar.status;
    
    if (status.isDenied) {
      final result = await Permission.calendar.request();
      return result.isGranted;
    }
    
    return status.isGranted;
  }

  // 캘린더 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 임시로 고정 공휴일만 사용
      _addFixedKoreanHolidays();
      _isInitialized = true;
      
      /* device_calendar 사용 시 주석 해제
      final hasPermission = await requestCalendarPermission();
      if (!hasPermission) {
        debugPrint('Calendar permission denied');
        return;
      }

      // 디바이스의 캘린더 목록 가져오기
      final result = await _deviceCalendarPlugin.retrieveCalendars();
      if (result.isSuccess && result.data != null) {
        _calendars = result.data!;
        
        // 공휴일 로드
        await loadHolidays();
        _isInitialized = true;
      }
      */
    } catch (e) {
      debugPrint('Failed to initialize calendar service: $e');
    }
  }

  // 공휴일 로드
  Future<void> loadHolidays() async {
    _holidays.clear();
    
    try {
      // 임시로 고정 공휴일만 사용
      _addFixedKoreanHolidays();
      
      /* device_calendar 사용 시 주석 해제
      // 각 캘린더에서 이벤트 가져오기
      for (final calendar in _calendars) {
        // 대한민국 공휴일 캘린더 찾기
        if (calendar.name?.toLowerCase().contains('holiday') == true ||
            calendar.name?.toLowerCase().contains('휴일') == true ||
            calendar.name?.toLowerCase().contains('공휴일') == true ||
            calendar.name?.toLowerCase().contains('korean') == true) {
          
          // 현재 년도의 시작과 끝
          final now = DateTime.now();
          final startDate = DateTime(now.year - 1, 1, 1);
          final endDate = DateTime(now.year + 2, 12, 31);
          
          final params = RetrieveEventsParams(
            startDate: startDate,
            endDate: endDate,
          );
          
          final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
            calendar.id,
            params,
          );
          
          if (eventsResult.isSuccess && eventsResult.data != null) {
            for (final event in eventsResult.data!) {
              if (event.start != null) {
                // 종일 이벤트인 경우에만 공휴일로 처리
                if (event.allDay == true) {
                  final holidayDate = DateTime(
                    event.start!.year,
                    event.start!.month,
                    event.start!.day,
                  );
                  _holidays.add(holidayDate);
                  debugPrint('Holiday found: ${event.title} on $holidayDate');
                }
              }
            }
          }
        }
      }
      */
    } catch (e) {
      debugPrint('Failed to load holidays: $e');
      // 오류 발생 시 고정 공휴일만 사용
      _addFixedKoreanHolidays();
    }
  }

  // 고정 대한민국 공휴일 추가
  void _addFixedKoreanHolidays() {
    final currentYear = DateTime.now().year;
    
    // 다음 3년간의 고정 공휴일
    for (int year = currentYear - 1; year <= currentYear + 2; year++) {
      _holidays.addAll([
        DateTime(year, 1, 1),   // 신정
        DateTime(year, 3, 1),   // 삼일절
        DateTime(year, 5, 5),   // 어린이날
        DateTime(year, 6, 6),   // 현충일
        DateTime(year, 8, 15),  // 광복절
        DateTime(year, 10, 3),  // 개천절
        DateTime(year, 10, 9),  // 한글날
        DateTime(year, 12, 25), // 성탄절
      ]);
    }
  }

  // 특정 날짜가 공휴일인지 확인
  bool isHoliday(DateTime date) {
    final checkDate = DateTime(date.year, date.month, date.day);
    return _holidays.contains(checkDate);
  }

  // 공휴일 목록 가져오기
  Set<DateTime> get holidays => _holidays;

  // 캘린더 목록 가져오기
  // List<Calendar> get calendars => _calendars;
  List<dynamic> get calendars => [];

  // 리프레시
  Future<void> refresh() async {
    _isInitialized = false;
    await initialize();
  }
}
