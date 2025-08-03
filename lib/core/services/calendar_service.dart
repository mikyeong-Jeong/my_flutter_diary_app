/**
 * 캘린더 관련 서비스 클래스
 * 
 * 한국의 공휴일 정보를 관리하고 캘린더 기능을 제공하는 서비스입니다.
 * Singleton 패턴을 사용하여 앱 전체에서 하나의 인스턴스만 존재하도록 합니다.
 * 
 * 주요 기능:
 * - 한국 공휴일 정보 관리
 * - 특정 날짜의 공휴일 여부 확인
 * - 연도별 공휴일 데이터 로딩 및 캐싱
 * - 캘린더 권한 관리
 * 
 * 현재 device_calendar 패키지는 주석 처리되어 있고,
 * 고정된 한국 공휴일 정보만 사용하고 있습니다.
 */

// import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

/**
 * 캘린더 서비스 클래스
 * 
 * 한국의 공휴일 정보와 캘린더 관련 기능을 제공하는 Singleton 서비스입니다.
 */
class CalendarService {
  /// Singleton 인스턴스
  static final CalendarService _instance = CalendarService._internal();
  
  /// 외부에서 접근 가능한 Singleton 인스턴스 getter
  static CalendarService get instance => _instance;
  
  /// private 생성자 (Singleton 패턴)
  CalendarService._internal();

  /// 디바이스 캘린더 플러그인 (현재 주석 처리됨)
  // final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  
  /// 캘린더 목록 (현재 주석 처리됨)
  // List<Calendar> _calendars = [];
  
  /// 공휴일 날짜들을 저장하는 Set (중복 방지)
  final Set<DateTime> _holidays = {};
  
  /// 이미 로드된 연도를 추적하는 Set (중복 로딩 방지)
  final Set<int> _loadedYears = {};
  
  /// 서비스 초기화 여부 플래그
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
      // 현재 연도의 공휴일만 초기에 로드
      await loadHolidaysForYear(DateTime.now().year);
      _isInitialized = true;
      
      /* device_calendar 사용 시 주석 해제
      // ... (기존 코드)
      */
    } catch (e) {
      debugPrint('Failed to initialize calendar service: $e');
    }
  }

  // 특정 연도의 공휴일 로드
  Future<void> loadHolidaysForYear(int year) async {
    // 이미 해당 연도의 공휴일을 로드했다면 다시 로드하지 않음
    if (_loadedYears.contains(year)) {
      return;
    }

    try {
      _addFixedKoreanHolidays(year);
      _loadedYears.add(year); // 로드된 연도로 기록
      
      /* device_calendar 사용 시 주석 해제
      // ... (기존 코드와 유사하게 특정 연도에 대한 로직 추가)
      */
    } catch (e) {
      debugPrint('Failed to load holidays for year $year: $e');
      // 오류 발생 시 고정 공휴일만 사용
      _addFixedKoreanHolidays(year);
      _loadedYears.add(year);
    }
  }

  // 고정 대한민국 공휴일 추가 (특정 연도)
  void _addFixedKoreanHolidays(int year) {
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

  // 리프레시 (이제 특정 연도를 다시 로드하도록 수정 가능)
  Future<void> refresh(int year) async {
    _loadedYears.remove(year); // 해당 연도 캐시 제거
    await loadHolidaysForYear(year);
  }
}