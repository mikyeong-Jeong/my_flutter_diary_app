import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/diary_provider.dart';
import '../../../../core/models/diary_entry.dart';

/// 검색 화면 위젯
/// 
/// 일기와 메모를 검색할 수 있는 화면입니다.
/// - 텍스트 검색: 제목과 내용에서 키워드 검색
/// - 태그 필터: 특정 태그로 필터링
/// - 날짜 범위: 특정 기간의 일기 검색
/// - 탭 분리: 날짜별 일기와 일반 메모 각각 검색
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
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // 2개 탭(날짜별 일기, 일반 메모) 컨트롤러 초기화
    _tabController = TabController(length: 2, vsync: this);
    
    // 초기에 태그 목록을 로드 - 태그 필터링에 사용
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailableTags();
    });
  }

  /// 사용 가능한 태그 목록 로드
  /// 
  /// 모든 일기와 메모에서 사용된 태그를 수집해서
  /// 필터링에 사용할 태그 목록을 만듭니다.
  void _loadAvailableTags() {
    final diaryProvider = context.read<DiaryProvider>();
    final allTags = <String>{};
    
    // 모든 엔트리에서 태그 수집
    for (final entry in diaryProvider.entries) {
      allTags.addAll(entry.tags);
    }
    
    // 알파벳 순으로 정렬
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

  List<DiaryEntry> _filterEntries(List<DiaryEntry> entries, bool isDated) {
    List<DiaryEntry> filteredEntries = entries;
    
    // 태그 필터 적용
    if (_selectedTags.isNotEmpty) {
      filteredEntries = filteredEntries.where((entry) {
        return _selectedTags.any((tag) => entry.tags.contains(tag));
      }).toList();
    }
    
    // 날짜 필터 적용
    if (_startDate != null || _endDate != null) {
      filteredEntries = filteredEntries.where((entry) {
        DateTime? targetDate;
        
        if (isDated) {
          // 캘린더 메모: 해당 날짜 기준
          if (entry.date != null) {
            targetDate = DateTime.parse(entry.date!);
          }
        } else {
          // 일반 메모: 생성일 기준
          targetDate = entry.createdAt;
        }
        
        if (targetDate == null) return false;
        
        // 날짜만 비교 (시간 제외)
        final dateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
        
        if (_startDate != null && _endDate != null) {
          return dateOnly.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
                 dateOnly.isBefore(_endDate!.add(const Duration(days: 1)));
        } else if (_startDate != null) {
          return dateOnly.isAfter(_startDate!.subtract(const Duration(days: 1)));
        } else if (_endDate != null) {
          return dateOnly.isBefore(_endDate!.add(const Duration(days: 1)));
        }
        
        return true;
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

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      helpText: '검색할 기간을 선택하세요',
      cancelText: '취소',
      confirmText: '적용',
      saveText: '저장',
      errorFormatText: '잘못된 날짜 형식입니다',
      errorInvalidText: '유효하지 않은 날짜입니다',
      errorInvalidRangeText: '유효하지 않은 기간입니다',
      fieldStartHintText: '시작 날짜',
      fieldEndHintText: '종료 날짜',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    } else {
      // 사용자가 취소했지만 기존 날짜 필터가 있다면 초기화할지 물어보기
      if (_startDate != null || _endDate != null) {
        final bool? shouldClear = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('날짜 필터'),
            content: const Text('날짜 필터를 초기화하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('아니오'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('초기화'),
              ),
            ],
          ),
        );
        
        if (shouldClear == true) {
          setState(() {
            _startDate = null;
            _endDate = null;
          });
        }
      }
    }
  }

  String _getDateFilterDisplayText() {
    if (_startDate == null && _endDate == null) {
      return '';
    } else if (_startDate != null && _endDate != null) {
      if (_startDate!.isAtSameMomentAs(_endDate!)) {
        return DateFormat('yyyy-MM-dd').format(_startDate!);
      } else {
        return '${DateFormat('yyyy-MM-dd').format(_startDate!)} ~ ${DateFormat('yyyy-MM-dd').format(_endDate!)}';
      }
    } else if (_startDate != null) {
      return '${DateFormat('yyyy-MM-dd').format(_startDate!)} 이후';
    } else {
      return '${DateFormat('yyyy-MM-dd').format(_endDate!)} 이전';
    }
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
        final datedResults = _filterEntries(diaryProvider.datedEntries, true);
        datedResults.sort((a, b) => b.date!.compareTo(a.date!));
        
        final generalResults = _filterEntries(diaryProvider.generalNotes, false);
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
                                Icons.date_range,
                                color: (_startDate != null || _endDate != null) 
                                    ? Theme.of(context).primaryColor 
                                    : null,
                              ),
                              onPressed: _selectDateRange,
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
                    
                    // 활성화된 필터 표시
                    if (_startDate != null || _endDate != null || _selectedTags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '활성 필터',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _startDate = null;
                                      _endDate = null;
                                      _selectedTags.clear();
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                  ),
                                  child: const Text(
                                    '모두 초기화',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                // 날짜 필터 표시
                                if (_startDate != null || _endDate != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.blue[300]!),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.date_range,
                                          size: 12,
                                          color: Colors.blue[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getDateFilterDisplayText(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _startDate = null;
                                              _endDate = null;
                                            });
                                          },
                                          child: Icon(
                                            Icons.close,
                                            size: 12,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                // 선택된 태그들 표시
                                ..._selectedTags.map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.tag,
                                        size: 12,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        tag,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedTags.remove(tag);
                                          });
                                        },
                                        child: Icon(
                                          Icons.close,
                                          size: 12,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    
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
      String emptyMessage = '검색 결과가 없습니다';
      String subMessage = '다른 키워드나 필터를 사용해보세요';
      
      if (_startDate != null || _endDate != null) {
        subMessage = '선택한 기간에 해당하는 메모가 없습니다';
      } else if (_selectedTags.isNotEmpty) {
        subMessage = '선택한 태그가 포함된 메모가 없습니다';
      } else if (_searchQuery.isNotEmpty) {
        subMessage = '검색어와 일치하는 메모가 없습니다';
      }
      
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
              emptyMessage,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
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
                '/read',
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
                                backgroundColor: _selectedTags.contains(tag) 
                                    ? Theme.of(context).primaryColor.withOpacity(0.3)
                                    : null,
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // 날짜 정보 (개선됨)
                  Row(
                    children: [
                      if (isDated) ...[
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '날짜: ${entry.formattedDate}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '작성: ${entry.formattedCreatedAt}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.create,
                          size: 14,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '생성: ${entry.formattedCreatedAt}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '수정: ${entry.formattedUpdatedAt}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
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
