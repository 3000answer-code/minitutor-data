import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../services/translations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lecture_card.dart';
import '../lecture/lecture_player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late TabController _tabController;
  bool _isSearching = false;
  String _searchResult = '';
  String _selectedGrade = '';
  String _selectedSubject = '';
  String _sortBy = '관련순';

  final List<String> _grades = ['전체', '초등', '중등', '고등'];
  final List<String> _gradeKeys = ['', 'elementary', 'middle', 'high'];
  final List<String> _subjects = ['전체', '국어', '영어', '수학', '과학', '사회'];
  final List<String> _sortOptions = ['관련순', '최신순', '평점순', '조회순'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    setState(() {
      _searchResult = query;
      _isSearching = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: _controller,
            autofocus: !_isSearching,
            decoration: InputDecoration(
              hintText: T('search_hint2'),
              hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () {
                      _controller.clear();
                      setState(() { _isSearching = false; _searchResult = ''; });
                    })
                  : null,
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textHint),
            ),
            onSubmitted: _search,
            onChanged: (v) => setState(() {}),
            textInputAction: TextInputAction.search,
          ),
        ),
        actions: [
          TextButton(onPressed: () {
            _controller.clear();
            setState(() { _isSearching = false; _searchResult = ''; });
          }, child: Text(T('search_cancel'), style: const TextStyle(color: AppColors.primary))),
        ],
        bottom: _isSearching ? PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ) : null,
      ),
      body: _isSearching ? _buildSearchResults(appState) : _buildSearchHome(appState),
    );
  }

  Widget _buildSearchHome(AppState appState) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildSearchTabs(appState)),
        SliverToBoxAdapter(child: _buildSubjectGrid()),
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  Widget _buildSearchTabs(AppState appState) {
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    return Column(children: [
      TabBar(
        controller: _tabController,
        tabs: [Tab(text: T('search_popular_tab')), Tab(text: T('search_recent_tab'))],
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.divider,
      ),
      SizedBox(
        height: 200,
        child: TabBarView(
          controller: _tabController,
          children: [
            // 인기 검색어
            _buildKeywordList(appState.popularSearches, isPopular: true),
            // 최근 검색어
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(children: [
                  Text(T('search_recent_label'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const Spacer(),
                  TextButton(onPressed: appState.clearRecentSearches,
                    child: Text(T('search_clear_all'), style: const TextStyle(fontSize: 12, color: AppColors.textHint))),
                ]),
              ),
              Expanded(child: _buildKeywordList(appState.recentSearches, isPopular: false)),
            ]),
          ],
        ),
      ),
    ]);
  }

  Widget _buildKeywordList(List<String> keywords, {required bool isPopular}) {
    final lang = context.read<AppState>().selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    if (keywords.isEmpty) {
      return Center(child: Text(T('search_no_history'), style: const TextStyle(color: AppColors.textHint)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: keywords.length.clamp(0, 8),
      separatorBuilder: (_, __) => const Divider(height: 0, indent: 16, endIndent: 16),
      itemBuilder: (_, i) => ListTile(
        dense: true,
        leading: isPopular
            ? Text('${i + 1}', style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800,
                color: i < 3 ? AppColors.primary : AppColors.textSecondary))
            : const Icon(Icons.history_rounded, size: 18, color: AppColors.textHint),
        title: Text(keywords[i], style: const TextStyle(fontSize: 14)),
        trailing: !isPopular ? IconButton(
          icon: const Icon(Icons.close, size: 16, color: AppColors.textHint),
          onPressed: () {},
        ) : null,
        onTap: () {
          _controller.text = keywords[i];
          _search(keywords[i]);
        },
      ),
    );
  }

  Widget _buildSubjectGrid() {
    final lang = context.read<AppState>().selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    final subjects = [
      {'name': '국어', 'color': AppColors.korean, 'icon': '📖'},
      {'name': '영어', 'color': AppColors.english, 'icon': '🌍'},
      {'name': '수학', 'color': AppColors.math, 'icon': '🔢'},
      {'name': '과학', 'color': AppColors.science, 'icon': '🔬'},
      {'name': '사회', 'color': AppColors.social, 'icon': '🏛️'},
      {'name': '기타', 'color': AppColors.other, 'icon': '📚'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(T('search_browse_subject'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.4,
          children: subjects.map((s) => GestureDetector(
            onTap: () {
              _controller.text = s['name'] as String;
              _search(s['name'] as String);
            },
            child: Container(
              decoration: BoxDecoration(
                color: (s['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: (s['color'] as Color).withValues(alpha: 0.3)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(s['icon'] as String, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(s['name'] as String,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: s['color'] as Color)),
              ]),
            ),
          )).toList(),
        ),
      ]),
    );
  }

  Widget _buildSearchResults(AppState appState) {
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    final results = appState.getLecturesBySubject('전체').where((l) =>
      l.title.contains(_searchResult) ||
      l.hashtags.any((h) => h.contains(_searchResult)) ||
      l.instructor.contains(_searchResult) ||
      l.subject.contains(_searchResult)).toList();

    return Column(children: [
      // 필터 영역
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(children: [
          // 학제 필터
          SizedBox(height: 34, child: ListView(scrollDirection: Axis.horizontal, children: [
            ...List.generate(_grades.length, (i) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_grades[i], style: const TextStyle(fontSize: 12)),
                selected: _selectedGrade == _gradeKeys[i],
                onSelected: (_) => setState(() => _selectedGrade = _gradeKeys[i]),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: _selectedGrade == _gradeKeys[i] ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: _selectedGrade == _gradeKeys[i] ? FontWeight.w700 : FontWeight.w400,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
            )),
            const SizedBox(width: 8),
            const VerticalDivider(width: 1, color: AppColors.divider),
            const SizedBox(width: 8),
            // 정렬 팝업
            ActionChip(
              label: Row(children: [
                Text(_sortBy, style: const TextStyle(fontSize: 12)),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 14),
              ]),
              onPressed: () => _showSortSheet(),
              backgroundColor: AppColors.background,
            ),
          ])),
          const SizedBox(height: 8),
          // 과목 필터
          SizedBox(height: 34, child: ListView(scrollDirection: Axis.horizontal, children: [
            ..._subjects.map((s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(s, style: const TextStyle(fontSize: 12)),
                selected: _selectedSubject == (s == '전체' ? '' : s),
                onSelected: (_) => setState(() => _selectedSubject = s == '전체' ? '' : s),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            )),
          ])),
        ]),
      ),
      // 결과 수
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          Text('"$_searchResult"', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          Text(' 검색 결과 ${results.length}개',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ]),
      ),
      // 결과 목록
      Expanded(
        child: results.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.search_off_rounded, size: 60, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text(T('search_no_result2'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                const SizedBox(height: 4),
                Text(T('search_try_other'), style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                itemCount: results.length,
                itemBuilder: (_, i) => LectureCard(
                  lecture: results[i],
                  isHorizontal: true,
                  onTap: () {
                    appState.addRecentView(results[i].id);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => LecturePlayerScreen(lecture: results[i])));
                  },
                ),
              ),
      ),
    ]);
  }

  void _showSortSheet() {
    showModalBottomSheet(context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('정렬 기준', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ..._sortOptions.map((opt) => ListTile(
            title: Text(opt, style: const TextStyle(fontSize: 14)),
            trailing: _sortBy == opt ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
            onTap: () { setState(() => _sortBy = opt); Navigator.pop(context); },
          )),
        ]),
      ));
  }
}
