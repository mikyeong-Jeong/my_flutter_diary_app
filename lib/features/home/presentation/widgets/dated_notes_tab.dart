import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/diary_provider.dart';
import '../../../../core/models/diary_entry.dart';

/// 할 일 탭 위젯
/// 
/// 모든 할 일을 목록으로 보여주고 텍스트 검색 기능을 제공하는 탭입니다.
/// 하루에 여러 개의 할 일을 작성할 수 있으며, 제목과 내용을 기준으로 검색할 수 있습니다.
class DatedNotesTab extends StatefulWidget {
  const DatedNotesTab({super.key});

  @override
  State<DatedNotesTab> createState() => _DatedNotesTabState();
}

class _DatedNotesTabState extends State<DatedNotesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 검색어 업데이트
  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  /// 검색어 초기화
  void _clearSearch() {
    _searchController.clear();
    _updateSearchQuery('');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DiaryProvider>(
      builder: (context, diaryProvider, child) {
        // 모든 할 일 가져오기
        List<DiaryEntry> datedNotes = List.from(diaryProvider.datedNotes);
        
        // 검색어가 있으면 필터링
        if (_searchQuery.isNotEmpty) {
          datedNotes = datedNotes.where((note) {
            return note.title.toLowerCase().contains(_searchQuery) ||
                   note.content.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        return Column(
          children: [
            // 검색 영역
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _updateSearchQuery,
                      decoration: InputDecoration(
                        hintText: '제목이나 내용으로 검색...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearSearch,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 할 일 목록 영역
            Expanded(
              child: datedNotes.isEmpty
                  ? _buildEmptyState()
                  : _buildMemoList(datedNotes),
            ),
          ],
        );
      },
    );
  }

  /// 할 일이 없을 때의 빈 상태 UI
  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      // 검색 결과가 없을 때
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '"$_searchQuery"에 대한 검색 결과가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '다른 검색어를 시도해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    } else {
      // 할 일이 전혀 없을 때
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '작성된 할 일이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '첫 번째 할 일을 작성해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
  }

  /// 할 일 목록 UI
  Widget _buildMemoList(List<DiaryEntry> notes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () async {
              // 편집 화면으로 이동하고 결과를 기다림
              await Navigator.pushNamed(context, '/dated_note', arguments: note);
              // 돌아온 후 명시적으로 새로고침
              if (mounted) {
                setState(() {});
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 표시
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      note.date != null 
                          ? DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(DateTime.parse(note.date!))
                          : '날짜 없음',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 제목
                  if (note.title.isNotEmpty) ...[
                    Text(
                      note.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // 내용 (전체)
                  if (note.content.isNotEmpty) ...[
                    Text(
                      note.content,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // 메타 정보
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '생성: ${note.formattedCreatedAt}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.grey[500],
                      ),
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