import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../services/data_service.dart';
import '../../services/translations.dart';
import '../../theme/app_theme.dart';
import '../lecture/lecture_player_screen.dart';

class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DataService _dataService = DataService();

  // 탭 카테고리
  final List<String> _categories = ['국영수', '과학', '사회', '기타과목'];
  final Map<String, List<String>> _subjectsByCategory = {
    '국영수': ['국어', '영어', '수학'],
    '과학': ['물리', '화학', '생명과학', '지구과학'],
    '사회': ['사회', '역사', '지리', '도덕'],
    '기타과목': ['음악', '미술', '체육', '정보'],
  };

  String? _selectedGrade;
  String? _selectedUnit;
  String _selectedCategory = '국영수';
  String _selectedSubject = '수학';

  // 학년 목록
  final List<Map<String, String>> _grades = [
    {'key': 'all', 'label': '모든 학년'},
    {'key': 'elem1', 'label': '초등 1학년'}, {'key': 'elem2', 'label': '초등 2학년'},
    {'key': 'elem3', 'label': '초등 3학년'}, {'key': 'elem4', 'label': '초등 4학년'},
    {'key': 'elem5', 'label': '초등 5학년'}, {'key': 'elem6', 'label': '초등 6학년'},
    {'key': 'mid1', 'label': '중학교 1학년'}, {'key': 'mid2', 'label': '중학교 2학년'},
    {'key': 'mid3', 'label': '중학교 3학년'},
    {'key': 'high1', 'label': '고등학교 1학년'}, {'key': 'high2', 'label': '고등학교 2학년'},
    {'key': 'high3', 'label': '고등학교 3학년'},
  ];

  // 과목별 단원 목록
  Map<String, List<Map<String, dynamic>>> get _unitsBySubject => {
    '수학': [
      {'id': 'u_math_1', 'name': '수와 연산', 'lectureCount': 8, 'grade': '중학교 1학년'},
      {'id': 'u_math_2', 'name': '방정식과 부등식', 'lectureCount': 12, 'grade': '중학교 2학년'},
      {'id': 'u_math_3', 'name': '함수', 'lectureCount': 10, 'grade': '중학교 2학년'},
      {'id': 'u_math_4', 'name': '이차방정식', 'lectureCount': 9, 'grade': '중학교 3학년'},
      {'id': 'u_math_5', 'name': '피타고라스 정리', 'lectureCount': 6, 'grade': '중학교 3학년'},
      {'id': 'u_math_6', 'name': '삼각함수', 'lectureCount': 11, 'grade': '고등학교 1학년'},
      {'id': 'u_math_7', 'name': '수열과 극한', 'lectureCount': 14, 'grade': '고등학교 2학년'},
      {'id': 'u_math_8', 'name': '적분', 'lectureCount': 13, 'grade': '고등학교 2학년'},
    ],
    '국어': [
      {'id': 'u_kor_1', 'name': '소설의 이해', 'lectureCount': 7, 'grade': '중학교 1학년'},
      {'id': 'u_kor_2', 'name': '시의 표현기법', 'lectureCount': 6, 'grade': '중학교 2학년'},
      {'id': 'u_kor_3', 'name': '논설문 쓰기', 'lectureCount': 8, 'grade': '중학교 3학년'},
      {'id': 'u_kor_4', 'name': '고전문학의 이해', 'lectureCount': 10, 'grade': '고등학교 1학년'},
      {'id': 'u_kor_5', 'name': '현대문학과 사회', 'lectureCount': 9, 'grade': '고등학교 2학년'},
    ],
    '영어': [
      {'id': 'u_eng_1', 'name': '기초 문법', 'lectureCount': 10, 'grade': '중학교 1학년'},
      {'id': 'u_eng_2', 'name': '현재완료 vs 과거', 'lectureCount': 6, 'grade': '중학교 2학년'},
      {'id': 'u_eng_3', 'name': '관계대명사', 'lectureCount': 7, 'grade': '중학교 3학년'},
      {'id': 'u_eng_4', 'name': '가정법', 'lectureCount': 8, 'grade': '고등학교 1학년'},
      {'id': 'u_eng_5', 'name': '독해 전략', 'lectureCount': 12, 'grade': '고등학교 2학년'},
    ],
    '물리': [
      {'id': 'u_phy_1', 'name': '역학의 기초', 'lectureCount': 9, 'grade': '고등학교 1학년'},
      {'id': 'u_phy_2', 'name': '전기와 자기', 'lectureCount': 11, 'grade': '고등학교 2학년'},
    ],
    '화학': [
      {'id': 'u_chem_1', 'name': '원소와 주기율표', 'lectureCount': 8, 'grade': '고등학교 1학년'},
      {'id': 'u_chem_2', 'name': '화학 반응', 'lectureCount': 10, 'grade': '고등학교 2학년'},
    ],
    '생명과학': [
      {'id': 'u_bio_1', 'name': '세포와 생명', 'lectureCount': 7, 'grade': '고등학교 1학년'},
      {'id': 'u_bio_2', 'name': '유전과 진화', 'lectureCount': 9, 'grade': '고등학교 2학년'},
    ],
    '지구과학': [
      {'id': 'u_earth_1', 'name': '지구의 구조', 'lectureCount': 6, 'grade': '중학교 2학년'},
      {'id': 'u_earth_2', 'name': '기상과 기후', 'lectureCount': 8, 'grade': '중학교 3학년'},
    ],
    '사회': [
      {'id': 'u_soc_1', 'name': '민주주의와 정치', 'lectureCount': 8, 'grade': '중학교 1학년'},
      {'id': 'u_soc_2', 'name': '시장경제의 이해', 'lectureCount': 7, 'grade': '중학교 2학년'},
    ],
    '역사': [
      {'id': 'u_his_1', 'name': '한국사 근대', 'lectureCount': 12, 'grade': '중학교 2학년'},
      {'id': 'u_his_2', 'name': '세계사 현대', 'lectureCount': 10, 'grade': '고등학교 1학년'},
    ],
    '지리': [
      {'id': 'u_geo_1', 'name': '세계 지리', 'lectureCount': 8, 'grade': '중학교 1학년'},
    ],
    '도덕': [
      {'id': 'u_mor_1', 'name': '인성과 도덕', 'lectureCount': 6, 'grade': '중학교 1학년'},
    ],
    '음악': [
      {'id': 'u_mus_1', 'name': '음악 이론 기초', 'lectureCount': 5, 'grade': '중학교 1학년'},
    ],
    '미술': [
      {'id': 'u_art_1', 'name': '미술사 이해', 'lectureCount': 5, 'grade': '중학교 2학년'},
    ],
    '체육': [
      {'id': 'u_pe_1', 'name': '스포츠 이론', 'lectureCount': 4, 'grade': '중학교 1학년'},
    ],
    '정보': [
      {'id': 'u_info_1', 'name': '코딩 기초', 'lectureCount': 8, 'grade': '중학교 1학년'},
      {'id': 'u_info_2', 'name': '알고리즘', 'lectureCount': 10, 'grade': '고등학교 1학년'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = _categories[_tabController.index];
          _selectedSubject = _subjectsByCategory[_selectedCategory]!.first;
          _selectedGrade = null;
          _selectedUnit = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredUnits {
    final units = _unitsBySubject[_selectedSubject] ?? [];
    if (_selectedGrade == null || _selectedGrade == 'all') return units;
    final gradeLabel = _grades.firstWhere(
      (g) => g['key'] == _selectedGrade,
      orElse: () => {'label': ''},
    )['label']!;
    return units.where((u) => u['grade'] == gradeLabel).toList();
  }

  Color _subjectColor(String subject) {
    switch (subject) {
      case '국어': return AppColors.korean;
      case '영어': return AppColors.english;
      case '수학': return AppColors.math;
      case '물리': case '화학': case '생명과학': case '지구과학': return AppColors.science;
      case '사회': case '역사': case '지리': case '도덕': return AppColors.social;
      default: return AppColors.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(T('curriculum_title'), style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _categories.map((c) => Tab(text: c)).toList(),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          dividerColor: AppColors.divider,
        ),
      ),
      body: Column(
        children: [
          // 과목 선택 가로 스크롤
          _buildSubjectSelector(),
          // 학년 / 단원 필터
          _buildFilterRow(),
          const Divider(height: 1),
          // 단원 목록
          Expanded(child: _buildUnitList()),
        ],
      ),
    );
  }

  Widget _buildSubjectSelector() {
    final subjects = _subjectsByCategory[_selectedCategory] ?? [];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: subjects.map((s) {
            final isSelected = _selectedSubject == s;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedSubject = s;
                  _selectedGrade = null;
                  _selectedUnit = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? _subjectColor(s) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    )),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    final lang = context.read<AppState>().selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    final gradeLabel = _selectedGrade == null || _selectedGrade == 'all'
        ? T('select_grade')
        : _grades.firstWhere((g) => g['key'] == _selectedGrade,
            orElse: () => {'label': T('select_grade')})['label']!;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          // 학년 선택 버튼
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showGradePicker(),
              icon: const Icon(Icons.school_outlined, size: 16),
              label: Text(gradeLabel, style: const TextStyle(fontSize: 13)),

              style: OutlinedButton.styleFrom(
                foregroundColor: _selectedGrade != null && _selectedGrade != 'all'
                    ? AppColors.primary : AppColors.textSecondary,
                side: BorderSide(
                  color: _selectedGrade != null && _selectedGrade != 'all'
                      ? AppColors.primary : AppColors.divider,
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 단원 선택 버튼
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                if (_selectedGrade == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(T('select_grade_first')), duration: const Duration(seconds: 2)));
                  return;
                }
                _showUnitPicker();
              },
              icon: const Icon(Icons.menu_book_outlined, size: 16),
              label: Text(_selectedUnit ?? T('select_unit'), style: const TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _selectedUnit != null
                    ? AppColors.primary : AppColors.textSecondary,
                side: BorderSide(
                  color: _selectedUnit != null ? AppColors.primary : AppColors.divider,
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 초기화
          IconButton(
            onPressed: () => setState(() { _selectedGrade = null; _selectedUnit = null; }),
            icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textHint),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitList() {
    final units = _filteredUnits;
    if (units.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.menu_book_rounded, size: 64, color: AppColors.divider),
          const SizedBox(height: 12),
          Builder(builder: (ctx) {
            final lang2 = ctx.read<AppState>().selectedLanguage;
            final T2 = (String key) => AppTranslations.tLang(lang2, key);
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Text(T2('no_unit_for_filter'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() { _selectedGrade = null; _selectedUnit = null; }),
                child: Text(T2('reset_filter')),
              ),
            ]);
          }),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: units.length,
      itemBuilder: (context, i) {
        final unit = units[i];
        return _buildUnitCard(unit);
      },
    );
  }

  Widget _buildUnitCard(Map<String, dynamic> unit) {
    final color = _subjectColor(_selectedSubject);
    return GestureDetector(
      onTap: () => _openUnitDetail(unit),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // 색상 바
          Container(width: 4, height: 56,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6)),
                child: Text(_selectedSubject,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(6)),
                child: Text(unit['grade'] as String,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(unit['name'] as String,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.play_circle_outline, size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
              Builder(builder: (ctx) {
                final l = ctx.read<AppState>().selectedLanguage;
                final Tk = (String key) => AppTranslations.tLang(l, key);
                return Text(Tk('lecture_count_unit').replaceAll('{n}', '${unit['lectureCount']}'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary));
              }),
            ]),
          ])),
          Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        ]),
      ),
    );
  }

  void _showGradePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Builder(builder: (ctx) {
            final l = ctx.read<AppState>().selectedLanguage;
            return Text(AppTranslations.tLang(l, 'select_grade'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800));
          }),
          const SizedBox(height: 16),
          SizedBox(
            height: 320,
            child: ListView(
              children: _grades.map((g) => ListTile(
                title: Text(g['label']!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _selectedGrade == g['key'] ? FontWeight.w700 : FontWeight.w400,
                    color: _selectedGrade == g['key'] ? AppColors.primary : AppColors.textPrimary,
                  )),
                trailing: _selectedGrade == g['key']
                    ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () {
                  setState(() {
                    _selectedGrade = g['key'];
                    _selectedUnit = null;
                  });
                  Navigator.pop(context);
                },
              )).toList(),
            ),
          ),
        ]),
      ),
    );
  }

  void _showUnitPicker() {
    final gradeLabel = _grades.firstWhere((g) => g['key'] == _selectedGrade,
      orElse: () => {'label': ''})['label']!;
    final units = (_unitsBySubject[_selectedSubject] ?? [])
        .where((u) => _selectedGrade == 'all' || u['grade'] == gradeLabel)
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Builder(builder: (ctx) {
            final l = ctx.read<AppState>().selectedLanguage;
            return Text(AppTranslations.tLang(l, 'select_unit'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800));
          }),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: units.isEmpty
                ? Center(child: Builder(builder: (ctx) {
                    final l = ctx.read<AppState>().selectedLanguage;
                    return Text(AppTranslations.tLang(l, 'no_unit_for_grade'));
                  }))
                : ListView(
                    children: units.map((u) => ListTile(
                      title: Text(u['name'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: _selectedUnit == u['name'] ? FontWeight.w700 : FontWeight.w400,
                          color: _selectedUnit == u['name'] ? AppColors.primary : AppColors.textPrimary,
                        )),
                      subtitle: Builder(builder: (ctx) {
                        final l = ctx.read<AppState>().selectedLanguage;
                        return Text(AppTranslations.tLang(l, 'lecture_count_unit').replaceAll('{n}', '${u['lectureCount']}'));
                      }),
                      trailing: _selectedUnit == u['name']
                          ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                      onTap: () {
                        setState(() => _selectedUnit = u['name'] as String);
                        Navigator.pop(context);
                      },
                    )).toList(),
                  ),
          ),
        ]),
      ),
    );
  }

  void _openUnitDetail(Map<String, dynamic> unit) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _UnitDetailScreen(
        unit: unit,
        subject: _selectedSubject,
        dataService: _dataService,
      ),
    ));
  }
}

