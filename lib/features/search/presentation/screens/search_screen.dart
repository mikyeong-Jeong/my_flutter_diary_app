import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/diary_provider.dart';
import '../../../../core/models/diary_entry.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  List<DiaryEntry> _datedResults = [];
  List<DiaryEntry> _generalResults = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // 초기에 전체 메모를 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch(''); // 빈 문자열로 전체 메모 로드
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      final diaryProvider = context.read<DiaryProvider>();
      
      if (_searchQuery.isEmpty) {
        // 검색어가 없으면 전체 메모를 표시
        _datedResults = diaryProvider.datedEntries
          ..sort((a, b) => b.date!.compareTo(a.date!));
        _generalResults = diaryProvider.generalNotes
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      } else {
        // 날짜별 메모 검색
        _datedResults = diaryProvider.datedEntries.where((entry) {
          return entry.title.toLowerCase().contains(_searchQuery) ||
                 entry.content.toLowerCase().contains(_searchQuery) ||
                 entry.allEmojis.any((emoji) => emoji.contains(_searchQuery)) ||
                 entry.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
        }).toList()
          ..sort((a, b) => b.date!.compareTo(a.date!));
          
        // 일반 메모 검색
        _generalResults = diaryProvider.generalNotes.where((entry) {
          return entry.title.toLowerCase().contains(_searchQuery) ||
                 entry.content.toLowerCase().contains(_searchQuery) ||
                 entry.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
        }).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('검색'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '날짜별 메모 (${_datedResults.length})'),
            Tab(text: '일반 메모 (${_generalResults.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 검색 바
          Container(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '제목, 내용, 태그로 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
              ),
              onChanged: _performSearch,
            ),
          ),
          
          // 검색 결과
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSearchResults(_datedResults, true),
                _buildSearchResults(_generalResults, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<DiaryEntry> results, bool isDated) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '다른 키워드로 검색해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final entry = results[index];
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
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 타입 표시와 이모지
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDated ? Colors.blue[100] : Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isDated ? '날짜별' : '일반',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDated ? Colors.blue[800] : Colors.green[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
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
                  // 제목
                  if (entry.title.isNotEmpty) ...[
                    Text(
                      entry.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // 내용
                  Text(
                    entry.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  // 태그
                  if (entry.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: entry.tags
                          .map((tag) => Chip(
                                label: Text(tag, style: const TextStyle(fontSize: 12)),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // 날짜 정보
                  Text(
                    isDated
                        ? entry.formattedDate
                        : '수정: ${entry.formattedUpdatedAt}',
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
    );
  }
}
