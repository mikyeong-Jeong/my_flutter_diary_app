import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/diary_provider.dart';
import '../../../../core/models/diary_entry.dart';
import '../../../write/presentation/screens/write_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<String> _selectedTags = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('검색'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '제목이나 내용을 검색하세요',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                _performSearch();
              },
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                _performSearch();
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 태그 필터
          _buildTagFilter(),
          
          // 검색 결과
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildTagFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '태그 필터',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_selectedTags.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedTags.clear();
                    });
                    _performSearch();
                  },
                  child: const Text('전체 해제'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 모든 사용된 태그들 표시
          Consumer<DiaryProvider>(
            builder: (context, diaryProvider, child) {
              final allUsedTags = diaryProvider.tagFrequency.keys.toList();
              allUsedTags.sort();
              
              if (allUsedTags.isEmpty) {
                return Text(
                  '사용된 태그가 없습니다',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
                );
              }
              
              return Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: allUsedTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  final count = diaryProvider.tagFrequency[tag] ?? 0;
                  
                  return FilterChip(
                    label: Text('$tag ($count)'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                      _performSearch();
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<DiaryProvider>(
      builder: (context, diaryProvider, child) {
        if (_isSearching) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final results = diaryProvider.filteredEntries;

        if (_searchController.text.isEmpty && _selectedTags.isEmpty) {
          return _buildSearchPrompt();
        }

        if (results.isEmpty) {
          return _buildNoResults();
        }

        return _buildResultsList(results);
      },
    );
  }

  Widget _buildSearchPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            '검색어를 입력하거나 태그를 선택하세요',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '제목, 내용, 태그로 일기를 찾을 수 있습니다',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            '검색 결과가 없습니다',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 검색어나 태그를 시도해보세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<DiaryEntry> results) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final entry = results[index];
        return _buildResultCard(entry);
      },
    );
  }

  Widget _buildResultCard(DiaryEntry entry) {
    final entryDate = DateTime.parse(entry.date);
    final formattedDate = DateFormat('M월 d일 (E)', 'ko_KR').format(entryDate);
    final searchQuery = _searchController.text.toLowerCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WriteScreen(),
              settings: RouteSettings(arguments: entry),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 (날짜와 아이콘)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (entry.icons.isNotEmpty)
                    Row(
                      children: entry.icons.take(3).map((icon) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            icon,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // 제목 (검색어 하이라이트)
              RichText(
                text: _buildHighlightedText(
                  entry.title,
                  searchQuery,
                  Theme.of(context).textTheme.titleLarge!,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // 내용 (검색어 하이라이트)
              RichText(
                text: _buildHighlightedText(
                  entry.content,
                  searchQuery,
                  Theme.of(context).textTheme.bodyMedium!,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // 태그들
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: entry.tags.map((tag) {
                    final isSelectedTag = _selectedTags.contains(tag);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelectedTag
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                            : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: isSelectedTag
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelectedTag
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).colorScheme.secondary,
                          fontWeight: isSelectedTag ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // 수정 시간
              const SizedBox(height: 12),
              Text(
                '수정됨: ${DateFormat('HH:mm').format(DateTime.parse(entry.lastModified))}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextSpan _buildHighlightedText(String text, String query, TextStyle baseStyle) {
    if (query.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    int start = 0;
    int index = lowerText.indexOf(lowerQuery);
    
    while (index != -1) {
      // 하이라이트되지 않은 텍스트 추가
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: baseStyle,
        ));
      }
      
      // 하이라이트된 텍스트 추가
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: baseStyle.copyWith(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }
    
    // 남은 텍스트 추가
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: baseStyle,
      ));
    }
    
    return TextSpan(children: spans);
  }

  void _performSearch() {
    setState(() {
      _isSearching = true;
    });

    // 디바운싱을 위한 짧은 지연
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        final diaryProvider = context.read<DiaryProvider>();
        diaryProvider.setSearchQuery(_searchController.text);
        diaryProvider.setSelectedTags(_selectedTags);
        
        setState(() {
          _isSearching = false;
        });
      }
    });
  }
}
