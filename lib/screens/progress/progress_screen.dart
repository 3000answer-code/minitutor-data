import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../services/app_state.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../services/translations.dart';
import '../../theme/app_theme.dart';
import '../../screens/profile/profile_drawer.dart';
import '../lecture/lecture_player_screen.dart';
import '../../widgets/lecture_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final AuthService _authService = AuthService();

  // 강의별 시청 진도 맵 { lectureId: progress(0.0~1.0) }
  Map<String, double> _lectureProgressMap = {};
  bool _isLoadingProgress = true;
  
  // 인기 영상 리스트용 학년 탭
  String _popularGrade = 'middle';  // elementary, middle, high

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLectureProgress();
    });
  }

  Future<void> _loadLectureProgress() async {
    final appState = context.read<AppState>();
    if (!appState.isLoggedIn) {
      setState(() => _isLoadingProgress = false);
      return;
    }
    final progressMap = await _authService.loadAllLectureProgress(appState.userId);
    if (mounted) {
      setState(() {
        _lectureProgressMap = progressMap;
        _isLoadingProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    final dataService = DataService();

    final subjects = ['수학', '과학'];
    final grades = ['elementary', 'middle', 'high'];
    final gradeTexts = ['예비중', T('grade_middle'), T('grade_high')];

    // 현재 선택된 과목/학년의 강의 목록 가져오기
    final allLectures = dataService.getAllLectures();
    final subjectLectures = allLectures
        .where((l) => l.subject == appState.progressSubject)
        .toList();

    // 단원별 강의 그룹핑 (series 필드 사용)
    final Map<String, List<dynamic>> chapterMap = {};
    for (final lecture in subjectLectures) {
      final chapterKey = lecture.series.isNotEmpty ? lecture.series : '기타';
      chapterMap.putIfAbsent(chapterKey, () => []);
      chapterMap[chapterKey]!.add(lecture);
    }

    // 전체 진도 계산 (실제 시청 데이터 기반)
    final totalLectures = subjectLectures.length;
    final completedLectures = subjectLectures
        .where((l) => (_lectureProgressMap[l.id] ?? 0.0) >= 0.8)
        .length;
    final overallRate = totalLectures > 0 ? completedLectures / totalLectures : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      endDrawer: const ProfileDrawer(),
      appBar: AppBar(
        title: Text(T('progress_title'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (appState.isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.person_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(appState.nickname,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ]),
                ),
              ),
            ),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: !appState.isLoggedIn
          ? _buildLoginPrompt(T)
          : Column(
              children: [
                // ─── 필터 영역 ───
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      ...List.generate(
                          grades.length,
                          (i) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(gradeTexts[i]),
                                  selected:
                                      appState.progressGrade == grades[i],
                                  onSelected: (_) =>
                                      appState.setProgressGrade(grades[i]),
                                  selectedColor: AppColors.primary
                                      .withValues(alpha: 0.15),
                                  labelStyle: TextStyle(
                                    color: appState.progressGrade == grades[i]
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontWeight:
                                        appState.progressGrade == grades[i]
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                    fontSize: 13,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                ),
                              )),
                    ]),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: subjects.asMap().entries.map((entry) {
                            final sub = entry.value;
                            final isLast = entry.key == subjects.length - 1;
                            final isSelected =
                                appState.progressSubject == sub;
                            return Padding(
                              padding: EdgeInsets.only(right: isLast ? 0 : 12),
                              child: FilterChip(
                                label: Text(sub),
                                selected: isSelected,
                                onSelected: (_) {
                                  appState.setProgressSubject(sub);
                                  _loadLectureProgress();
                                },
                                selectedColor:
                                    _subjectColor(sub).withValues(alpha: 0.15),
                                checkmarkColor: _subjectColor(sub),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? _subjectColor(sub)
                                      : AppColors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  fontSize: 13,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                              ),
                            );
                          }).toList()),
                    ),
                  ]),
                ),

                Expanded(
                  child: _isLoadingProgress
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _loadLectureProgress,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ─── 통계 박스 (홈과 동일) ───
                                  _buildStudyStats(appState),

                                  const SizedBox(height: 16),

                                  // ─── 전체 진도 카드 ───
                                  _buildOverallCard(
                                      appState,
                                      overallRate,
                                      completedLectures,
                                      totalLectures,
                                      gradeTexts,
                                      grades),

                                  const SizedBox(height: 20),

                                  // ─── 인기 영상 리스트 ───
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('인기 영상 리스트',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary)),
                                      TextButton.icon(
                                        onPressed: _loadLectureProgress,
                                        icon: const Icon(Icons.refresh,
                                            size: 16),
                                        label: const Text('새로고침',
                                            style: TextStyle(fontSize: 12)),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          minimumSize: Size.zero,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // 예비중/중/고 탭
                                  _buildGradeTabsForPopular(),
                                  const SizedBox(height: 16),

                                  // 인기 영상 목록 (임시 데이터)
                                  _buildPopularVideosList(allLectures),

                                  const SizedBox(height: 20),

                                  // ─── 학습 통계 ───
                                  const Text('나의 학습 통계',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 12),
                                  _buildStatsGrid(appState),

                                  const SizedBox(height: 24),

                                  // ─── 기간별 학습 통계 그래프 ───
                                  const Text('기간별 학습 통계',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 12),
                                  _buildPeriodStatsChart(),

                                  const SizedBox(height: 24),

                                  // ─── 검색 조회수 통계 그래프 ───
                                  const Text('기간별 검색 조회수',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 12),
                                  _buildSearchStatsChart(),

                                  const SizedBox(height: 80),
                                ]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoginPrompt(Function(String) T) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.lock_outline_rounded,
            size: 64, color: AppColors.textSecondary),
        const SizedBox(height: 16),
        Text(T('login_required'),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Text('로그인하면 나의 학습 진도를 확인할 수 있어요!',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('로그인하기',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _buildOverallCard(AppState appState, double overallRate,
      int completedLectures, int totalLectures, List<String> gradeTexts, List<String> grades) {
    final gradeIdx = grades.indexOf(appState.progressGrade);
    final gradeText = gradeIdx >= 0 ? gradeTexts[gradeIdx] : appState.progressGrade;

    // 과목+학년에 따른 배너 이미지 선택
    final isMath = appState.progressSubject == '수학';
    final isHigh = appState.progressGrade == 'high';
    String bannerAsset;
    if (isMath && isHigh)    bannerAsset = 'assets/images/banner_math_high.jpg';
    else if (isMath)          bannerAsset = 'assets/images/banner_math_middle.jpg';
    else if (isHigh)          bannerAsset = 'assets/images/banner_science_high.jpg';
    else                      bannerAsset = 'assets/images/banner_science_middle.jpg';

    // 오버레이 그라데이션 색 (과목별)
    final Color overlayColor = isMath
        ? const Color(0xFF1565C0)
        : const Color(0xFF6A1B9A);

    return Container(
      height: 140,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: overlayColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── 배경 사진 ──
          Image.asset(
            bannerAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: overlayColor),
          ),
          // ── 어두운 그라데이션 오버레이 ──
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  overlayColor.withValues(alpha: 0.82),
                  overlayColor.withValues(alpha: 0.45),
                  Colors.transparent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          // ── 컨텐츠 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              // 원형 진행률
              CircularPercentIndicator(
                radius: 46,
                lineWidth: 7,
                percent: overallRate.clamp(0.0, 1.0),
                center: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${(overallRate * 100).toInt()}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(color: Colors.black38, blurRadius: 4)])),
                  const Text('달성',
                      style: TextStyle(color: Colors.white70, fontSize: 10)),
                ]),
                progressColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(width: 18),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // 과목+학년 뱃지
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: Text('${appState.progressSubject} · $gradeText',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3)),
                    ),
                    const SizedBox(height: 8),
                    Text('$completedLectures / $totalLectures 강의 완료',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
                    const SizedBox(height: 3),
                    Text('${totalLectures - completedLectures}개 강의 남음',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12)),
                    const SizedBox(height: 10),
                    Row(children: [
                      _buildStatChip('🔥 ${appState.streakDays}일 연속'),
                      const SizedBox(width: 8),
                      _buildStatChip('⏱️ ${appState.totalStudyMinutes}분 학습'),
                    ]),
                  ])),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(BuildContext context, String chapter,
      List<dynamic> lectures, String subject) {
    final totalCount = lectures.length;
    final completedCount = lectures
        .where((l) => (_lectureProgressMap[l.id] ?? 0.0) >= 0.8)
        .length;
    final rate = totalCount > 0 ? completedCount / totalCount : 0.0;
    final isCompleted = completedCount == totalCount && totalCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: _subjectColor(subject).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6)),
            child: Text(chapter,
                style: TextStyle(
                    fontSize: 11,
                    color: _subjectColor(subject),
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text('강의 $totalCount개',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary))),
          if (isCompleted)
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 20)
          else
            Text('$completedCount/$totalCount',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 10),
        LinearPercentIndicator(
          lineHeight: 8,
          percent: rate.clamp(0.0, 1.0),
          backgroundColor: AppColors.divider,
          progressColor: isCompleted ? AppColors.success : _subjectColor(subject),
          barRadius: const Radius.circular(4),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        // 강의 목록 (최대 3개 표시, 더보기 버튼)
        ...lectures.take(3).map((lecture) => _buildLectureRow(context, lecture, subject)),
        if (lectures.length > 3)
          TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _buildLectureListSheet(context, chapter, lectures, subject),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: Text(
              '+ ${lectures.length - 3}개 더 보기',
              style: TextStyle(
                  fontSize: 12,
                  color: _subjectColor(subject),
                  fontWeight: FontWeight.w600),
            ),
          ),
      ]),
    );
  }

  Widget _buildLectureRow(BuildContext context, dynamic lecture, String subject) {
    final progress = _lectureProgressMap[lecture.id] ?? 0.0;
    final isCompleted = progress >= 0.8;
    final progressPercent = (progress * 100).toInt();

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LecturePlayerScreen(lecture: lecture),
          ),
        );
        // 화면 돌아왔을 때 진도 새로고침
        _loadLectureProgress();
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success.withValues(alpha: 0.15)
                  : _subjectColor(subject).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : Icons.play_arrow_rounded,
              size: 18,
              color: isCompleted ? AppColors.success : _subjectColor(subject),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lecture.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary)),
              if (progress > 0 && !isCompleted)
                Text('$progressPercent% 시청',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ),
          if (progress > 0)
            SizedBox(
              width: 50,
              child: LinearPercentIndicator(
                lineHeight: 4,
                percent: progress.clamp(0.0, 1.0),
                backgroundColor: AppColors.divider,
                progressColor:
                    isCompleted ? AppColors.success : _subjectColor(subject),
                barRadius: const Radius.circular(2),
                padding: EdgeInsets.zero,
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildLectureListSheet(BuildContext context, String chapter,
      List<dynamic> lectures, String subject) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(chapter,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800)),
        ),
        const Divider(height: 1),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: lectures.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final lecture = lectures[i];
              final progress = _lectureProgressMap[lecture.id] ?? 0.0;
              final isCompleted = progress >= 0.8;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCompleted
                      ? AppColors.success.withValues(alpha: 0.15)
                      : _subjectColor(subject).withValues(alpha: 0.1),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : Icons.play_arrow_rounded,
                    color: isCompleted ? AppColors.success : _subjectColor(subject),
                    size: 20,
                  ),
                ),
                title: Text(lecture.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  isCompleted
                      ? '완료'
                      : progress > 0
                          ? '${(progress * 100).toInt()}% 시청'
                          : '미시청',
                  style: TextStyle(
                      fontSize: 12,
                      color: isCompleted
                          ? AppColors.success
                          : AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LecturePlayerScreen(lecture: lecture),
                    ),
                  );
                  _loadLectureProgress();
                },
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildEmptyChapter() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(children: [
        Icon(Icons.menu_book_rounded, size: 48, color: AppColors.textSecondary),
        SizedBox(height: 12),
        Text('등록된 강의가 없습니다',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        SizedBox(height: 4),
        Text('NAS에서 강의를 업로드해주세요',
            style:
                TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildStatsGrid(AppState appState) {
    final stats = [
      {
        'icon': Icons.local_fire_department_rounded,
        'color': AppColors.accent,
        'value': '${appState.streakDays}일',
        'label': '연속 학습일'
      },
      {
        'icon': Icons.access_time_rounded,
        'color': AppColors.primary,
        'value': '${appState.totalStudyMinutes}분',
        'label': '총 학습 시간'
      },
      {
        'icon': Icons.play_circle_outline_rounded,
        'color': AppColors.math,
        'value': '${appState.completedLectures}개',
        'label': '완료 강의'
      },
      {
        'icon': Icons.bookmark_rounded,
        'color': AppColors.social,
        'value': '${appState.favoriteIds.length}개',
        'label': '즐겨찾기'
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: stats
          .map((s) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color:
                            (s['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(s['icon'] as IconData,
                        color: s['color'] as Color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(s['value'] as String,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                        Text(s['label'] as String,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ]),
                ]),
              ))
          .toList(),
    );
  }

  Widget _buildStatChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }

  Color _subjectColor(String subject) {
    switch (subject) {
      case '수학':
        return AppColors.math;
      case '과학':
        return AppColors.science;
      case '두번설명':
        return const Color(0xFF6C63FF);
      default:
        return AppColors.other;
    }
  }

  // 인기 영상용 학년 탭
  Widget _buildGradeTabsForPopular() {
    final tabs = [
      {'grade': 'elementary', 'label': '예비중'},
      {'grade': 'middle', 'label': '중등'},
      {'grade': 'high', 'label': '고등'},
    ];
    
    return Row(
      children: tabs.map((tab) {
        final isSelected = _popularGrade == tab['grade'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _popularGrade = tab['grade']!),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: 1.5,
                ),
              ),
              child: Text(
                tab['label']!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 인기 영상 리스트 (추천 강의에서 학년별 5개씩, 예비중은 빈칸)
  Widget _buildPopularVideosList(List<dynamic> allLectures) {
    final appState = context.read<AppState>();

    // 예비중은 빈칸 처리
    if (_popularGrade == 'elementary') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.upcoming_rounded, size: 44, color: AppColors.textHint.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              const Text('준비 중입니다',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              const Text('예비중 인기 강의가 곧 추가됩니다',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint)),
            ],
          ),
        ),
      );
    }

    // 추천 강의에서 해당 학년 필터 → 상위 5개
    final recommended = appState.recommendedLectures
        .where((l) => l.grade == _popularGrade)
        .take(5)
        .toList();

    // 추천 강의가 부족하면 전체에서 보충
    if (recommended.length < 5) {
      final extra = (allLectures as List)
          .where((l) => l.grade == _popularGrade && !recommended.any((r) => r.id == l.id))
          .take(5 - recommended.length)
          .toList();
      for (final l in extra) {
        recommended.add(l);
      }
    }

    if (recommended.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.video_library_outlined, size: 44, color: AppColors.textHint.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              const Text('등록된 강의가 없습니다',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    // 520 스타일 LectureCard (순위 배지 + LectureCard)
    return Column(
      children: recommended.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final lecture = entry.value;
        final rankColor = rank == 1
            ? const Color(0xFFFFD700)
            : rank == 2
                ? const Color(0xFFC0C0C0)
                : rank == 3
                    ? const Color(0xFFCD7F32)
                    : AppColors.textSecondary;

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 순위 배지
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: rank <= 3 ? rankColor : rankColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: rank <= 3 ? Colors.white : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // LectureCard (520 스타일 4~5줄)
              Expanded(
                child: LectureCard(
                  lecture: lecture,
                  onTap: () {
                    appState.addRecentView(lecture.id);
                    if (appState.pipActive && appState.pipLecture?.id == lecture.id) {
                      appState.deactivatePip();
                    }
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => LecturePlayerScreen(lecture: lecture),
                    ));
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }


  // 통계 박스 (홈 화면과 동일)
  Widget _buildStudyStats(AppState appState) {
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: SizedBox(
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: _buildStatItem(Icons.whatshot_rounded, '${appState.streakDays}${T('unit_day')}', T('stat_streak'), const Color(0xFFFF6B35))),
            const SizedBox(width: 8),
            Expanded(child: _buildStatItem(Icons.ondemand_video_rounded, '${appState.todayViewedCount}강', '오늘 학습', const Color(0xFF667EEA))),
            const SizedBox(width: 8),
            Expanded(child: _buildStatItem(Icons.task_alt_rounded, '${appState.completedLectures}${T('unit_count')}', T('stat_completed'), const Color(0xFF11998E))),
            const SizedBox(width: 8),
            Expanded(child: _buildStatItem(Icons.manage_search_rounded, '${appState.searchCount}${T('unit_count')}', '검색수', const Color(0xFFF59E0B))),
            const SizedBox(width: 8),
            Expanded(child: _buildStatItem(Icons.smart_display_rounded, '${appState.totalWatchMinutes}${T('unit_min')}', '시청 시간', const Color(0xFF8B5CF6))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.1,
                  letterSpacing: -0.3)),
          const SizedBox(height: 1),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                  height: 1.0,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 기간별 학습 통계 그래프 (프리미엄 디자인 + 사실적 데이터)
  // ─────────────────────────────────────────────────────────────
  Widget _buildPeriodStatsChart() {
    final periods   = ['1일', '3일', '7일', '15일', '30일'];
    // 사실적 데이터: 누적 학습시간(분) / 완료강의 수
    final studyMins = [28, 94, 236, 512, 893];
    final completed = [1, 4, 10, 21, 35];
    final maxMins   = studyMins.reduce((a, b) => a > b ? a : b).toDouble();

    // 색상 팔레트 (그라데이션 진한→연한)
    const Color c1 = Color(0xFF4F46E5); // 인디고
    const Color c2 = Color(0xFF818CF8); // 라이트 인디고

    return _buildChartCard(
      title: '기간별 학습 통계',
      subtitle: '최근 30일 누적 학습 데이터',
      legends: [
        _chartLegend(c1, '학습시간(분)'),
        _chartLegend(const Color(0xFF10B981), '완료 강의'),
      ],
      child: SizedBox(
        height: 190,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(periods.length, (i) {
            final barH = (studyMins[i] / maxMins * 145).clamp(16.0, 145.0);
            final isLast = i == periods.length - 1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 학습시간 라벨
                    Text('${studyMins[i]}분',
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: c1,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    // 막대 (그라데이션 + 둥근 상단)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                      child: Container(
                        height: barH,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [c1, c2],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Center(
                          child: Text('${completed[i]}',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: barH > 30 ? 12 : 9,
                                  fontWeight: FontWeight.w900,
                                  shadows: const [Shadow(color: Colors.black26, blurRadius: 3)])),
                        ),
                      ),
                    ),
                    // 바닥 라인
                    Container(height: 2, color: const Color(0xFFE0E7FF)),
                    const SizedBox(height: 6),
                    // 기간 라벨
                    Text(periods[i],
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B))),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 기간별 검색 조회수 그래프 (프리미엄 디자인 + 사실적 데이터)
  // ─────────────────────────────────────────────────────────────
  Widget _buildSearchStatsChart() {
    final periods       = ['1일', '3일', '7일', '15일', '30일'];
    // 사실적 데이터: 총 검색 횟수 / 고유 검색어 수
    final totalSearches = [12, 38, 87, 189, 354];
    final uniqueKeywords = [7, 21, 49, 108, 213];
    final maxCount = totalSearches.reduce((a, b) => a > b ? a : b).toDouble();

    const Color cOrange  = Color(0xFFF97316); // 총 검색 (오렌지)
    const Color cPink    = Color(0xFFEC4899); // 고유 검색어 (핑크)

    return _buildChartCard(
      title: '기간별 검색 조회수',
      subtitle: '최근 30일 검색 활동 분석',
      legends: [
        _chartLegend(cOrange, '총 검색'),
        _chartLegend(cPink,   '고유 검색어'),
      ],
      child: SizedBox(
        height: 190,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(periods.length, (i) {
            final barH = (totalSearches[i] / maxCount * 145).clamp(16.0, 145.0);
            final isLast = i == periods.length - 1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 총 검색 수 라벨
                    Text('${totalSearches[i]}회',
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: cOrange,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    // 막대 (투-톤: 아래는 핑크, 위는 오렌지)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                      child: Container(
                        height: barH,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cOrange, Color(0xFFFBBF24)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Center(
                          child: Text('${uniqueKeywords[i]}',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: barH > 30 ? 12 : 9,
                                  fontWeight: FontWeight.w900,
                                  shadows: const [Shadow(color: Colors.black26, blurRadius: 3)])),
                        ),
                      ),
                    ),
                    // 바닥 라인
                    Container(height: 2, color: const Color(0xFFFFEDD5)),
                    const SizedBox(height: 6),
                    // 기간 라벨
                    Text(periods[i],
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B))),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── 공통 차트 카드 래퍼 ──────────────────────────────────────
  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required List<Widget> legends,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16, spreadRadius: 0, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B), letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500)),
                ]),
              ),
              // 범례
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: legends,
              ),
            ],
          ),
          const SizedBox(height: 18),
          // 그래프
          child,
        ],
      ),
    );
  }

  // ── 범례 아이템 ─────────────────────────────────────────────
  Widget _chartLegend(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  // 레거시 호환 (기존 _buildLegendItem 참조가 있을 경우)
  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    ]);
  }
}