// ─── 단원 상세 화면 ─────────────────────────────────────
class _UnitDetailScreen extends StatefulWidget {
  final Map<String, dynamic> unit;
  final String subject;
  final DataService dataService;

  const _UnitDetailScreen({
    required this.unit,
    required this.subject,
    required this.dataService,
  });

  @override
  State<_UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends State<_UnitDetailScreen> {
  bool _autoPlay = false;

  Color get _color {
    switch (widget.subject) {
      case '국어': return AppColors.korean;
      case '영어': return AppColors.english;
      case '수학': return AppColors.math;
      case '물리': case '화학': case '생명과학': case '지구과학': return AppColors.science;
      case '사회': case '역사': case '지리': case '도덕': return AppColors.social;
      default: return AppColors.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lectures = widget.dataService.getAllLectures()
        .where((l) => l.subject == widget.subject)
        .take(widget.unit['lectureCount'] as int)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // 헤더
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: _color,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_color, _color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8)),
                      child: Text(widget.subject,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8)),
                      child: Text(widget.unit['grade'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(widget.unit['name'] as String,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                ]),
              ),
            ),
          ),
          // 강의 수 + 자동재생 토글
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Icon(Icons.play_circle_outline, size: 18, color: _color),
                const SizedBox(width: 6),
                Text('총 ${lectures.length}개 강의',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                const Text('자동 재생', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                Switch(
                  value: _autoPlay,
                  onChanged: (v) => setState(() => _autoPlay = v),
                  activeColor: _color,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          // 강의 리스트
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final lec = lectures[i];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => LecturePlayerScreen(lecture: lec),
                  )),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Row(children: [
                      // 번호
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: _color.withValues(alpha: 0.1),
                          shape: BoxShape.circle),
                        child: Center(
                          child: Text('${i + 1}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _color)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 썸네일
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          lec.thumbnailUrl,
                          width: 72, height: 48, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 72, height: 48,
                            color: _color.withValues(alpha: 0.2),
                            child: Icon(Icons.play_arrow, color: _color)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 정보
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(lec.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(children: [
                          Text(lec.instructor,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(width: 8),
                          Icon(Icons.star_rounded, size: 12, color: Colors.amber[600]),
                          Text(' ${lec.rating}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ]),
                      ])),
                      Icon(Icons.play_circle_filled_rounded, color: _color, size: 28),
                    ]),
                  ),
                );
              },
              childCount: lectures.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }
}
