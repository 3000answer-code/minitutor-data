import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/app_state.dart';
import '../../services/translations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lecture_card.dart';
import '../lecture/lecture_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _tabs = ['추천', '인기', '수학', '과학', '두번설명'];
  final _tabKeys = ['recommend', 'popular', '수학', '과학', '두번설명'];
  int _bannerIndex = 0;
  final PageController _bannerController = PageController(viewportFraction: 1.0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<AppState>().setHomeTab(_tabKeys[_tabController.index]);
      }
    });
    // 앱 시작 시 API 강의 강제 새로고침
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshApiLectures();
    });
    Future.delayed(const Duration(seconds: 4), _autoSlide);
  }

  void _autoSlide() {
    if (!mounted) return;
    final next = (_bannerIndex + 1) % 5;
    _bannerController.animateToPage(next,
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    Future.delayed(const Duration(seconds: 4), _autoSlide);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    // 탭 이름 언어 갱신
    _tabs = [
      T('tab_recommend'), T('tab_popular'),
      T('tab_math'), T('tab_science'), T('tab_twice'),
    ];
    // Scaffold 없음 — MainShell의 Scaffold가 AppBar+endDrawer 담당
    return Column(
      children: [
        // 탭바만 표시 (AppBar는 MainShell에서 처리)
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            tabs: _tabs.map((t) => Tab(
              child: Text(
                t,
                style: const TextStyle(fontSize: 13),
              ),
            )).toList(),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            dividerColor: AppColors.divider,
            labelPadding: EdgeInsets.zero,
          ),
        ),
        // 콘텐츠
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _tabKeys.map((key) => _buildTabContent(key)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(String tab) {
    final appState = context.watch<AppState>();
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);

    // 과학/두번설명 탭은 전용 UI 반환
    if (tab == '과학') {
      return Container(
        color: AppColors.background,
        child: SingleChildScrollView(
          child: Column(children: [
            _buildScienceTab(lang),
            const SizedBox(height: 80),
          ]),
        ),
      );
    }
    if (tab == '두번설명') {
      return Container(
        color: AppColors.background,
        child: SingleChildScrollView(
          child: Column(children: [
            _buildTwiceTab(lang),
            const SizedBox(height: 80),
          ]),
        ),
      );
    }

    final allLecs = appState.allLectures;
    final apiLectures = appState.apiLectures;
    final recommendedLecs = apiLectures.isNotEmpty
        ? apiLectures
        : appState.recommendedLectures;
    final popularLecs = appState.popularLectures;
    final ytLectures = allLecs.where((l) => l.videoUrl.contains('youtube') || l.videoUrl.contains('youtu.be')).toList();

    final lectures = tab == 'recommend'
        ? recommendedLecs
        : tab == 'popular'
            ? popularLecs
            : appState.getLecturesBySubject(tab);

    return Container(
      color: AppColors.background,
      child: CustomScrollView(
        slivers: [
          if (tab == 'recommend' || tab == 'popular') ...[
            SliverToBoxAdapter(child: _buildBanner()),
            SliverToBoxAdapter(child: _buildMathScienceCards()),
            SliverToBoxAdapter(child: _buildStudyStats(appState)),
          ],

          // ── 강의 목록 섹션 헤더 (추천: NEW 강의 목록 / 인기: HOT 인기 강의) ──
          if (tab == 'recommend' || tab == 'popular')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(children: [
                  if (tab == 'recommend') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2ECC71), Color(0xFF27AE60)]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    const Text('강의 목록',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFE74C3C), Color(0xFFC0392B)]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('HOT', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    const Text('🔥 인기 강의',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ],
                  const Spacer(),
                  Text('총 ${allLecs.length}개',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ),
            ),

          // ── 강의 세로 리스트 (추천/인기 동일 내용, 어드민에서 조절) ──
          if (tab == 'recommend' || tab == 'popular')
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final lec = allLecs[i];
                    return _LectureListCard(
                      lecture: lec,
                      onTap: () => _openLecture(lec),
                      thumbnailWidget: _buildYtThumbnail(lec, 110, 76),
                      isPopular: tab == 'popular',
                    );
                  },
                  childCount: allLecs.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => LectureCard(
                    lecture: lectures[i],
                    isHorizontal: true,
                    onTap: () => _openLecture(lectures[i]),
                  ),
                  childCount: lectures.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  /// YouTube 썸네일 빌더 (다양한 URL 포맷 시도)
  Widget _buildYtThumbnail(dynamic lec, double width, double height) {
    // YouTube ID 추출
    final videoUrl = lec.videoUrl as String;
    String? ytId;
    final regexps = [
      RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
    ];
    for (final re in regexps) {
      final m = re.firstMatch(videoUrl);
      if (m != null) { ytId = m.group(1); break; }
    }

    // 썸네일 URL 목록 (우선순위 순)
    final thumbUrls = <String>[];
    if (ytId != null) {
      thumbUrls.addAll([
        'https://i.ytimg.com/vi/$ytId/hqdefault.jpg',
        'https://i.ytimg.com/vi/$ytId/mqdefault.jpg',
        'https://i.ytimg.com/vi/$ytId/sddefault.jpg',
        'https://i.ytimg.com/vi/$ytId/default.jpg',
      ]);
    }
    if (lec.thumbnailUrl != null && (lec.thumbnailUrl as String).isNotEmpty) {
      thumbUrls.add(lec.thumbnailUrl as String);
    }

    if (thumbUrls.isEmpty) {
      return _thumbFallback(width, height, lec.subject as String);
    }

    return _ThumbWithFallback(
      urls: thumbUrls,
      width: width,
      height: height,
      subject: lec.subject as String,
    );
  }

  Widget _thumbFallback(double width, double height, String subject) {
    Color c;
    switch (subject) {
      case '수학': c = AppColors.math; break;
      case '영어': c = AppColors.english; break;
      case '국어': c = AppColors.korean; break;
      default: c = AppColors.other;
    }
    return Container(
      width: width, height: height,
      color: c.withValues(alpha: 0.2),
      child: Icon(Icons.play_circle_outline, size: 36, color: c),
    );
  }


  // ══════════════════════════════════════════
  // 과학 탭 전용 UI
  // ══════════════════════════════════════════
  Widget _buildScienceTab(String lang) {
    final appState = context.watch<AppState>();
    final allLecs = appState.allLectures;

    // 과학 관련 강의 수 계산
    int scienceLecCount(String sub) =>
        allLecs.where((l) => l.subject.contains(sub) || l.description.contains(sub)).length;

    final categories = [
      {'title': '과학', 'sub': '중등 과학', 'icon': '🔬', 'color': const Color(0xFF5E35B1), 'count': scienceLecCount('과학'), 'image': 'assets/images/subjects/science_card.jpg'},
      {'title': '공통과학', 'sub': '고등 공통과학', 'icon': '🧪', 'color': const Color(0xFF1976D2), 'count': scienceLecCount('공통과학'), 'image': 'assets/images/subjects/common_science_card.jpg'},
      {'title': '물리', 'sub': '고등 물리학', 'icon': '⚡', 'color': const Color(0xFF1565C0), 'count': scienceLecCount('물리'), 'image': 'assets/images/subjects/physics_card.jpg'},
      {'title': '화학', 'sub': '고등 화학', 'icon': '🧬', 'color': const Color(0xFFE65100), 'count': scienceLecCount('화학'), 'image': 'assets/images/subjects/chemistry_card.jpg'},
      {'title': '생명과학', 'sub': '고등 생명과학', 'icon': '🌿', 'color': const Color(0xFF2E7D32), 'count': scienceLecCount('생명과학'), 'image': 'assets/images/subjects/biology_card.jpg'},
      {'title': '지구과학', 'sub': '고등 지구과학', 'icon': '🌍', 'color': const Color(0xFF00838F), 'count': scienceLecCount('지구과학'), 'image': 'assets/images/subjects/earth_card.jpg'},
    ];

    final totalCount = allLecs.where((l) =>
        l.subject.contains('과학') || l.subject.contains('물리') ||
        l.subject.contains('화학') || l.subject.contains('생명') ||
        l.subject.contains('지구')).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 섹션 헤더
        Row(children: [
          const Text('🔬', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          const Text('과학 강의',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const Spacer(),
          Text('총 ${totalCount > 0 ? totalCount : 11}개',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 12),

        // 보라색 헤더 카드
        Container(
          width: double.infinity,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: AssetImage('assets/images/banners/banner_science_new.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Color(0x886A1B9A), BlendMode.multiply),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(children: [
            const Text('🔬', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('과학',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('중등 · 고등 세분화  |  총 ${totalCount > 0 ? totalCount : 11}개',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              ),
              child: const Text('과목 선택 →',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ]),
          ),
        ),
        const SizedBox(height: 16),

        // 카테고리 그리드 2열
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7,
          ),
          itemCount: categories.length,
          itemBuilder: (context, idx) {
            final cat = categories[idx];
            final Color catColor = cat['color'] as Color;
            final int count = cat['count'] as int;
            final String? catImage = cat['image'] as String?;
            return GestureDetector(
              onTap: () {
                // 해당 과목 강의 목록으로 이동 가능
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: catColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                  image: catImage != null
                      ? DecorationImage(
                          image: AssetImage(catImage),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            catColor.withValues(alpha: 0.5),
                            BlendMode.multiply,
                          ),
                        )
                      : null,
                  gradient: catImage == null
                      ? LinearGradient(
                          colors: [catColor, catColor.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: Stack(children: [
                  // 배경 원
                  Positioned(
                    right: -10,
                    top: -10,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  // 강의 수 배지
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${count}강',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  // 텍스트
                  Positioned(
                    left: 12,
                    bottom: 10,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(cat['icon'] as String, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 2),
                      Text(cat['title'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                      Text(cat['sub'] as String,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10)),
                    ]),
                  ),
                ]),
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        // 과학 학습 가이드
        Row(children: [
          const Text('📚', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          const Text('과학 학습 가이드',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📋 추천 학습 순서',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            _buildGuideStep('1단계', '과학 (중등)', '기초 개념 → 탐구 원리 정립', const Color(0xFF7C4DFF)),
            _buildGuideStep('2단계', '물리 / 화학', '고등 핵심 과목 집중 학습', const Color(0xFF2196F3)),
            _buildGuideStep('3단계', '생명과학 / 지구과학', '심화 개념 + 수능 대비', const Color(0xFF4CAF50)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildGuideStep(String step, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(step, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════
  // 두번설명 탭 전용 UI
  // ══════════════════════════════════════════
  Widget _buildTwiceTab(String lang) {
    final appState = context.watch<AppState>();
    final allLecs = appState.allLectures;
    final apiLecs = appState.apiLectures;

    // 두번설명 태그가 있는 강의 우선, 없으면 전체
    final twiceLecs = allLecs.where((l) =>
        l.hashtags.any((t) => t.contains('두번') || t.contains('twice')) ||
        l.description.contains('두번') || l.title.contains('두번')).toList();
    final displayLecs = twiceLecs.isNotEmpty ? twiceLecs : (apiLecs.isNotEmpty ? apiLecs : allLecs);
    final totalCount = displayLecs.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 상단 배너 카드 (두번설명 이미지 배경)
        Container(
          width: double.infinity,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            image: const DecorationImage(
              image: AssetImage('assets/images/banners/banner_twice_new2.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Color(0x884E342E), BlendMode.multiply),
            ),
          ),
          child: Stack(children: [
            // 배경 원
            Positioned(
              right: -15,
              top: -15,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            // 번개 아이콘 배지
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: const Center(child: Text('⚡', style: TextStyle(fontSize: 18))),
              ),
            ),
            // 텍스트
            Positioned(
              left: 64,
              top: 14,
              right: 120,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('두번설명',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('핵심을 두 번 설명하는 강의',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
              ]),
            ),
            // 총 개수 + 전체보기 버튼
            Positioned(
              right: 16,
              top: 14,
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('총 ${totalCount > 0 ? totalCount : 10}개',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  child: const Text('전체보기 →',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // 강의 리스트
        if (displayLecs.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('강의를 불러오는 중...', style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ...displayLecs.take(10).map((lec) {
            final subjectColor = lec.subject == '수학'
                ? AppColors.math
                : lec.subject == '과학' || lec.subject == '물리' ||
                      lec.subject == '화학' || lec.subject == '생명과학' ||
                      lec.subject == '지구과학'
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFF059669);
            return GestureDetector(
            onTap: () => _openLecture(lec),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단: 썸네일 + 기본 정보
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      // 썸네일
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildYtThumbnail(lec, 110, 76),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          // 태그들
                          Row(children: [
                            _miniTag(lec.grade.isNotEmpty ? lec.gradeText : '전체', AppColors.accent),
                            const SizedBox(width: 4),
                            _miniTag(lec.subject.isNotEmpty ? lec.subject : '수학', subjectColor),
                          ]),
                          const SizedBox(height: 6),
                          // 제목
                          Text(lec.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          // 강사
                          Row(children: [
                            const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(lec.instructor,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: subjectColor.withValues(alpha: 0.12),
                              ),
                              child: Icon(Icons.play_arrow_rounded, color: subjectColor, size: 18),
                            ),
                          ]),
                        ]),
                      ),
                    ]),
                  ),
                  // 해시태그 2줄 가로스크롤
                  if ((lec.hashtags as List).isNotEmpty)
                    Container(
                      height: 56,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildHashtagRows(
                            (lec.hashtags as List).cast<String>(),
                            subjectColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );}).toList(),
      ]),
    );
  }

  Widget _miniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
    );
  }

  /// 해시태그 목록을 2줄로 나눠서 Row 위젯 리스트로 반환
  /// 4~5개씩 두 줄로 나누며, 초과분은 가로 스크롤로 처리
  List<Widget> _buildHashtagRows(List<String> tags, Color color) {
    if (tags.isEmpty) return [];
    Widget _tagChip(String tag) => Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.20), width: 0.8),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 10,
          color: color.withValues(alpha: 0.9),
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    // 홀수 인덱스(0,2,4...) → 1행, 짝수(1,3,5...) → 2행
    final row1 = <Widget>[];
    final row2 = <Widget>[];
    for (int i = 0; i < tags.length; i++) {
      if (i % 2 == 0) {
        row1.add(_tagChip(tags[i]));
      } else {
        row2.add(_tagChip(tags[i]));
      }
    }

    return [
      Row(children: row1),
      if (row2.isNotEmpty) ...[
        const SizedBox(height: 4),
        Row(children: row2),
      ],
    ];
  }

  Widget _buildBanner() {
    final appState = context.watch<AppState>();
    final lang = appState.selectedLanguage;

    final apiLectures = appState.apiLectures;
    final sortedApi = List.from(apiLectures);
    sortedApi.sort((a, b) => (b.uploadDate).compareTo(a.uploadDate));
    final newestLecture = sortedApi.isNotEmpty ? sortedApi.first : null;
    final popularLecture = apiLectures.isNotEmpty ? apiLectures.first : null;

    final banner2Sub = popularLecture != null
        ? '${popularLecture.title}  |  ${popularLecture.instructor} 강사'
        : '강의를 불러오는 중...';
    final banner3Sub = newestLecture != null
        ? '${newestLecture.title}  |  ${newestLecture.instructor} 강사'
        : '강의를 불러오는 중...';

    // 5개 배너 정의
    final List<_BannerData> banners = [
      // 배너1: NEW - 신규 강의 업데이트
      _BannerData(
        badge: 'NEW',
        badgeColor: const Color(0xFF2ECC71),
        title: '신규 강의 업데이트',
        subtitle: banner3Sub,
        btnText: '▶  바로 보기',
        gradientColors: [const Color(0xFF1A6B3A), const Color(0xFF2E8B57)],
        accentEmoji: '✨',
        lecture: newestLecture,
        imagePath: 'assets/images/banners/banner_new_new.jpg',
      ),
      // 배너2: STUDY - 키워드로 합격을 (원형 도서관)
      _BannerData(
        badge: 'STUDY',
        badgeColor: const Color(0xFF9B59B6),
        title: '키워드로 합격을!',
        subtitle: '끼리에.끼리를 묻는 핵심 개념\n학습으로 합격을 잡으세요!',
        btnText: '강의 목록 보기 ▶',
        gradientColors: [const Color(0xFF4A0E8F), const Color(0xFF7B2FBE)],
        accentEmoji: '💡',
        lecture: null,
        imagePath: 'assets/images/banners/banner_study_new.jpg',
      ),
      // 배너3: HOT - 이번 주 인기 강의 (현대 도서관)
      _BannerData(
        badge: 'HOT',
        badgeColor: const Color(0xFFE74C3C),
        title: '이번 주 인기 강의',
        subtitle: banner2Sub,
        btnText: '▶  지금 보기',
        gradientColors: [const Color(0xFF8B1A0A), const Color(0xFFCC3300)],
        accentEmoji: '🔥',
        lecture: popularLecture,
        imagePath: 'assets/images/banners/banner_hot_new.jpg',
      ),
      // 배너4: MATH - 수학 강의 (초록 칠판 배경)
      _BannerData(
        badge: 'MATH',
        badgeColor: const Color(0xFF27AE60),
        title: '수학 강의',
        subtitle: '고등·중등 수학 핵심 개념\n총 17개 강의 보러가기',
        btnText: '수학 강의 전체보기 ▶',
        gradientColors: [const Color(0xFF1A5C2A), const Color(0xFF2E7D32)],
        accentEmoji: '📐',
        lecture: null,
        tabTarget: '수학',
        imagePath: 'assets/images/banners/banner_math.png',
      ),
      // 배너5: SCIENCE - 과학 강의
      _BannerData(
        badge: 'SCIENCE',
        badgeColor: const Color(0xFF8E44AD),
        title: '과학 강의',
        subtitle: '중등·고등 과학 핵심 개념\n총 11개 강의 보러가기',
        btnText: '과학 강의 전체보기 ▶',
        gradientColors: [const Color(0xFF2C0654), const Color(0xFF6A1B9A)],
        accentEmoji: '🔬',
        lecture: null,
        tabTarget: '과학',
        imagePath: 'assets/images/banners/banner_science.png',
      ),
    ];

    return Container(
      height: 168,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Stack(children: [
        PageView.builder(
          controller: _bannerController,
          onPageChanged: (i) => setState(() => _bannerIndex = i),
          itemCount: banners.length,
          itemBuilder: (_, i) {
            final b = banners[i];
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (b.lecture != null) {
                  _openLecture(b.lecture);
                } else if (b.tabTarget != null) {
                  // 수학/과학 탭으로 이동
                  final idx = _tabKeys.indexOf(b.tabTarget!);
                  if (idx >= 0) _tabController.animateTo(idx);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: b.imagePath != null
                      ? DecorationImage(
                          image: AssetImage(b.imagePath!),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            b.gradientColors[0].withValues(alpha: 0.55),
                            BlendMode.multiply,
                          ),
                        )
                      : null,
                  gradient: b.imagePath == null
                      ? LinearGradient(
                          colors: b.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: Stack(children: [
                  // 배경 텍스처 원
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    bottom: -30,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  // 오른쪽 이모지
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(b.accentEmoji,
                          style: const TextStyle(fontSize: 52)),
                    ),
                  ),
                  // 메인 콘텐츠
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 90, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 배지
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: b.badgeColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(b.badge,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5)),
                        ),
                        const SizedBox(height: 8),
                        // 제목
                        Text(b.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.2)),
                        const SizedBox(height: 5),
                        // 부제목
                        Text(b.subtitle,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11,
                                height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 12),
                        // 버튼
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.play_circle_filled, color: Colors.white, size: 14),
                            const SizedBox(width: 5),
                            Text(b.btnText,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
        // 인디케이터 도트
        Positioned(
          bottom: 10,
          right: 16,
          child: Row(
            children: List.generate(
              banners.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: i == _bannerIndex ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: i == _bannerIndex
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildMathScienceCards() {
    final appState = context.watch<AppState>();
    final allLecs = appState.allLectures;
    final mathCount = allLecs.where((l) => l.subject.contains('수학')).length;
    final scienceCount = allLecs.where((l) =>
        l.subject.contains('과학') || l.subject.contains('물리') ||
        l.subject.contains('화학') || l.subject.contains('생명') ||
        l.subject.contains('지구')).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(children: [
        // 수학 카드
        Expanded(
          child: GestureDetector(
            onTap: () {
              final idx = _tabKeys.indexOf('수학');
              if (idx >= 0) _tabController.animateTo(idx);
            },
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 3))],
                image: const DecorationImage(
                  image: AssetImage('assets/images/banners/banner_math.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Color(0x661A5C2A), BlendMode.multiply),
                ),
              ),
              child: Stack(children: [
                // 어두운 그라디언트 오버레이
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.calculate_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 4),
                        const Text('수학', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                      ]),
                      Text('${mathCount > 0 ? mathCount : 17}개 강의',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // 과학 카드
        Expanded(
          child: GestureDetector(
            onTap: () {
              final idx = _tabKeys.indexOf('과학');
              if (idx >= 0) _tabController.animateTo(idx);
            },
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 3))],
                image: const DecorationImage(
                  image: AssetImage('assets/images/banners/banner_science_new.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Color(0x662C0654), BlendMode.multiply),
                ),
              ),
              child: Stack(children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.science_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 4),
                        const Text('과학', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                      ]),
                      Text('${scienceCount > 0 ? scienceCount : 11}개 강의',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildStudyStats(AppState appState) {
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem2(Icons.whatshot_rounded,    '${appState.streakDays}${T('unit_day')}',             '연속 학습',  const Color(0xFFFF6B35)),
          const SizedBox(width: 4),
          _buildStatItem2(Icons.ondemand_video_rounded, '${appState.todayViewedCount}강',                   '오늘 학습',  const Color(0xFF667EEA)),
          const SizedBox(width: 4),
          _buildStatItem2(Icons.task_alt_rounded,    '${appState.completedLectures}${T('unit_count')}',    '완료 강의',  const Color(0xFF11998E)),
          const SizedBox(width: 4),
          _buildStatItem2(Icons.manage_search_rounded,'${appState.searchCount}${T('unit_count')}',          '검색수',     const Color(0xFFF59E0B)),
          const SizedBox(width: 4),
          _buildStatItem2(Icons.smart_display_rounded,'${appState.totalWatchMinutes}${T('unit_min')}',      '시청 시간',  const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _buildStatItem2(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.04)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.12), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(7),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4)],
              ),
              child: Icon(icon, color: Colors.white, size: 14),
            ),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary)),
      Text(label,
          style:
              const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }

  Widget _buildStatDivider() =>
      Container(width: 1, height: 40, color: AppColors.divider);

  Widget _buildRecentLectures(AppState appState) {
    final recent = appState.recentViewedLectures;
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    if (recent.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(T('section_recent'),
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
      ),
      SizedBox(
        height: 260,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: recent.take(5).length,
          itemBuilder: (context, i) => LectureCard(
            lecture: recent[i],
            onTap: () => _openLecture(recent[i]),
          ),
        ),
      ),
    ]);
  }

  void _openLecture(lecture) {
    context.read<AppState>().addRecentView(lecture.id);
    // Google Drive URL이면 플레이어 화면으로 이동 (플레이어에서 브라우저 열기 버튼 제공)
    Navigator.push(context,
        MaterialPageRoute(
            builder: (_) => LecturePlayerScreen(lecture: lecture)));
  }
}

// ─── 썸네일: 여러 URL을 순서대로 시도하는 위젯 ───
class _ThumbWithFallback extends StatefulWidget {
  final List<String> urls;
  final double width;
  final double height;
  final String subject;
  const _ThumbWithFallback({
    required this.urls,
    required this.width,
    required this.height,
    required this.subject,
  });

  @override
  State<_ThumbWithFallback> createState() => _ThumbWithFallbackState();
}

class _ThumbWithFallbackState extends State<_ThumbWithFallback> {
  int _urlIndex = 0;

  Color get _subjectColor {
    switch (widget.subject) {
      case '수학': return AppColors.math;
      case '영어': return AppColors.english;
      case '국어': return AppColors.korean;
      default: return AppColors.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_urlIndex >= widget.urls.length) {
      return Container(
        width: widget.width, height: widget.height,
        color: _subjectColor.withValues(alpha: 0.2),
        child: Icon(Icons.play_circle_outline, size: 36, color: _subjectColor),
      );
    }
    return Image.network(
      widget.urls[_urlIndex],
      width: widget.width, height: widget.height,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: widget.width, height: widget.height,
          color: _subjectColor.withValues(alpha: 0.1),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (_, __, ___) {
        // 다음 URL 시도
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _urlIndex++);
        });
        return Container(
          width: widget.width, height: widget.height,
          color: _subjectColor.withValues(alpha: 0.1),
        );
      },
    );
  }
}

// ─── 신규 강의 카드 (터치 완전 지원) ───
class _NewLectureCard extends StatelessWidget {
  final dynamic lecture;
  final VoidCallback onTap;
  final Widget thumbnailWidget;

  const _NewLectureCard({
    required this.lecture,
    required this.onTap,
    required this.thumbnailWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                  width: 1.5),
            ),
            child: Row(children: [
              // 썸네일
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
                child: thumbnailWidget,
              ),
              // 강의 정보
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF6B35).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(lecture.subject as String,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFFF6B35),
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(children: [
                            Icon(Icons.play_circle_filled,
                                size: 9, color: Colors.green),
                            SizedBox(width: 3),
                            Text('YouTube',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 5),
                      Text(lecture.title as String,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text('${lecture.instructor} 강사',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.play_circle_fill_rounded,
                    color: Color(0xFFFF6B35), size: 30),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// 강의 목록 카드 (추천/인기 탭 세로 리스트용)
class _LectureListCard extends StatelessWidget {
  final dynamic lecture;
  final VoidCallback onTap;
  final Widget thumbnailWidget;
  final bool isPopular;

  const _LectureListCard({
    required this.lecture,
    required this.onTap,
    required this.thumbnailWidget,
    this.isPopular = false,
  });

  @override
  Widget build(BuildContext context) {
    final subjectColor = lecture.subject == '수학'
        ? const Color(0xFF2563EB)
        : lecture.subject == '과학' || lecture.subject == '물리' ||
              lecture.subject == '화학' || lecture.subject == '생명과학' ||
              lecture.subject == '지구과학'
            ? const Color(0xFF7C3AED)
            : const Color(0xFF059669);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일 + 기본 정보 Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 썸네일
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                  child: thumbnailWidget,
                ),
                // 강의 정보
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 과목 + 학년 + 인기 뱃지
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: subjectColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(lecture.subject as String,
                                style: TextStyle(fontSize: 10, color: subjectColor, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              lecture.gradeText as String,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (lecture.gradeYear != null && lecture.gradeYear != 'All' && (lecture.gradeYear as String).isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${lecture.gradeYear}학년',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 6),
                        // 강의 제목
                        Text(
                          lecture.title as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // 강사명
                        Row(children: [
                          const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 3),
                          Text(
                            '${lecture.instructor} 강사',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                          const Spacer(),
                          // 재생 버튼
                          Icon(
                            Icons.play_circle_fill_rounded,
                            color: isPopular ? const Color(0xFFE74C3C) : const Color(0xFF2ECC71),
                            size: 28,
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // 해시태그 2줄 가로스크롤
            if ((lecture.hashtags as List).isNotEmpty)
              Container(
                height: 56,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildHashtagRowsStatic(
                      (lecture.hashtags as List).cast<String>(),
                      subjectColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static List<Widget> _buildHashtagRowsStatic(List<String> tags, Color color) {
    if (tags.isEmpty) return [];
    Widget tagChip(String tag) => Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.20), width: 0.8),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 10,
          color: color.withValues(alpha: 0.9),
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    final row1 = <Widget>[];
    final row2 = <Widget>[];
    for (int i = 0; i < tags.length; i++) {
      if (i % 2 == 0) {
        row1.add(tagChip(tags[i]));
      } else {
        row2.add(tagChip(tags[i]));
      }
    }

    return [
      Row(children: row1),
      if (row2.isNotEmpty) ...[
        const SizedBox(height: 4),
        Row(children: row2),
      ],
    ];
  }
}

/// 배너 데이터 모델
class _BannerData {
  final String badge;
  final Color badgeColor;
  final String title;
  final String subtitle;
  final String btnText;
  final List<Color> gradientColors;
  final String accentEmoji;
  final dynamic lecture;
  final String? tabTarget;
  final String? imagePath;

  const _BannerData({
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
    required this.btnText,
    required this.gradientColors,
    required this.accentEmoji,
    this.lecture,
    this.tabTarget,
    this.imagePath,
  });
}
