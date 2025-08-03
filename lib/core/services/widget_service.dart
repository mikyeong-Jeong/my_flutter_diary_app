import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary_entry.dart';
import 'storage_service.dart';

/// 홈 화면 위젯과 메모 위젯을 관리하는 서비스
/// 
/// Android 홈 화면에 표시되는 위젯들의 데이터를 업데이트하고
/// 위젯과 앱 간의 상호작용을 처리합니다.
class WidgetService {
  static const String _widgetName = 'DiaryAppWidget';
  static const String _memoWidgetName = 'MemoWidget';
  static const String _singleMemoWidgetName = 'SingleMemoWidget';
  
  final StorageService _storageService = StorageService.instance;

  /// 위젯 데이터 업데이트
  /// 
  /// 모든 위젯의 데이터를 최신 상태로 업데이트합니다.
  /// 일기가 추가/수정/삭제될 때마다 호출됩니다.
  Future<void> updateWidget() async {
    try {
      // 오늘 날짜
      final today = DateTime.now();
      final todayString = DateFormat('yyyy년 M월 d일').format(today);
      
      // 최근 일기 목록 가져오기
      final entries = await _getRecentEntries();
      
      // 전체 entries를 JSON으로 저장 (SingleMemoWidget 설정 화면용)
      await _saveAllEntries();
      
      // 홈 위젯에 데이터 저장
      await HomeWidget.saveWidgetData<String>('today_date', todayString);
      await HomeWidget.saveWidgetData<String>('entry_count', '${entries.length}개의 일기');
      
      // 최근 일기 3개 저장
      for (int i = 0; i < 3 && i < entries.length; i++) {
        final entry = entries[i];
        final date = DateTime.parse(entry.date!);
        final dateStr = DateFormat('M/d').format(date);
        
        await HomeWidget.saveWidgetData<String>(
          'entry_${i}_id', 
          entry.id,
        );
        await HomeWidget.saveWidgetData<String>(
          'entry_${i}_date', 
          dateStr,
        );
        await HomeWidget.saveWidgetData<String>(
          'entry_${i}_title', 
          entry.title.isEmpty ? '제목 없음' : entry.title,
        );
        // moods와 customEmojis를 결합하여 표시
        final allEmojis = [...entry.moods, ...entry.customEmojis];
        await HomeWidget.saveWidgetData<String>(
          'entry_${i}_icons', 
          allEmojis.join(' '),
        );
      }
      
      // 빈 슬롯 초기화
      for (int i = entries.length; i < 3; i++) {
        await HomeWidget.saveWidgetData<String>('entry_${i}_id', '');
        await HomeWidget.saveWidgetData<String>('entry_${i}_date', '');
        await HomeWidget.saveWidgetData<String>('entry_${i}_title', '');
        await HomeWidget.saveWidgetData<String>('entry_${i}_icons', '');
      }
      
      // 위젯 업데이트 요청
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
      );
      
      // 캘린더 위젯 업데이트
      await HomeWidget.updateWidget(
        name: 'CalendarWidget',
        androidName: 'CalendarWidget',
      );

      // 메모 위젯 업데이트
      await updateMemoWidgets();
      
      // 단일 메모 위젯 업데이트
      await HomeWidget.updateWidget(
        name: _singleMemoWidgetName,
        androidName: _singleMemoWidgetName,
      );
    } catch (e) {
      // 위젯 업데이트 실패 시 조용히 무시
    }
  }

  /// 최근 일기 항목 가져오기
  /// 
  /// 날짜별 일기 중 최근 10개를 가져옵니다.
  /// 홈 화면 위젯에 표시할 데이터로 사용됩니다.
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

  /// 메모 위젯들 업데이트
  /// 
  /// 모든 메모 위젯의 데이터를 업데이트합니다.
  /// 최근 메모 3개를 위젯에 표시합니다.
  Future<void> updateMemoWidgets() async {
    try {
      // 최근 메모 가져오기
      final memos = await _getRecentMemos();
      
      // 최근 메모 3개 저장
      for (int i = 0; i < 3 && i < memos.length; i++) {
        final memo = memos[i];
        final date = DateFormat('M/d').format(memo.updatedAt);
        
        await HomeWidget.saveWidgetData<String>(
          'memo_${i}_id', 
          memo.id,
        );
        await HomeWidget.saveWidgetData<String>(
          'memo_${i}_date', 
          date,
        );
        await HomeWidget.saveWidgetData<String>(
          'memo_${i}_title', 
          memo.title.isEmpty ? '제목 없음' : memo.title,
        );
        await HomeWidget.saveWidgetData<String>(
          'memo_${i}_content', 
          memo.content,
        );
      }
      
      // 빈 슬롯 초기화
      for (int i = memos.length; i < 3; i++) {
        await HomeWidget.saveWidgetData<String>('memo_${i}_id', '');
        await HomeWidget.saveWidgetData<String>('memo_${i}_date', '');
        await HomeWidget.saveWidgetData<String>('memo_${i}_title', '');
        await HomeWidget.saveWidgetData<String>('memo_${i}_content', '');
      }
      
      await HomeWidget.updateWidget(
        name: _memoWidgetName,
        androidName: _memoWidgetName,
      );
    } catch (e) {
      // 메모 위젯 업데이트 실패 시 조용히 무시
    }
  }
  
  /// 최근 메모 항목 가져오기
  /// 
  /// 일반 메모 중 최근 10개를 가져옵니다.
  Future<List<DiaryEntry>> _getRecentMemos() async {
    try {
      final allEntries = await _storageService.loadAllEntries();
      
      // 일반 메모만 필터링
      final memos = allEntries.where((e) => e.type == EntryType.general).toList();
      
      // 수정일 기준 내림차순 정렬
      memos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      // 최근 10개만 반환
      return memos.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  /// 특정 메모를 단일 메모 위젯에 설정
  /// 
  /// 사용자가 위젯 설정에서 특정 메모를 선택했을 때 호출됩니다.
  /// 선택된 메모의 데이터를 위젯에 저장합니다.
  /// 
  /// @param widgetId : 위젯 ID (여러 개의 메모 위젯 구분용)
  /// @param memoId : 표시할 메모의 ID
  Future<void> setSingleMemoForWidget(int widgetId, String memoId) async {
    try {
      final entry = await _storageService.loadEntry(memoId);
      if (entry != null) {
        // 날짜 포맷팅 (메모 타입에 따라 다르게 처리)
        final date = entry.type == EntryType.dated && entry.date != null
            ? DateFormat('yyyy년 M월 d일').format(DateTime.parse(entry.date!))
            : DateFormat('yyyy년 M월 d일').format(entry.updatedAt);
        
        // 일반 메모는 이모지가 없으므로 빈 문자열 사용
        final allEmojis = entry.type == EntryType.general ? [] : [...entry.moods, ...entry.customEmojis];
        
        // 위젯별 데이터 저장
        await HomeWidget.saveWidgetData<String>('single_memo_widget_${widgetId}_id', memoId);
        await HomeWidget.saveWidgetData<String>('single_memo_widget_${widgetId}_date', date);
        await HomeWidget.saveWidgetData<String>('single_memo_widget_${widgetId}_title', 
            entry.title.isEmpty ? '제목 없음' : entry.title);
        await HomeWidget.saveWidgetData<String>('single_memo_widget_${widgetId}_content', entry.content);
        await HomeWidget.saveWidgetData<String>('single_memo_widget_${widgetId}_icons', allEmojis.join(' '));
        await HomeWidget.saveWidgetData<String>('single_memo_widget_${widgetId}_type', 
            entry.type == EntryType.dated ? 'dated' : 'general');
        
        // 위젯 업데이트
        await HomeWidget.updateWidget(
          name: _singleMemoWidgetName,
          androidName: _singleMemoWidgetName,
        );
      }
    } catch (e) {
      // 메모 설정 실패 시 조용히 무시
    }
  }

  /// 단일 메모 위젯에서 메모 제거
  /// 
  /// 사용자가 위젯에서 메모를 제거하거나 메모가 삭제되었을 때 호출됩니다.
  /// 해당 위젯의 모든 데이터를 초기화합니다.
  Future<void> removeSingleMemoFromWidget(int widgetId) async {
    try {
      await HomeWidget.saveWidgetData<String>('single_memo_widget_${widgetId}_id', '');
      await HomeWidget.saveWidgetData<String>('single_memo_widget_${widgetId}_date', '');
      await HomeWidget.saveWidgetData<String>('single_memo_widget_${widgetId}_title', '');
      await HomeWidget.saveWidgetData<String>('single_memo_widget_${widgetId}_content', '');
      await HomeWidget.saveWidgetData<String>('single_memo_widget_${widgetId}_icons', '');
      await HomeWidget.saveWidgetData<String>('single_memo_widget_${widgetId}_type', '');
      
      // 위젯 업데이트
      await HomeWidget.updateWidget(
        name: _singleMemoWidgetName,
        androidName: _singleMemoWidgetName,
      );
    } catch (e) {
      // 메모 제거 실패 시 조용히 무시
    }
  }

  /// 전체 entries를 SharedPreferences에 저장
  /// 
  /// SingleMemoWidget 설정 화면에서 메모 목록을 표시하기 위해
  /// 전체 entries를 JSON 형태로 저장합니다.
  Future<void> _saveAllEntries() async {
    try {
      final allEntries = await _storageService.loadAllEntries();
      
      // entries를 JSON 배열로 변환
      final entriesJson = allEntries.map((entry) => {
        'id': entry.id,
        'title': entry.title,
        'content': entry.content,
        'date': entry.date ?? '',
        'type': entry.type == EntryType.dated ? 'dated' : 'general',
        'updatedAt': entry.updatedAt.toIso8601String(),
      }).toList();
      
      // JSON 문자열로 변환하여 저장
      final jsonString = jsonEncode(entriesJson);
      
      // HomeWidget를 통해 저장 (home_widget 패키지의 SharedPreferences 사용)
      await HomeWidget.saveWidgetData<String>('entries', jsonString);
      
      // SharedPreferences에도 직접 저장 (Android 위젯이 읽을 수 있도록)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('entries', jsonString);
      // Flutter가 사용하는 실제 키로도 저장 (flutter. 접두사)
      await prefs.setString('flutter.entries', jsonString);
      
      // 디버깅을 위한 로그
      print('Saved ${entriesJson.length} entries to SharedPreferences');
      print('First few characters of JSON: ${jsonString.substring(0, jsonString.length > 100 ? 100 : jsonString.length)}...');
      
      // 저장된 키 확인
      final keys = prefs.getKeys();
      print('SharedPreferences keys: $keys');
    } catch (e) {
      // 저장 실패 시 에러 로그 출력
      print('Error saving entries to SharedPreferences: $e');
    }
  }

  /// 위젯 서비스 초기화
  /// 
  /// 앱 시작 시 호출되며, 앱 그룹 ID를 설정하여
  /// 앱과 위젯 간의 데이터 공유를 가능하게 합니다.
  Future<void> initializeWidget() async {
    await HomeWidget.setAppGroupId('com.diary.app');
  }
}
