/**
 * 홈 화면 위젯
 * 
 * 다이어리 앱의 메인 화면으로, 네 개의 탭을 통해 다양한 기능에 접근할 수 있습니다.
 * - 달력 탭: 월간 캘린더 뷰로 날짜별 일기 확인
 * - 일기 탭: 날짜별 일기 목록 표시
 * - 메모 탭: 일반 메모 목록 관리
 * - 계산기 탭: 스프레드시트 스타일의 계산기
 * 
 * 플로팅 액션 버튼을 통해 탭에 따라 적절한 일기/메모 작성 기능을 제공합니다.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/diary_provider.dart';
import '../../../../core/models/diary_entry.dart';
import '../widgets/calendar_tab.dart';
import '../widgets/entries_tab.dart';
import '../widgets/general_notes_tab.dart';
import '../widgets/calculator_tab.dart';

/**
 * 홈 화면 StatefulWidget
 * 
 * 탭 컨트롤러를 관리하고 앱의 메인 네비게이션을 제공합니다.
 */
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/**
 * 홈 화면 State 클래스
 * 
 * TickerProviderStateMixin을 사용하여 탭 애니메이션을 지원합니다.
 * 앱 시작 시 데이터를 로드하고 탭 기반 네비게이션을 관리합니다.
 */
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  /// 네 개 탭(달력, 일기, 메모, 계산기)을 관리하는 컨트롤러
  late TabController _tabController;
  
  /// 메모 탭에서 선택할 특정 메모 ID
  String? _targetMemoId;

  /**
   * 위젯 초기화 메서드
   * 
   * 탭 컨트롤러를 설정하고 데이터 로딩을 트리거합니다.
   * PostFrameCallback을 사용하여 위젯 빌드 완료 후 데이터를 로드합니다.
   */
  @override
  void initState() {
    super.initState();
    
    // 4개 탭을 가진 탭 컨트롤러 초기화
    _tabController = TabController(length: 4, vsync: this);
    
    // 탭 변경 시 화면 갱신
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          // 탭이 변경될 때 화면을 다시 그려서 FloatingActionButton 표시/숨김 처리
        });
      }
    });
    
    // 위젯 빌드 완료 후 저장된 일기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiaryProvider>().loadEntries();
      
      // 위젯에서 전달된 viewMemoId 또는 tabIndex 처리
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is Map<String, dynamic>) {
        final viewMemoId = arguments['viewMemoId'];
        final tabIndex = arguments['tabIndex'];
        
        if (viewMemoId != null) {
          // 메모 탭으로 이동하고 특정 메모 설정
          setState(() {
            _targetMemoId = viewMemoId;
          });
          _tabController.animateTo(2);
        } else if (tabIndex != null && tabIndex is int) {
          // 특정 탭으로 이동
          _tabController.animateTo(tabIndex);
        }
      }
    });
  }

  /**
   * 리소스 정리 메서드
   * 
   * 탭 컨트롤러를 해제하여 메모리 누수를 방지합니다.
   */
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 다이어리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: '달력'),
            Tab(icon: Icon(Icons.book), text: '일기'),
            Tab(icon: Icon(Icons.note), text: '메모'),
            Tab(icon: Icon(Icons.calculate), text: '계산기'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const CalendarTab(),
                  const EntriesTab(),
                  GeneralNotesTab(targetMemoId: _targetMemoId),
                  const CalculatorTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          final selectedIndex = _tabController.index;
          final diaryProvider = context.read<DiaryProvider>();
          
          if (selectedIndex == 0 || selectedIndex == 1) {
            // 달력/일기 탭: 날짜별 메모 추가 + 일반 메모 추가
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 일반 메모 추가 버튼
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: FloatingActionButton(
                      heroTag: "general_note",
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/write',
                          arguments: DiaryEntry(
                            title: '',
                            content: '',
                            type: EntryType.general,
                          ),
                        );
                      },
                      backgroundColor: Colors.orange,
                      child: const Icon(Icons.note_add, size: 28),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 날짜별 메모 추가 버튼 (메인)
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: FloatingActionButton(
                      heroTag: "dated_note",
                      onPressed: () {
                        final selectedDate = diaryProvider.selectedDate;
                        final existingEntry = diaryProvider.getEntryForDate(selectedDate);
                        
                        if (existingEntry != null) {
                          // 기존 메모가 있으면 편집
                          Navigator.pushNamed(context, '/write', arguments: existingEntry);
                        } else {
                          // 새 메모 작성
                          Navigator.pushNamed(
                            context,
                            '/write',
                            arguments: DiaryEntry(
                              date: _formatDate(selectedDate),
                              title: '',
                              content: '',
                              type: EntryType.dated,
                            ),
                          );
                        }
                      },
                      child: const Icon(Icons.add, size: 32),
                    ),
                  ),
                ],
              ),
            );
          } else if (selectedIndex == 2) {
            // 메모 탭: 일반 메모 추가 + 날짜별 메모 추가
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 날짜별 메모 추가 버튼
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: FloatingActionButton(
                      heroTag: "dated_note_small",
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/write',
                          arguments: DiaryEntry(
                            date: _formatDate(DateTime.now()),
                            title: '',
                            content: '',
                            type: EntryType.dated,
                          ),
                        );
                      },
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
                      child: const Icon(Icons.calendar_today, size: 28),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 일반 메모 추가 버튼 (메인)
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: FloatingActionButton(
                      heroTag: "general_note_main",
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/write',
                          arguments: DiaryEntry(
                            title: '',
                            content: '',
                            type: EntryType.general,
                          ),
                        );
                      },
                      backgroundColor: Colors.orange,
                      child: const Icon(Icons.note_add, size: 32),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // 계산기 탭: FloatingActionButton 숨기기
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
