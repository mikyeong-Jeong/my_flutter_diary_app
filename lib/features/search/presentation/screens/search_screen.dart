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
  String _searchQuery = '';
  List<String> _availableTags = [];
  List<String> _selectedTags = [];
  bool _showTagFilter = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // 초기에 태그 목록을 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailableTags();
    });
  }

  void _loadAvailableTags() {
    final diaryProvider = context.read<DiaryProvider>();
    final allTags = <String>{};
    
    for (final entry in diaryProvider.entries) {
      allTags.addAll(entry.tags);
    }
    
    setState(() {
      _availableTags = allTags.toList()..sort();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<DiaryEntry> _filterEntries(List<DiaryEntry> entries) {
    List<DiaryEntry> filteredEntries = entries;
    
    // 태그 필터 적용
    if (_selectedTags.isNotEmpty) {
      filteredEntries = filteredEntries.where((entry) {
        return _selectedTags.any((tag) => entry.tags.contains(tag));
      }).toList();
    }
    
    // 텍스트 검색 적용
    if (_searchQuery.isNotEmpty) {
      filteredEntries = filteredEntries.where((entry) {
        return entry.title.toLowerCase().contains(_searchQuery) ||
               entry.content.toLowerCase().contains(_searchQuery) ||
               entry.allEmojis.any((emoji) => emoji.contains(_searchQuery)) ||
               entry.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
      }).toList();
    }
    
    return filteredEntries;
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DiaryProvider>(
      builder: (context, diaryProvider, child) {
        // 태그 목록 업데이트
        final allTags = <String>{};
        for (final entry in diaryProvider.entries) {
          allTags.addAll(entry.tags);
        }
        _availableTags = allTags.toList()..sort();

        // 검색 결과 계산
        final datedResults = _filterEntries(diaryProvider.datedEntries);
        datedResults.sort((a, b) => b.date!.compareTo(a.date!));
        
        final generalResults = _filterEntries(diaryProvider.generalNotes);
        generalResults.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        return Scaffold(
          appBar: AppBar(
            title: const Text('검색'),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: '날짜별 메모 (${datedResults.length})'),
                Tab(text: '일반 메모 (${generalResults.length})'),
              ],
            ),
          ),
          body: Column(
            children: [
              // 검색 바
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '제목, 내용, 태그로 검색',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch('');
                                },
                              ),
                            IconButton(
                              icon: Icon(
                                _showTagFilter ? Icons.filter_list : Icons.filter_list_outlined,
                                color: _selectedTags.isNotEmpty ? Theme.of(context).primaryColor : null,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showTagFilter = !_showTagFilter;
                                });
                              },
                            ),
                          ],
                        ),
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
                    
                    // 태그 필터 UI
                    if (_showTagFilter) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '태그로 필터링',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (_selectedTags.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedTags.clear();
                                      });
                                    },
                                    child: const Text('초기화'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_availableTags.isEmpty)
                              const Text(
                                '사용 가능한 태그가 없습니다',
                                style: TextStyle(color: Colors.grey),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: _availableTags.map((tag) {
                                  final isSelected = _selectedTags.contains(tag);
                                  return FilterChip(
                                    label: Text(tag),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedTags.add(tag);
                                        } else {
                                          _selectedTags.remove(tag);
                                        }
                                      });
                                    },
                                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // 검색 결과
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSearchResults(datedResults, true),
                    _buildSearchResults(generalResults, false),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
