import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  List<String> _tabs = ['추천', '인기', '국어', '영어', '수학', '과학', '사회'];
  final _tabKeys = ['recommend', 'popular', '국어', '영어', '수학', '과학', '사회'];
  int _bannerIndex = 0;
  final PageController _bannerController = PageController();

  final _banners = [
    {
      'title': '2분 공부의 기적',
      'subtitle': '매일 2분씩, 365일 후의 나를 상상해보세요!',
      'color': AppColors.primary,
      'icon': Icons.lightbulb_rounded
    },
    {
      'title': '이번 주 인기 강의',
      'subtitle': '이차방정식 근의 공식 - 김수학 강사',
      'color': AppColors.accent,
      'icon': Icons.local_fire_department_rounded
    },
    {
      'title': '신규 강의 업데이트',
      'subtitle': '고등 수학 삼각함수 시리즈 오픈!',
      'color': AppColors.math,
      'icon': Icons.new_releases_rounded
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<AppState>().setHomeTab(_tabKeys[_tabController.index]);
      }
    });
    Future.delayed(const Duration(seconds: 3), _autoSlide);
  }

  void _autoSlide() {
    if (!mounted) return;
    final next = (_bannerIndex + 1) % _banners.length;
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
      T('tab_korean'), T('tab_english'), T('tab_math'),
      T('tab_science'), T('tab_social'),
    ];
    // Scaffold 없음 — MainShell의 Scaffold가 AppBar+endDrawer 담당
    return Column(
      children: [
        // 탭바만 표시 (AppBar는 MainShell에서 처리)
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            dividerColor: AppColors.divider,
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
    final ytLectures = appState.allLectures.where((l) => l.videoUrl.contains('youtube')).toList();
    final lectures = tab == 'recommend'
        ? appState.recommendedLectures
        : tab == 'popular'
            ? appState.popularLectures
            : appState.getLecturesBySubject(tab);

    return Container(
      color: AppColors.background,
      child: CustomScrollView(
        slivers: [
          if (tab == 'recommend' || tab == 'popular') ...[
            SliverToBoxAdapter(child: _buildBanner()),
            SliverToBoxAdapter(child: _buildStudyStats(appState)),
          ],
          // ── YouTube 실제 강의 섹션 (추천/인기/수학 탭에 항상 표시) ──
          if ((tab == 'recommend' || tab == 'popular' || tab == '수학') && ytLectures.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('LIVE',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  Text(T('section_live_lecture'),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final lec = ytLectures[i];
                    return GestureDetector(
                      onTap: () => _openLecture(lec),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(children: [
                          // 썸네일
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                            child: _buildYtThumbnail(lec, 120, 80),
                          ),
                          // 정보
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.math.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(T('tab_math'), style: const TextStyle(fontSize: 10, color: AppColors.math, fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(children: [
                                      Icon(Icons.play_circle_filled, size: 10, color: Colors.red),
                                      SizedBox(width: 3),
                                      Text('YouTube', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w700)),
                                    ]),
                                  ),
                                ]),
                                const SizedBox(height: 6),
                                Text(lec.title,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Text(lec.instructor,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ]),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                          ),
                        ]),
                      ),
                    );
                  },
                  childCount: ytLectures.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(children: [
                Text(
                  tab == 'recommend'
                      ? T('section_recommend')
                      : tab == 'popular'
                          ? T('section_popular')
                          : '📚 ${T('section_subject_lecture')}',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text(T('btn_view_all'),
                      style: const TextStyle(fontSize: 13, color: AppColors.primary)),
                ),
              ]),
            ),
          ),
          if (tab == 'recommend' || tab == 'popular')
            SliverToBoxAdapter(
              child: SizedBox(
                height: 260,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: lectures.length,
                  itemBuilder: (context, i) => LectureCard(
                    lecture: lectures[i],
                    onTap: () => _openLecture(lectures[i]),
                  ),
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
          if (tab == 'recommend')
            SliverToBoxAdapter(child: _buildRecentLectures(appState)),
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

  Widget _buildBanner() {
    final appState = context.watch<AppState>();
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    final banners = [
      {
        'title': T('banner_miracle_title'),
        'subtitle': T('banner_miracle_sub'),
        'color': AppColors.primary,
        'icon': Icons.lightbulb_rounded,
      },
      {
        'title': T('banner_popular_title'),
        'subtitle': '이차방정식 근의 공식 - 김수학 강사',
        'color': AppColors.accent,
        'icon': Icons.local_fire_department_rounded,
      },
      {
        'title': T('banner_new_title'),
        'subtitle': T('banner_new_sub'),
        'color': AppColors.math,
        'icon': Icons.new_releases_rounded,
      },
    ];
    return Container(
      height: 140,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Stack(children: [
        PageView.builder(
          controller: _bannerController,
          onPageChanged: (i) => setState(() => _bannerIndex = i),
          itemCount: banners.length,
          itemBuilder: (_, i) {
            final b = banners[i];
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (b['color'] as Color),
                    (b['color'] as Color).withValues(alpha: 0.7)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Text(b['title'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(b['subtitle'] as String,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13)),
                      const SizedBox(height: 10),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(T('btn_watch_now'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600))),
                    ])),
                Icon(b['icon'] as IconData,
                    size: 60, color: Colors.white.withValues(alpha: 0.4)),
              ]),
            );
          },
        ),
        Positioned(
            bottom: 10,
            right: 16,
            child: Row(
                children: List.generate(
                    banners.length,
                    (i) => Container(
                          width: i == _bannerIndex ? 16 : 6,
                          height: 6,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                              color: i == _bannerIndex
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(3)),
                        )))),
      ]),
    );
  }

  Widget _buildStudyStats(AppState appState) {
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
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
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildStatItem('🔥', '${appState.streakDays}${T('unit_day')}', T('stat_streak')),
        _buildStatDivider(),
        _buildStatItem('⏱️', '${appState.todayStudyMinutes}${T('unit_min')}', T('stat_today')),
        _buildStatDivider(),
        _buildStatItem('✅', '${appState.completedLectures}${T('unit_count')}', T('stat_completed')),
      ]),
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
    Navigator.push(context,
        MaterialPageRoute(
            builder: (_) => LecturePlayerScreen(lecture: lecture)));
  }
}

// ─── YouTube 썸네일: 여러 URL을 순서대로 시도하는 위젯 ───
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
      headers: const {
        'User-Agent': 'Mozilla/5.0',
        'Referer': 'https://www.youtube.com/',
      },
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
