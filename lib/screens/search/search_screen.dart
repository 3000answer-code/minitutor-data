import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/lecture.dart';
import '../../models/consultation.dart';
import '../../services/app_state.dart';
import '../../services/translations.dart';
import '../../theme/app_theme.dart';
import '../../screens/profile/profile_drawer.dart';
import '../lecture/lecture_player_screen.dart';
import '../search/note_search_viewer_screen.dart';
import '../../widgets/lecture_card.dart';

// 주황색 포인트 컬러 (캡처 화면 기준)
const Color _kOrange = Color(0xFFF97316);

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late TabController _tabController;
  bool _isSearching = false;
  String _searchResult = '';
  String _selectedGrade = '';
  String _selectedSubject = '';
  String _sortBy = '관련순';
  bool _autoPlay = false;
  String _lastHandledQuery = ''; // 외부 쿼리 중복 처리 방지
  // 과목 카드(검색하기)에서 진입 시 과목 범위 기억
  String _categoryFilter = ''; // '수학' | '과학' | '두번설명' | ''

  final List<String> _sortOptions = ['관련순', '최신순', '평점순', '조회순'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // 앱 시작 시 이미 searchQuery가 설정되어 있으면 자동 검색
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final q = context.read<AppState>().searchQuery;
      if (q.isNotEmpty) {
        _triggerExternalSearch(q);
      }
    });
  }

  /// 외부에서 searchQuery 설정 시 자동 실행
  void _triggerExternalSearch(String query) {
    if (query.isEmpty || query == _lastHandledQuery) return;
    _lastHandledQuery = query;
    _controller.text = query;
    final appState = context.read<AppState>();
    appState.addRecentSearch(query);
    // 검색쿼리 사용 후 초기화 (중복 클릭 방지)
    appState.setSearchQuery('');
    setState(() {
      _searchResult = query;
      _isSearching = true;
      _selectedGrade = '';
      _selectedSubject = '';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (query.isEmpty) return;
    final appState = context.read<AppState>();
    appState.addRecentSearch(query);
    appState.incrementSearchCount();  // 검색수 자동 증가
    setState(() {
      _searchResult = query;
      _isSearching = true;
      _categoryFilter = '';
    });
  }

  /// 과목 카드 "검색하기" 버튼: 검색창 키워드 + 과목 범위 조합 검색
  void _searchInCategory(String category) {
    final keyword = _controller.text.trim();
    final appState = context.read<AppState>();
    if (keyword.isNotEmpty) {
      appState.addRecentSearch(keyword);
      appState.incrementSearchCount();  // 검색수 자동 증가
    }
    setState(() {
      _searchResult = keyword; // 빈 문자열이면 전체 표시
      _isSearching = true;
      _categoryFilter = category;
      _selectedGrade = '';
      _selectedSubject = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);

    // 외부에서 searchQuery가 설정되면 자동 검색 실행 (build 중 안전 처리)
    final externalQuery = appState.searchQuery;
    if (externalQuery.isNotEmpty && externalQuery != _lastHandledQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerExternalSearch(externalQuery);
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: const ProfileDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.textPrimary),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchResult = '';
                _controller.clear();
              });
            } else {
              final appState = context.read<AppState>();
              appState.setNavIndex(0);
            }
          },
        ),
        centerTitle: true,
        title: const Text(
          '검색',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded,
                  color: AppColors.textPrimary, size: 24),
              tooltip: '메뉴',
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── 검색창
          _buildSearchBar(T),
          // ── 탭바
          _buildTabBar(),
          // ── 구분선
          Container(height: 1, color: const Color(0xFFEEEEEE)),
          // ── 본문
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // 탭1: 동영상
                _isSearching
                    ? _buildSearchResults(appState)
                    : _buildSearchHome(appState),
                // 탭2: 전문가 상담 검색
                _buildConsultationSearch(appState),
                // 탭3: 노트 검색
                _buildNoteSearchResults(appState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(String Function(String) T) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(23),
        ),
        child: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: T('search_hint2'),
            hintStyle: const TextStyle(
                fontSize: 14, color: Color(0xFFAAAAAA), fontWeight: FontWeight.w400),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 8),
              child: Icon(Icons.search_rounded, size: 22, color: _kOrange),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFFAAAAAA)),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _isSearching = false;
                        _searchResult = '';
                      });
                    },
                  )
                : null,
          ),
          onSubmitted: _search,
          onChanged: (v) => setState(() {}),
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: '동영상'),
        Tab(text: '내 상담'),
        Tab(text: '노트 검색'),
      ],
      labelColor: _kOrange,
      unselectedLabelColor: const Color(0xFF666666),
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelStyle:
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      indicatorColor: _kOrange,
      indicatorWeight: 2.5,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
    );
  }

  // ── 탭3: 노트 검색 결과 ─────────────────────────────────────
  Widget _buildNoteSearchResults(AppState appState) {
    final query = _controller.text.trim();

    // 검색어가 없으면 안내 화면만 표시 (목록 노출 금지)
    if (query.isEmpty) {
      return _buildNotePrompt();
    }

    String normalize(String s) =>
        s.replaceAll(RegExp(r'[\s_\-]+'), '').toLowerCase();
    final nq = normalize(query);

    // 교안이 있는 강의만 대상 (실제 교안 페이지가 하나라도 있으면 포함)
    var pool = appState.getLecturesBySubject('전체')
        .where((l) => l.handoutUrls.any((u) => u.isNotEmpty && !u.endsWith('.mp4')))
        .toList();

    // 검색어 필터
    List<Lecture> results;
    if (nq.isEmpty) {
      results = pool;
    } else {
      // 1순위: 제목에 검색어 포함
      final titleMatch = pool
          .where((l) => normalize(l.title).contains(nq))
          .toList();
      // 2순위: 해시태그에 포함 (제목 매칭 제외)
      final hashMatch = pool
          .where((l) =>
              !normalize(l.title).contains(nq) &&
              l.hashtags.any((h) => normalize(h).contains(nq)))
          .toList();
      results = [...titleMatch, ...hashMatch];
    }

    // 정렬: 중등→고등, 수학→과학 순
    final gradeOrder = {'elementary': 0, 'middle': 1, 'high': 2};
    final subjectOrder = {'수학': 0, '과학': 1, '물리': 2, '화학': 3, '생명과학': 4, '지구과학': 5};
    results.sort((a, b) {
      final ga = gradeOrder[a.grade] ?? 9;
      final gb = gradeOrder[b.grade] ?? 9;
      if (ga != gb) return ga.compareTo(gb);
      final sa = subjectOrder[a.subject] ?? 9;
      final sb = subjectOrder[b.subject] ?? 9;
      return sa.compareTo(sb);
    });

    if (results.isEmpty) {
      return _buildNoteEmptyState('\'$query\' 관련 교안 강의가 없습니다');
    }

    return Column(children: [
      // ── 결과 수 헤더 ────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // 책 아이콘
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.menu_book_rounded, size: 15, color: _kOrange),
          ),
          const SizedBox(width: 8),
          // 검색어 + 결과 수
          Expanded(
            child: nq.isNotEmpty
                ? RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      children: [
                        TextSpan(
                          text: '\'$query\'',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _kOrange,
                          ),
                        ),
                        const TextSpan(text: ' 교안 '),
                        TextSpan(
                          text: '${results.length}건',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  )
                : RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      children: [
                        const TextSpan(text: '전체 교안 '),
                        TextSpan(
                          text: '${results.length}건',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
          ),
        ]),
      ),
      Container(height: 1, color: const Color(0xFFF0F0F0)),
      // ── 결과 목록 ───────────────────────────────
      Expanded(
        child: ColoredBox(
          color: const Color(0xFFF4F6F8),
          child: ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 100),
          itemCount: results.length,
          itemBuilder: (_, i) {
            return _buildNoteCard(results[i], results, i, appState);
          },
        ),
        ), // ColoredBox
      ),
    ]);
  }

  // ── 노트 검색 카드 (520 스타일 3줄 · 내용 중심부 배치) ──────────
  Widget _buildNoteCard(Lecture lec, List<Lecture> allResults, int index, AppState appState) {
    Color subjectColor;
    switch (lec.subject) {
      case '수학':     subjectColor = AppColors.math; break;
      case '과학':     subjectColor = AppColors.science; break;
      case '물리':     subjectColor = AppColors.physics; break;
      case '화학':     subjectColor = AppColors.chemistry; break;
      case '생명과학': subjectColor = AppColors.biology; break;
      case '지구과학': subjectColor = AppColors.earth; break;
      default:         subjectColor = _kOrange; break;
    }

    // 유효한 교안 URL 목록 (비어있지 않고 mp4 아닌 것)
    final realUrls = lec.handoutUrls
        .where((u) => u.isNotEmpty && !u.endsWith('.mp4'))
        .toList();
    final thumbUrl = realUrls.isNotEmpty ? realUrls.first : '';

    // 썸네일 위젯
    Widget thumbInner;
    if (thumbUrl.isEmpty) {
      thumbInner = Container(
        color: subjectColor.withValues(alpha: 0.08),
        child: Center(child: Icon(Icons.description_rounded,
            size: 28, color: subjectColor.withValues(alpha: 0.35))),
      );
    } else if (thumbUrl.startsWith('assets/')) {
      thumbInner = Center(
        child: Image.asset(thumbUrl,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => Container(
              color: subjectColor.withValues(alpha: 0.08),
              child: Center(child: Icon(Icons.description_rounded,
                  size: 28, color: subjectColor.withValues(alpha: 0.35))),
            )));
    } else {
      thumbInner = Center(
        child: Image.network(thumbUrl,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => Container(
              color: subjectColor.withValues(alpha: 0.08),
              child: Center(child: Icon(Icons.description_rounded,
                  size: 28, color: subjectColor.withValues(alpha: 0.35))),
            )));
    }

    // 학제 색상
    Color gradeColor;
    switch (lec.grade) {
      case 'elementary': gradeColor = AppColors.elementary; break;
      case 'middle':     gradeColor = AppColors.middle; break;
      default:           gradeColor = AppColors.high; break;
    }
    final yearLabel = lec.gradeYear.isEmpty || lec.gradeYear == 'All'
        ? 'All' : '${lec.gradeYear}학년';
    const Color allBadgeColor = Color(0xFFF97316);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => NoteSearchViewerScreen(
            lectures: allResults, initialIndex: index),
      )),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 썸네일: 고정 너비 105 ──────────────
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                  child: Container(
                    width: 105,
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: thumbInner,
                  ),
                ),

                // ── 본문 정보 영역 (세로 중앙 정렬) ─────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1줄: 강의 제목 (520 스타일)
                        Text(lec.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.3)),

                        const SizedBox(height: 4),

                        // 2줄: 시리즈명 (없으면 "시리즈") — 520 스타일 아이콘+회색
                        Row(children: [
                          Icon(Icons.playlist_play_rounded,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              lec.series.isNotEmpty ? lec.series : '시리즈',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ]),

                        const SizedBox(height: 4),

                        // 3줄: 학제 배지 + 학년 배지 + 과목 배지 + 강사명 (520 스타일)
                        Row(children: [
                          _noteBadge520(lec.gradeText, gradeColor),
                          const SizedBox(width: 3),
                          _noteBadge520(yearLabel, yearLabel == 'All' ? allBadgeColor : gradeColor.withValues(alpha: 0.65)),
                          const SizedBox(width: 3),
                          _noteBadge520(lec.subject, subjectColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(lec.instructor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),

                // ── 영상 버튼: 오른쪽 세로 중앙 ───────────
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    appState.addRecentView(lec.id);
                    if (appState.pipActive && appState.pipLecture?.id == lec.id) {
                      appState.deactivatePip();
                    }
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => LecturePlayerScreen(lecture: lec),
                    ));
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 10, 0),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: subjectColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow_rounded,
                          color: subjectColor, size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 520 스타일 배지 헬퍼 (LectureCard와 동일) ──────────
  Widget _noteBadge520(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
    ),
    child: Text(label,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w700)),
  );

  Widget _buildNoteEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_outlined, size: 44, color: _kOrange),
          ),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('검색어를 입력하면 교안을 찾아드려요',
              style: TextStyle(color: AppColors.textHint, fontSize: 13)),
        ],
      ),
    );
  }

  // ── 노트 검색: 검색어 입력 전 안내 화면 ───────────────────
  Widget _buildNotePrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_rounded, size: 46, color: _kOrange),
          ),
          const SizedBox(height: 18),
          const Text(
            '교안 검색',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            '검색어를 입력하면\n해당 단어가 포함된 강의 교안을 찾아드려요',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '예) 방정식, 세포분열, 이차함수',
              style: TextStyle(
                  fontSize: 12,
                  color: _kOrange,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── 전문가 상담: 검색어 입력 전 안내 화면 ─────────────────
  Widget _buildConsultationPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.question_answer_rounded,
                size: 46, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 18),
          const Text(
            '내 상담 검색',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            '검색어를 입력하면\n질문·답변에 해당 단어가 포함된\n상담 내용을 보여드려요',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '예) 방정식, 세포, 인수분해',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 탭2: 전문가 상담 검색 (검색어가 포함된 질문·답변 목록)
  // ══════════════════════════════════════════════════════════
  Widget _buildConsultationSearch(AppState appState) {
    final query = _controller.text.trim();

    // 검색어가 없으면 안내 화면만 표시 (목록 노출 금지)
    if (query.isEmpty) {
      return _buildConsultationPrompt();
    }

    String normalize(String s) => s.toLowerCase();
    final nq = normalize(query);
    final all = appState.consultations;

    final List<Consultation> results = all.where((c) {
            final inTitle   = normalize(c.title).contains(nq);
            final inContent = normalize(c.content).contains(nq);
            final inAnswer  = c.answer != null &&
                normalize(c.answer!).contains(nq);
            return inTitle || inContent || inAnswer;
          }).toList();

    return Column(children: [
      // ── 헤더 ──────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.question_answer_rounded,
                size: 15, color: Color(0xFF10B981)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: nq.isNotEmpty
                ? RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      children: [
                        TextSpan(
                          text: '\'$query\'',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981)),
                        ),
                        const TextSpan(text: ' 관련 상담 '),
                        TextSpan(
                          text: '${results.length}건',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  )
                : RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      children: [
                        const TextSpan(text: '전체 내 상담 '),
                        TextSpan(
                          text: '${results.length}건',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
          ),
        ]),
      ),
      Container(height: 1, color: const Color(0xFFF0F0F0)),

      // ── 결과 목록 ─────────────────────────────────
      Expanded(
        child: results.isEmpty
            ? _buildConsultationEmpty(query)
            : ColoredBox(
                color: const Color(0xFFF4F6F8),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 100),
                  itemCount: results.length,
                  itemBuilder: (_, i) =>
                      _buildConsultationCard(results[i], query, appState),
                ),
              ),
      ),
    ]);
  }

  // ── 전문가 상담 결과 없음 ────────────────────────────────
  Widget _buildConsultationEmpty(String query) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.question_answer_outlined,
              size: 44, color: Color(0xFF10B981)),
        ),
        const SizedBox(height: 16),
        Text(
          query.isEmpty ? '검색어를 입력해 주세요' : '\'$query\' 관련 상담이 없습니다',
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text('상담 탭에서 직접 질문을 등록할 수 있어요',
            style: TextStyle(color: AppColors.textHint, fontSize: 13)),
      ]),
    );
  }

  // ── 전문가 상담 카드 (검색어 하이라이트 포함) ────────────
  Widget _buildConsultationCard(
      Consultation c, String query, AppState appState) {

    // 검색어가 일치하는 위치 표시용 RichText 빌더
    List<TextSpan> _highlight(String text, String q, TextStyle base) {
      if (q.isEmpty) return [TextSpan(text: text, style: base)];
      final lower = text.toLowerCase();
      final lq    = q.toLowerCase();
      final spans = <TextSpan>[];
      int start = 0;
      while (true) {
        final idx = lower.indexOf(lq, start);
        if (idx == -1) {
          spans.add(TextSpan(text: text.substring(start), style: base));
          break;
        }
        if (idx > start) {
          spans.add(TextSpan(text: text.substring(start, idx), style: base));
        }
        spans.add(TextSpan(
          text: text.substring(idx, idx + q.length),
          style: base.copyWith(
            color: const Color(0xFFFF6B35),
            fontWeight: FontWeight.w800,
            backgroundColor: const Color(0xFFFF6B35).withValues(alpha: 0.10),
          ),
        ));
        start = idx + q.length;
      }
      return spans;
    }

    return GestureDetector(
      onTap: () => _openConsultationDetail(context, c),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // 1행: 아바타 + 닉네임 + 시간 + 상태 배지
          Row(children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.background,
              backgroundImage: NetworkImage(c.authorProfileUrl),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(c.authorNickname,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(c.timeAgo,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textHint)),
              ]),
            ),
            // 상태 배지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: c.isAnswered
                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  c.isAnswered
                      ? Icons.check_circle_rounded
                      : Icons.schedule_rounded,
                  size: 11,
                  color: c.isAnswered
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 3),
                Text(c.statusText,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: c.isAnswered
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B))),
              ]),
            ),
          ]),

          const SizedBox(height: 8),

          // 2행: 과목/학년 태그
          Row(children: [
            _consultTag(c.subject, const Color(0xFF6366F1)),
            const SizedBox(width: 5),
            _consultTag(
              c.grade == 'middle' ? '중등' : c.grade == 'high' ? '고등' : '예비중',
              const Color(0xFF94A3B8),
            ),
          ]),

          const SizedBox(height: 6),

          // 3행: 질문 제목 (하이라이트)
          RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: _highlight(
                c.title,
                query,
                const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E)),
              ),
            ),
          ),

          const SizedBox(height: 3),

          // 4행: 질문 내용 미리보기 (하이라이트)
          RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: _highlight(
                c.content,
                query,
                const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4),
              ),
            ),
          ),

          // 5행: 답변 미리보기 (있을 경우)
          if (c.isAnswered && c.answer != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    width: 1),
              ),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Icon(Icons.check_circle_rounded,
                    size: 13, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(c.answerAuthor ?? '전문가',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981))),
                    const SizedBox(height: 2),
                    RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: _highlight(
                          c.answer!,
                          query,
                          const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              height: 1.4),
                        ),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  // 태그 뱃지 (전문가 상담용)
  Widget _consultTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  // ── 상담 상세 보기 (BottomSheet) ────────────────────────
  void _openConsultationDetail(BuildContext context, Consultation c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 14),

            // 작성자 + 상태
            Row(children: [
              CircleAvatar(
                  radius: 17,
                  backgroundImage: NetworkImage(c.authorProfileUrl)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(c.authorNickname,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(c.timeAgo,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint)),
                ]),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                    color: c.isAnswered
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(c.statusText,
                    style: TextStyle(
                        fontSize: 11,
                        color: c.isAnswered
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                        fontWeight: FontWeight.w700)),
              ),
            ]),

            const SizedBox(height: 10),

            // 과목/학년 태그
            Row(children: [
              _consultTag(c.subject, const Color(0xFF6366F1)),
              const SizedBox(width: 5),
              _consultTag(
                c.grade == 'middle'
                    ? '중등'
                    : c.grade == 'high'
                        ? '고등'
                        : '예비중',
                const Color(0xFF94A3B8),
              ),
            ]),

            const SizedBox(height: 12),

            // 질문 제목
            Text(c.title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 10),

            // 질문 내용
            Text(c.content,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.65)),

            // 답변
            if (c.isAnswered && c.answer != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 15, color: Color(0xFF10B981)),
                    const SizedBox(width: 5),
                    Text(c.answerAuthor ?? '전문가',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981))),
                    const Spacer(),
                    if (c.answeredAt != null)
                      Text(
                        c.answeredAt!.difference(DateTime.now()).abs().inDays > 0
                            ? '${c.answeredAt!.difference(DateTime.now()).abs().inDays}일 전'
                            : '${c.answeredAt!.difference(DateTime.now()).abs().inHours}시간 전',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textHint),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  Text(c.answer!,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.65)),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoon(String name) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_rounded,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('$name 준비 중',
              style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSearchHome(AppState appState) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildSubjectGrid()),
        SliverToBoxAdapter(child: _buildSearchTabs(appState)),
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  Widget _buildSearchTabs(AppState appState) {
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    return Column(children: [
      DefaultTabController(
        length: 2,
        child: Column(children: [
          TabBar(
            tabs: [
              Tab(text: T('search_popular_tab')),
              Tab(text: T('search_recent_tab')),
            ],
            labelColor: _kOrange,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: _kOrange,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: const Color(0xFFEEEEEE),
          ),
          SizedBox(
            height: 200,
            child: TabBarView(
              children: [
                _buildKeywordList(appState.popularSearches, isPopular: true),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // '최근 검색' / '전체 삭제' 헤더 — 중앙 적절 간격
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(T('search_recent_label'),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        const SizedBox(width: 40),
                        GestureDetector(
                          onTap: appState.clearRecentSearches,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(T('search_clear_all'),
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textHint)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEEEEE)),
                  Expanded(
                      child: _buildKeywordList(appState.recentSearches,
                          isPopular: false)),
                ]),
              ],
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildKeywordList(List<String> keywords, {required bool isPopular}) {
    final lang = context.read<AppState>().selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    if (keywords.isEmpty) {
      return Center(
          child: Text(T('search_no_history'),
              style: const TextStyle(color: AppColors.textHint)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: keywords.length.clamp(0, 8),
      separatorBuilder: (_, __) =>
          const Divider(height: 0, indent: 16, endIndent: 16),
      itemBuilder: (_, i) {
        return InkWell(
          onTap: () {
            _controller.text = keywords[i];
            _search(keywords[i]);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: isPopular
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text('${i + 1}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: i < 3 ? _kOrange : AppColors.textSecondary)),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120,
                        child: Text(
                          keywords[i],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const SizedBox(
                        width: 28,
                        child: Icon(Icons.history_rounded,
                            size: 18, color: AppColors.textHint),
                      ),
                      Expanded(
                        child: Text(
                          keywords[i],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: GestureDetector(
                          onTap: () {
                            context.read<AppState>().removeRecentSearch(keywords[i]);
                          },
                          child: const Icon(Icons.close,
                              size: 16, color: AppColors.textHint),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectGrid() {
    final lang = context.read<AppState>().selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    final subjects = [
      {'name': '수학', 'image': 'assets/images/banners/banner_math_new2.jpg'},
      {'name': '과학', 'image': 'assets/images/banners/banner_science_new2.jpg'},
      {'name': '두번설명', 'image': 'assets/images/banners/banner_twice.png'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(T('search_browse_subject'),
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Column(
          children: subjects.map((s) {
            return GestureDetector(
              onTap: () {
                _searchInCategory(s['name'] as String);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        s['image'] as String,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                s['name'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                '검색하기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  // ── 검색 결과 화면 (Asome Tutor 스타일)
  Widget _buildSearchResults(AppState appState) {
    String normalize(String s) =>
        s.replaceAll(RegExp(r'[\s_\-]+'), '').toLowerCase();
    final nq = normalize(_searchResult);

    // ── 1단계: 과목 범위 필터 (카테고리 카드 진입 시)
    final _scienceSubjects = ['과학','물리','화학','생명과학','지구과학','공통과학'];
    var pool = appState.getLecturesBySubject('전체');
    if (_categoryFilter == '수학') {
      pool = pool.where((l) => l.subject == '수학').toList();
    } else if (_categoryFilter == '과학') {
      pool = pool.where((l) => _scienceSubjects.contains(l.subject)).toList();
    } else if (_categoryFilter == '두번설명') {
      pool = pool.where((l) => l.lectureType == 'twice').toList();
    }

    // ── 2단계: 키워드 검색 (빈 문자열이면 전체 pool 표시)
    var results = nq.isEmpty
        ? pool
        : pool.where((l) =>
            normalize(l.title).contains(nq) ||
            l.hashtags.any((h) => normalize(h).contains(nq)) ||
            normalize(l.instructor).contains(nq) ||
            normalize(l.subject).contains(nq) ||
            normalize(l.description).contains(nq)).toList();

    if (_selectedGrade.isNotEmpty) {
      results = results.where((l) => l.grade == _selectedGrade).toList();
    }
    if (_selectedSubject.isNotEmpty) {
      results = results.where((l) => l.subject == _selectedSubject).toList();
    }
    switch (_sortBy) {
      case '최신순':
        results.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
        break;
      case '평점순':
        results.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case '조회순':
        results.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
    }

    return Column(children: [
      // ── 검색 컨텍스트 배너 (카테고리 진입 시)
      if (_categoryFilter.isNotEmpty) _buildCategoryBanner(nq),
      // ── Asome Tutor 스타일 필터 영역
      _buildGongmansaeFilterBar(),
      // ── 결과 헤더: 총 N개 + 정렬
      _buildResultHeader(results.length),
      // ── 구분선
      Container(height: 1, color: const Color(0xFFEEEEEE)),
      // ── 결과 목록
      Expanded(
        child: results.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: results.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LectureCard(
                    lecture: results[i],
                    onTap: () {
                      appState.addRecentView(results[i].id);
                      // PIP 중인 강의와 동일하면 PIP 종료, 다른 강의면 PIP 유지(A 계속 재생)
                      if (appState.pipActive &&
                          appState.pipLecture?.id == results[i].id) {
                        appState.deactivatePip();
                      }
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => LecturePlayerScreen(
                                    lecture: results[i],
                                    autoPlayList: _autoPlay ? results : null,
                                    autoPlayIndex: _autoPlay ? i : 0,
                                  )));
                    },
                  ),
                ),
              ),
      ),
    ]);
  }

  // ── 카테고리 검색 컨텍스트 배너
  Widget _buildCategoryBanner(String keyword) {
    final Map<String, Color> catColor = {
      '수학': AppColors.math,
      '과학': AppColors.science,
      '두번설명': _kOrange,
    };
    final Map<String, IconData> catIcon = {
      '수학': Icons.calculate_rounded,
      '과학': Icons.science_rounded,
      '두번설명': Icons.replay_rounded,
    };
    final color = catColor[_categoryFilter] ?? _kOrange;
    final icon = catIcon[_categoryFilter] ?? Icons.search_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.15), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          // 과목 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _categoryFilter,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // 검색어 표시
          Expanded(
            child: keyword.isEmpty
                ? Text(
                    '전체 강의',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: color.withValues(alpha: 0.85),
                    ),
                  )
                : RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      children: [
                        const TextSpan(text: '에서  '),
                        TextSpan(
                          text: '\u2018$keyword\u2019',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        const TextSpan(text: '  검색 결과'),
                      ],
                    ),
                  ),
          ),
          // 전체 검색으로 전환 버튼
          GestureDetector(
            onTap: () => setState(() => _categoryFilter = ''),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '전체 범위',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Asome Tutor 스타일 필터바 (학년 + 과목)
  Widget _buildGongmansaeFilterBar() {
    const grades = [
      {'value': '', 'label': '전체'},
      {'value': 'elementary', 'label': '예비중'},
      {'value': 'middle', 'label': '중등'},
      {'value': 'high', 'label': '고등'},
    ];
    const subjects = [
      {'value': '', 'label': '전체'},
      {'value': '수학', 'label': '수학'},
      {'value': '과학', 'label': '과학'},
    ];

    return Container(
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 학년 필터
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: grades.map((g) {
                final isSelected = _selectedGrade == g['value'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedGrade = g['value']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1A2D5A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1A2D5A) : const Color(0xFFDDDDDD),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      g['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF666666),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // 과목 필터
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: subjects.map((s) {
                final isSelected = _selectedSubject == s['value'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedSubject = s['value']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? _kOrange : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? _kOrange : const Color(0xFFDDDDDD),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      s['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF666666),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 총 N개 | 관련순▼ | 자동재생 토글 (Asome Tutor 캡처 그대로)
  Widget _buildResultHeader(int count) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(children: [
        // 총 N개
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            children: [
              const TextSpan(
                  text: '총 ',
                  style: TextStyle(fontWeight: FontWeight.w400)),
              TextSpan(
                  text: '$count',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const TextSpan(
                  text: '개',
                  style: TextStyle(fontWeight: FontWeight.w400)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 정렬 드롭다운
        GestureDetector(
          onTap: _showSortSheet,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_sortBy,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
            const Icon(Icons.arrow_drop_down_rounded,
                size: 18, color: AppColors.textSecondary),
          ]),
        ),
        const Spacer(),
        // 자동재생 토글 (Asome Tutor 스타일)
        Row(children: [
          const Text('자동 재생',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _autoPlay = !_autoPlay),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 22,
              decoration: BoxDecoration(
                color: _autoPlay ? _kOrange : const Color(0xFFCCCCCC),
                borderRadius: BorderRadius.circular(11),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: _autoPlay ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 44, color: _kOrange),
          ),
          const SizedBox(height: 16),
          const Text('검색 결과가 없습니다',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('다른 검색어를 입력해 보세요',
              style:
                  TextStyle(color: AppColors.textHint, fontSize: 13)),
        ],
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('정렬 기준',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    ..._sortOptions.map((opt) => ListTile(
                          title:
                              Text(opt, style: const TextStyle(fontSize: 14)),
                          trailing: _sortBy == opt
                              ? const Icon(Icons.check_rounded,
                                  color: _kOrange)
                              : null,
                          onTap: () {
                            setState(() => _sortBy = opt);
                            Navigator.pop(context);
                          },
                        )),
                  ]),
            ));
  }
}

