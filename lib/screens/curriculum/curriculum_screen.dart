import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../services/data_service.dart';
import '../../services/translations.dart';
import '../../theme/app_theme.dart';
import '../../screens/profile/profile_drawer.dart';
import '../lecture/lecture_player_screen.dart';
import '../../widgets/lecture_card.dart';

class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DataService _dataService = DataService();

  // 탭 카테고리 (수학·과학만 서비스)
  final List<String> _categories = ['수학', '과학'];
  final Map<String, List<String>> _subjectsByCategory = {
    '수학': ['수학'],
    '과학': ['과학', '공통과학', '물리', '화학', '생명과학', '지구과학'],
  };

  String? _selectedGrade;
  String? _selectedUnit;
  String _selectedCategory = '수학';
  String _selectedSubject = '수학';

  // 학년 목록 — 예비중(초등 전체)은 학년 구분 없이 하나로 표시
  final List<Map<String, String>> _grades = [
    {'key': 'all', 'label': '모든 학년'},
    {'key': 'elementary', 'label': '예비중'},
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
    '과학': [
      {'id': 'u_sci_1', 'name': '물질의 구성', 'lectureCount': 7, 'grade': '중학교 1학년'},
      {'id': 'u_sci_2', 'name': '힘과 운동', 'lectureCount': 8, 'grade': '중학교 1학년'},
      {'id': 'u_sci_3', 'name': '생물의 구조와 기능', 'lectureCount': 9, 'grade': '중학교 2학년'},
      {'id': 'u_sci_4', 'name': '전기와 자기', 'lectureCount': 8, 'grade': '중학교 2학년'},
      {'id': 'u_sci_5', 'name': '화학 반응', 'lectureCount': 7, 'grade': '중학교 3학년'},
      {'id': 'u_sci_6', 'name': '에너지 전환', 'lectureCount': 6, 'grade': '중학교 3학년'},
    ],
    '공통과학': [
      {'id': 'u_csci_1', 'name': '물질과 규칙성', 'lectureCount': 9, 'grade': '고등학교 1학년'},
      {'id': 'u_csci_2', 'name': '시스템과 상호작용', 'lectureCount': 10, 'grade': '고등학교 1학년'},
      {'id': 'u_csci_3', 'name': '변화와 다양성', 'lectureCount': 8, 'grade': '고등학교 1학년'},
      {'id': 'u_csci_4', 'name': '환경과 에너지', 'lectureCount': 7, 'grade': '고등학교 1학년'},
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
    // '예비중' 선택 시 → grade가 '예비중'으로 시작하는 모든 단원 표시
    if (_selectedGrade == 'elementary') {
      return units.where((u) => (u['grade'] as String).startsWith('예비중')).toList();
    }
    final gradeLabel = _grades.firstWhere(
      (g) => g['key'] == _selectedGrade,
      orElse: () => {'label': ''},
    )['label']!;
    return units.where((u) => u['grade'] == gradeLabel).toList();
  }

  Color _subjectColor(String subject) {
    switch (subject) {
      case '수학': return AppColors.math;
      case '과학': case '공통과학': case '물리': case '화학': case '생명과학': case '지구과학': return AppColors.science;
      default: return AppColors.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);

    return Scaffold(
      backgroundColor: AppColors.background,
      endDrawer: const ProfileDrawer(),
      appBar: AppBar(
        title: Text(T('curriculum_title'), style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
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
          // 과목별 강의 소개 헤더 (탭바 바로 아래)
          _buildSubjectBanner(),
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SizedBox(
        height: 34,
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
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
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
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
      itemCount: units.length,
      itemBuilder: (context, i) {
        final unit = units[i];
        return _buildUnitCard(unit, i);
      },
    );
  }

  /// 과목 선택 칩 바로 아래 — 과목별 소개 배너
  Widget _buildSubjectBanner() {
    const Map<String, Map<String, dynamic>> subjectInfo = {
      '수학': {
        'emoji': '📐',
        'label': '수학 강의',
        'desc': '개념부터 심화까지, 수학 핵심을 정리해 드려요',
        'color': Color(0xFF16A34A),
      },
      '과학': {
        'emoji': '🔬',
        'label': '과학 강의',
        'desc': '중등·고등 과학의 핵심 개념을 한눈에',
        'color': Color(0xFF2563EB),
      },
      '공통과학': {
        'emoji': '🌡️',
        'label': '공통과학 강의',
        'desc': '공통과학 핵심 개념을 빠르게 이해해요',
        'color': Color(0xFF0891B2),
      },
      '물리': {
        'emoji': '⚡',
        'label': '물리 강의',
        'desc': '물리 법칙과 원리를 쉽게 풀어드려요',
        'color': Color(0xFF3B82F6),
      },
      '화학': {
        'emoji': '🧪',
        'label': '화학 강의',
        'desc': '화학 반응과 원소를 핵심만 정리해요',
        'color': Color(0xFFF97316),
      },
      '생명과학': {
        'emoji': '🌿',
        'label': '생명과학 강의',
        'desc': '생명과학의 원리를 개념별로 배워요',
        'color': Color(0xFF10B981),
      },
      '지구과학': {
        'emoji': '🌍',
        'label': '지구과학 강의',
        'desc': '지구와 우주의 신비를 쉽게 이해해요',
        'color': Color(0xFF06B6D4),
      },
    };

    final info = subjectInfo[_selectedSubject] ?? {
      'emoji': '📚',
      'label': '$_selectedSubject 강의',
      'desc': '$_selectedSubject 핵심 강의를 만나보세요',
      'color': const Color(0xFF7C3AED),
    };

    final Color accentColor = info['color'] as Color;
    final String emoji = info['emoji'] as String;
    final String label = info['label'] as String;
    final String desc = info['desc'] as String;

    // 총 강의 수 계산
    final totalLectures = (_unitsBySubject[_selectedSubject] ?? [])
        .fold<int>(0, (sum, u) => sum + ((u['lectureCount'] as int?) ?? 0));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        children: [
          // 이모지 원형 배지
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withValues(alpha: 0.30), width: 1.5),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    )),
                  if (totalLectures > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1),
                      ),
                      child: Text('총 $totalLectures강',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        )),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w400,
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 모든 과목 공통 — 파스텔톤 8가지 색 순환
  // [파스텔 배경색, 텍스트/포인트용 진한색]
  static const List<List<Color>> _universalPalette = [
    [Color(0xFFDCEEFB), Color(0xFF2563A8)], // 1 파스텔 블루
    [Color(0xFFFFE0E3), Color(0xFFA8303E)], // 2 파스텔 로즈
    [Color(0xFFD6F5E8), Color(0xFF1F7A55)], // 3 파스텔 민트
    [Color(0xFFFFEBD6), Color(0xFFA85C20)], // 4 파스텔 피치
    [Color(0xFFEADDF8), Color(0xFF6B3FAD)], // 5 파스텔 라벤더
    [Color(0xFFFFDDEE), Color(0xFFAD3070)], // 6 파스텔 핑크
    [Color(0xFFFFF8CC), Color(0xFF8A7010)], // 7 파스텔 옐로우
    [Color(0xFFCCF2EC), Color(0xFF1A7A72)], // 8 파스텔 틸
  ];

  List<List<Color>> get _cardGradientPalette => _universalPalette;

  Widget _buildUnitCard(Map<String, dynamic> unit, int idx) {
    final gradients = _cardGradientPalette;
    final gradientColors = gradients[idx % gradients.length];

    final bgColor   = gradientColors[0]; // 연한 파스텔 배경
    final textColor  = gradientColors[1]; // 진한 텍스트/포인트

    return GestureDetector(
      onTap: () => _openUnitDetail(unit),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withValues(alpha: 0.18), width: 1),
          boxShadow: [BoxShadow(
            color: textColor.withValues(alpha: 0.10),
            blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── 번호 배지
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: textColor.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Center(
                  child: Text('${idx + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    )),
                ),
              ),
              const SizedBox(width: 12),
              // ── 본문
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 배지 행
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(_selectedSubject,
                          style: TextStyle(
                            fontSize: 10,
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          )),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(unit['grade'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: textColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          )),
                      ),
                    ]),
                    const SizedBox(height: 5),
                    // 단원명
                    Text(unit['name'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.2,
                      )),
                    const SizedBox(height: 4),
                    // 강의 수
                    Row(children: [
                      Icon(Icons.play_circle_outline,
                        size: 12, color: textColor.withValues(alpha: 0.65)),
                      const SizedBox(width: 3),
                      Builder(builder: (ctx) {
                        final l = ctx.read<AppState>().selectedLanguage;
                        final Tk = (String key) => AppTranslations.tLang(l, key);
                        return Text(
                          Tk('lecture_count_unit').replaceAll('{n}', '${unit['lectureCount']}'),
                          style: TextStyle(
                            fontSize: 11,
                            color: textColor.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w600,
                          ));
                      }),
                    ]),
                  ],
                ),
              ),
              // ── 오른쪽 화살표
              Icon(Icons.chevron_right_rounded,
                color: textColor.withValues(alpha: 0.5), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ── 공통 바텀시트 핸들 & 타이틀 ───────────────────
  Widget _sheetHandle() => Center(
        child: Container(
          width: 36, height: 4,
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDDE1E7),
            borderRadius: BorderRadius.circular(2)),
        ),
      );

  Widget _sheetTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Text(text,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E))),
      );

  // ── 학년 선택 ─────────────────────────────────────
  void _showGradePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final lang = ctx.read<AppState>().selectedLanguage;
        return SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _sheetHandle(),
            _sheetTitle(AppTranslations.tLang(lang, 'select_grade')),
            const Divider(height: 1, color: Color(0xFFF0F1F3)),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _grades.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1, indent: 20, endIndent: 20,
                  color: Color(0xFFF0F1F3)),
              itemBuilder: (_, i) {
                final g = _grades[i];
                final selected = _selectedGrade == g['key'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedGrade = g['key'];
                      _selectedUnit = null;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(children: [
                      Expanded(
                        child: Text(g['label']!,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: selected
                                    ? AppColors.primary
                                    : const Color(0xFF3A3A4A))),
                      ),
                      if (selected)
                        Icon(Icons.check_rounded,
                            size: 18, color: AppColors.primary),
                    ]),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ]),
        );
      },
    );
  }

  // ── 단원 선택 ─────────────────────────────────────
  void _showUnitPicker() {
    final gradeLabel = _grades.firstWhere(
        (g) => g['key'] == _selectedGrade,
        orElse: () => {'label': ''})['label']!;
    final units = (_unitsBySubject[_selectedSubject] ?? [])
        .where((u) => _selectedGrade == 'all' || u['grade'] == gradeLabel)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final lang = ctx.read<AppState>().selectedLanguage;
        return SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _sheetHandle(),
            _sheetTitle(AppTranslations.tLang(lang, 'select_unit')),
            const Divider(height: 1, color: Color(0xFFF0F1F3)),
            if (units.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                    AppTranslations.tLang(lang, 'no_unit_for_grade'),
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 14)),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.of(context).size.height * 0.55),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: units.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, indent: 20, endIndent: 20,
                      color: Color(0xFFF0F1F3)),
                  itemBuilder: (_, i) {
                    final u = units[i];
                    final selected = _selectedUnit == u['name'];
                    final count = u['lectureCount'] as int;
                    return InkWell(
                      onTap: () {
                        setState(() =>
                            _selectedUnit = u['name'] as String);
                        Navigator.pop(context);
                      },
                      child: Container(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 11),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(u['name'] as String,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: selected
                                              ? AppColors.primary
                                              : const Color(0xFF3A3A4A))),
                                  const SizedBox(height: 2),
                                  Text(
                                      AppTranslations.tLang(lang,
                                              'lecture_count_unit')
                                          .replaceAll('{n}', '$count'),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textHint)),
                                ]),
                          ),
                          if (selected)
                            Icon(Icons.check_rounded,
                                size: 18, color: AppColors.primary),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ]),
        );
      },
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

  // 과목별 그래디언트 색상 쌍
  List<Color> get _gradientColors {
    switch (widget.subject) {
      case '수학':
        return [const Color(0xFF1565C0), const Color(0xFF42A5F5)]; // 딥블루→스카이블루
      case '과학':
        return [const Color(0xFF00695C), const Color(0xFF26C6A0)]; // 딥틸→민트
      case '공통과학':
        return [const Color(0xFF1B5E20), const Color(0xFF66BB6A)]; // 딥그린→라이트그린
      case '물리':
        return [const Color(0xFF4A148C), const Color(0xFFAB47BC)]; // 딥퍼플→라일락
      case '화학':
        return [const Color(0xFFB71C1C), const Color(0xFFEF5350)]; // 딥레드→코랄
      case '생명과학':
        return [const Color(0xFF1B5E20), const Color(0xFF43A047)]; // 포레스트→그린
      case '지구과학':
        return [const Color(0xFF0D47A1), const Color(0xFF1E88E5)]; // 네이비→블루
      default:
        return [const Color(0xFF37474F), const Color(0xFF78909C)]; // 슬레이트
    }
  }

  // 과목별 아이콘
  IconData get _subjectIcon {
    switch (widget.subject) {
      case '수학':       return Icons.functions_rounded;
      case '과학':       return Icons.science_outlined;
      case '공통과학':   return Icons.biotech_outlined;
      case '물리':       return Icons.electric_bolt_rounded;
      case '화학':       return Icons.colorize_rounded;
      case '생명과학':   return Icons.eco_rounded;
      case '지구과학':   return Icons.public_rounded;
      default:           return Icons.school_rounded;
    }
  }

  Color get _color => _gradientColors[0];

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
            expandedHeight: 160,
            pinned: true,
            backgroundColor: _gradientColors[0],
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(children: [
                // ── 그래디언트 배경 ──────────────────────
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // ── 장식 원형 (우상단) ───────────────────
                Positioned(
                  top: -30, right: -20,
                  child: Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),
                Positioned(
                  top: 30, right: 30,
                  child: Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                // ── 과목 대형 아이콘 (우하단 장식) ───────
                Positioned(
                  bottom: -10, right: 16,
                  child: Icon(
                    _subjectIcon,
                    size: 100,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                // ── 콘텐츠 ──────────────────────────────
                Positioned(
                  left: 20, right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(_subjectIcon,
                                size: 11,
                                color: Colors.white.withValues(alpha: 0.9)),
                            const SizedBox(width: 4),
                            Text(widget.subject,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3)),
                          ]),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Text(widget.unit['grade'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2)),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Text(widget.unit['name'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              height: 1.2)),
                    ],
                  ),
                ),
              ]),
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
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => LecturePlayerScreen(
                        lecture: lec,
                        autoPlayList: _autoPlay ? lectures : null,
                        autoPlayIndex: _autoPlay ? i : 0,
                      ),
                    )),
                    child: Stack(
                      children: [
                        LectureCard(lecture: lec),
                        // 번호 배지 오버레이
                        Positioned(
                          top: 8, left: 8,
                          child: Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: _color,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(
                                color: _color.withValues(alpha: 0.4),
                                blurRadius: 4, offset: const Offset(0, 1),
                              )],
                            ),
                            child: Center(
                              child: Text('${i + 1}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
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
