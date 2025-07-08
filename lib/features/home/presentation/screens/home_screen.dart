import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/diary_provider.dart';
import '../../../../core/models/diary_entry.dart';
import '../widgets/calendar_tab.dart';
import '../widgets/entries_tab.dart';
import '../widgets/general_notes_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiaryProvider>().loadEntries();
    });
  }

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
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  CalendarTab(),
                  EntriesTab(),
                  GeneralNotesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer<DiaryProvider>(
        builder: (context, diaryProvider, child) {
          final selectedIndex = _tabController.index;
          
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
          } else {
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
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
