import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/instructor.dart';
import '../../models/lecture.dart';
import '../../services/app_state.dart';
import '../../services/translations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lecture_card.dart';
import '../../screens/profile/profile_drawer.dart';
import '../lecture/lecture_player_screen.dart';

class InstructorScreen extends StatefulWidget {
  const InstructorScreen({super.key});

  @override
  State<InstructorScreen> createState() => _InstructorScreenState();
}

class _InstructorScreenState extends State<InstructorScreen> {
  String _selectedSubject = '전체'; // 과목 필터

  // 학제별 과목 목록
  static const Map<String, List<String>> _subjectsByGrade = {
    'pre_middle': ['전체', '수학', '과학'],
    'middle':     ['전체', '수학', '과학'],
    'high':       ['전체', '수학', '공통과학', '물리', '화학', '생명과학', '지구과학'],
  };

  // 학제 변경 시 과목 필터 리셋
  void _onGradeChanged(String grade, AppState appState) {
    appState.setInstructorGrade(grade);
    final subjects = _subjectsByGrade[grade] ?? ['전체'];
    if (!subjects.contains(_selectedSubject)) {
      setState(() => _selectedSubject = '전체');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    // ✅ 강의 데이터 기반 동적 강사 목록 (새 콘텐츠 업로드 시 자동 반영)
    final allInstructors = appState.dynamicInstructors;
    final gradeMap = {'pre_middle': T('grade_pre_middle'), 'middle': T('grade_middle'), 'high': T('grade_high')};

    var filtered = allInstructors
        .where((i) => i.grade == appState.instructorGrade ||
            (appState.instructorGrade == 'pre_middle' && i.grade == 'elementary'))
        .toList();

    // 과목 필터
    if (_selectedSubject != '전체') {
      filtered = filtered.where((i) => i.subject == _selectedSubject).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      endDrawer: const ProfileDrawer(),
      appBar: AppBar(
        title: Text(T('instructor_by'), style: const TextStyle(fontWeight: FontWeight.w800)),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(93),
          child: Container(
            color: Colors.white,
            child: Column(children: [
              // 학제 탭
              Row(children: ['pre_middle', 'middle', 'high'].map((g) =>
                Expanded(child: GestureDetector(
                  onTap: () => _onGradeChanged(g, appState),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(
                        color: appState.instructorGrade == g ? AppColors.primary : Colors.transparent,
                        width: 3))),
                    child: Text(gradeMap[g]!, textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: appState.instructorGrade == g ? FontWeight.w700 : FontWeight.w400,
                        color: appState.instructorGrade == g ? AppColors.primary : AppColors.textSecondary)),
                  ),
                ))
              ).toList()),
              Container(height: 1, color: AppColors.divider),
              // 과목 필터 칩
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  children: (_subjectsByGrade[appState.instructorGrade] ?? ['전체', '수학', '과학']).map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSubject = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: _selectedSubject == s ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedSubject == s ? AppColors.primary : AppColors.divider),
                        ),
                        child: Text(s, style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: _selectedSubject == s ? Colors.white : AppColors.textSecondary)),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ]),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text(T('no_lectures'), style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _buildInstructorCard(context, filtered[i], appState),
            ),
    );
  }

  Widget _buildInstructorCard(BuildContext context, Instructor instructor, AppState appState) {
    // ✅ 강의 데이터 기반 동적 강의 목록 (새 콘텐츠 업로드 시 자동 반영)
    final lectures = appState.getLecturesByInstructor(instructor.name);

    // 강사 과목 색상 - AppColors 사용으로 통일
    final subjectColor = _subjectColor(instructor.subject);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 강사 프로필 헤더
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            gradient: LinearGradient(
              colors: [subjectColor.withValues(alpha: 0.04), Colors.white],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 프로필 이미지
            Container(
              width: 62, height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: subjectColor.withValues(alpha: 0.3), width: 2),
              ),
              child: ClipOval(
                child: Image.network(
                  instructor.profileImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: subjectColor.withValues(alpha: 0.1),
                    child: Icon(Icons.person_rounded, size: 32, color: subjectColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // 강사 정보
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(instructor.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: subjectColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: subjectColor.withValues(alpha: 0.25)),
                  ),
                  child: Text(instructor.subject,
                    style: TextStyle(fontSize: 11, color: subjectColor, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 5),
              Text(instructor.introduction,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              // 통계 영역
              Wrap(spacing: 12, children: [
                _statChip(Icons.star_rounded, '${instructor.rating}', const Color(0xFFFBBF24)),
                _statChip(Icons.play_lesson_outlined, _lectureCountLabel(lectures, instructor.lectureCount), AppColors.textHint),
                _statChip(Icons.play_circle_outline_rounded, '${_formatCount(instructor.followerCount)}회', AppColors.textHint),
              ]),
            ])),
          ]),
        ),

        // 시리즈 목록 (정리된 레이아웃)
        if (instructor.series.isNotEmpty) ...[
          Container(
            width: double.infinity,
            height: 1,
            color: AppColors.divider,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: subjectColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('시리즈 ${instructor.series.length}',
                  style: TextStyle(fontSize: 11, color: subjectColor, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: instructor.series.take(4).map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: subjectColor.withValues(alpha: 0.3)),
                ),
                child: Text(s,
                  style: TextStyle(fontSize: 12, color: subjectColor, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
          ),
        ],

        // 강의 목록
        if (lectures.isNotEmpty) ...[
          Container(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Text('강의 ${lectures.length}개',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              TextButton(
                onPressed: () => _openAllLectures(context, instructor, lectures),
                child: const Text('전체보기', style: TextStyle(fontSize: 12)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: lectures.take(2).map((l) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LectureCard(
                  lecture: l,
                  onTap: () {
                    appState.addRecentView(l.id);
                    if (appState.pipActive && appState.pipLecture?.id != l.id) {
                      appState.deactivatePip();
                    }
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => LecturePlayerScreen(lecture: l)));
                  },
                  onTagTap: (tag) {
                    appState.setSearchQuery(tag);
                    appState.setNavIndex(3);
                  },
                ),
              )
            ).toList()),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Center(
                child: Text('강의 준비 중입니다',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint)),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]);
  }

  void _openAllLectures(BuildContext context, Instructor instructor, List<Lecture> lectures) {
    // ✅ 부모 context의 AppState를 미리 캡처 → 바텀시트 내부에서도 안전하게 사용
    final appState = context.read<AppState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,   // ✅ Root Navigator 사용 → Provider/ImageCache 올바르게 상속
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        final subjectColor = _subjectColor(instructor.subject);

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollCtrl) => Column(
            children: [
              // ── 핸들 + 헤더 ──
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                    child: Row(children: [
                      // ── 뒤로가기(닫기) 버튼 ──
                      GestureDetector(
                        onTap: () => Navigator.of(sheetCtx).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 16, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 6, height: 24,
                        decoration: BoxDecoration(
                          color: subjectColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${instructor.name} 강사의 강의',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                          Text('${instructor.subject} · ${lectures.length}개 강의',
                            style: TextStyle(fontSize: 12, color: subjectColor,
                                fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ]),
                  ),
                  Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
                ]),
              ),

              // ── 강의 목록 ──
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: lectures.length,
                  itemBuilder: (_, i) {
                    final lec = lectures[i];
                    return LectureCard(
                      lecture: lec,
                      // ✅ onTagTap 직접 주입 → AppState 없이도 태그 탭 동작
                      onTagTap: (tag) {
                        Navigator.pop(sheetCtx);
                        appState.setSearchQuery(tag);
                        appState.setNavIndex(3);
                      },
                      onTap: () {
                        appState.addRecentView(lec.id);
                        if (appState.pipActive && appState.pipLecture?.id != lec.id) {
                          appState.deactivatePip();
                        }
                        Navigator.pop(sheetCtx);
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => LecturePlayerScreen(
                            lecture: lec,
                            autoPlayList: lectures,
                            autoPlayIndex: i,
                          ),
                        ));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 과목별 색상 - AppColors 중앙 관리
  Color _subjectColor(String subject) {
    switch (subject) {
      case '수학':      return AppColors.math;
      case '과학':      return AppColors.science;
      case '공통과학':  return AppColors.commonScience;
      case '물리':      return AppColors.physics;
      case '화학':      return AppColors.chemistry;
      case '생명과학':  return AppColors.biology;
      case '지구과학':  return AppColors.earth;
      default:          return AppColors.primary;
    }
  }

  /// 강의 수 라벨 (두번설명 포함 시 별도 표기)
  String _lectureCountLabel(List<Lecture> lectures, int fallback) {
    final total = lectures.isNotEmpty ? lectures.length : fallback;
    final twiceCount = lectures.where((l) => l.lectureType == 'twice').length;
    if (twiceCount > 0) {
      return '강의 $total개 · 두번설명 $twiceCount개';
    }
    return '강의 $total개';
  }

  String _formatCount(int count) {
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}만';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}천';
    return count.toString();
  }
}
