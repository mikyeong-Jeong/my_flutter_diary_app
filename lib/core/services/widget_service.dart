import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';
import 'storage_service.dart';

class WidgetService {
  static const String _widgetName = 'DiaryAppWidget';
  static const String _calendarWidgetName = 'DiaryCalendarWidget';
  
  final StorageService _storageService = StorageService.instance;

  // 위젯 데이터 업데이트
  Future<void> updateWidget() async {
    try {
      // 오늘 날짜
      final today = DateTime.now();
      final todayString = DateFormat('yyyy년 M월 d일').format(today);
      
      // 최근 일기 목록 가져오기
      final entries = await _getRecentEntries();
      
      // 홈 위젯에 데이터 저장
      await HomeWidget.saveWidgetData<String>('today_date', todayString);
      await HomeWidget.saveWidgetData<String>('entry_count', '${entries.length}개의 일기');
      
      // 최근 일기 3개 저장
      for (int i = 0; i < 3 && i < entries.length; i++) {
        final entry = entries[i];
        final date = DateTime.parse(entry.date!);
        final dateStr = DateFormat('M/d').format(date);
        
        await HomeWidget.saveWidgetData<String>(
          'entry_${i}_date', 
          dateStr,
        );
        await HomeWidget.saveWidgetData<String>(
          'entry_${i}_title', 
          entry.title.isEmpty ? '제목 없음' : entry.title,
        );
        await HomeWidget.saveWidgetData<String>(
          'entry_${i}_icons', 
          entry.icons.join(' '),
        );
      }
      
      // 빈 슬롯 초기화
      for (int i = entries.length; i < 3; i++) {
        await HomeWidget.saveWidgetData<String>('entry_${i}_date', '');
        await HomeWidget.saveWidgetData<String>('entry_${i}_title', '');
        await HomeWidget.saveWidgetData<String>('entry_${i}_icons', '');
      }
      
      // 위젯 업데이트 요청
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
      );
      
      await HomeWidget.updateWidget(
        name: _calendarWidgetName,
        androidName: _calendarWidgetName,
      );
    } catch (e) {
      // 위젯 업데이트 실패 시 조용히 무시
    }
  }

  // 최근 일기 가져오기
  Future<List<DiaryEntry>> _getRecentEntries() async {
    try {
      final allEntries = await _storageService.loadAllEntries();
      
      // 날짜별 메모만 필터링
      final datedEntries = allEntries.where((e) => e.type == EntryType.dated).toList();
      
      // 날짜 내림차순 정렬 (이미 정렬되어 있지만 확실히 하기 위해)
      datedEntries.sort((a, b) => b.date!.compareTo(a.date!));
      
      // 최근 10개만 반환
      return datedEntries.take(10).toList();
    } catch (e) {
      // 최근 일기 로드 실패 시 빈 목록 반환
      return [];
    }
  }

  // 위젯 초기화
  Future<void> initializeWidget() async {
    await HomeWidget.setAppGroupId('com.example.diary_app');
    await HomeWidget.registerInteractivityCallback(backgroundCallback);
  }

  // 백그라운드 콜백 (위젯 클릭 처리)
  static Future<void> backgroundCallback(Uri? uri) async {
    if (uri != null) {
      // 위젯에서 앱 열기 처리
      if (uri.host == 'openapp') {
        // 앱이 이미 실행 중이면 아무 동작 안함
        // 앱이 종료된 상태면 main.dart에서 처리
      }
    }
  }
}
