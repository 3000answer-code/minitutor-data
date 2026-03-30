import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../services/app_state.dart';
import '../../services/data_service.dart';
import '../../services/translations.dart';
import '../../theme/app_theme.dart';
import '../lecture/lecture_player_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    final dataService = DataService();

    final subjects = ['수학', '국어', '영어', '과학', '사회'];
    final grades = ['elementary', 'middle', 'high'];
    final gradeTexts = [T('grade_elementary'), T('grade_middle'), T('grade_high')];

    final units = dataService.getStudyUnits(appState.progressSubject, appState.progressGrade);
    final completed = units.fold<int>(0, (s, u) => s + u.completedLectures);
    final total = units.fold<int>(0, (s, u) => s + u.totalLectures);
    final overallRate = total > 0 ? completed / total : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(T('progress_title'), style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: Column(
        children: [
          // ─── 필터 영역 ───
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(children: [
              // 학제 선택
              Row(children: [
                Text(T('filter_grade'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(width: 12),
                ...List.generate(grades.length, (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(gradeTexts[i]),
                    selected: appState.progressGrade == grades[i],
                    onSelected: (_) => appState.setProgressGrade(grades[i]),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: appState.progressGrade == grades[i] ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: appState.progressGrade == grades[i] ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 13,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                )),
              ]),
              const SizedBox(height: 10),
              // 과목 선택
              SizedBox(
                height: 36,
                child: ListView(scrollDirection: Axis.horizontal, children: subjects.map((sub) {
                  final isSelected = appState.progressSubject == sub;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(sub),
                      selected: isSelected,
                      onSelected: (_) => appState.setProgressSubject(sub),
                      selectedColor: _subjectColor(sub).withValues(alpha: 0.15),
                      checkmarkColor: _subjectColor(sub),
                      labelStyle: TextStyle(
                        color: isSelected ? _subjectColor(sub) : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 13,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  );
                }).toList()),
              ),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ─── 전체 진도 카드 ───
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_subjectColor(appState.progressSubject), _subjectColor(appState.progressSubject).withValues(alpha: 0.7)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    CircularPercentIndicator(
                      radius: 52,
                      lineWidth: 8,
                      percent: overallRate.clamp(0.0, 1.0),
                      center: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('${(overallRate * 100).toInt()}%',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                        const Text('달성', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ]),
                      progressColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                    const SizedBox(width: 20),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${appState.progressSubject} · ${gradeTexts[grades.indexOf(appState.progressGrade)]}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text('$completed / $total 강의 완료',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${total - completed}개 강의 남음',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                      const SizedBox(height: 12),
                      // 학습 스트릭
                      Row(children: [
                        _buildStatChip('🔥 ${appState.streakDays}일 연속'),
                        const SizedBox(width: 8),
                        _buildStatChip('⏱️ ${appState.totalStudyMinutes}분 학습'),
                      ]),
                    ])),
                  ]),
                ),

                const SizedBox(height: 20),

                // ─── 단원별 진도 ───
                const Text('단원별 학습 현황',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 12),

                ...units.map((unit) => _buildUnitCard(context, unit, appState.progressSubject)),

                const SizedBox(height: 20),

                // ─── 학습 통계 ───
                const Text('나의 학습 통계',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                _buildStatsGrid(appState),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(BuildContext context, unit, String subject) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _subjectColor(subject).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6)),
            child: Text(unit.chapter, style: TextStyle(fontSize: 11, color: _subjectColor(subject), fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(unit.unitName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
          if (unit.isCompleted)
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20)
          else
            Text(unit.progressText, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 10),
        LinearPercentIndicator(
          lineHeight: 8,
          percent: unit.completionRate.clamp(0.0, 1.0),
          backgroundColor: AppColors.divider,
          progressColor: unit.isCompleted ? AppColors.success : _subjectColor(subject),
          barRadius: const Radius.circular(4),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 6),
        Row(children: [
          Text('${(unit.completionRate * 100).toInt()}% 완료',
            style: TextStyle(fontSize: 11, color: unit.isCompleted ? AppColors.success : AppColors.textSecondary)),
          const Spacer(),
          TextButton(
            onPressed: () {
              final dataService = DataService();
              final lectures = dataService.getAllLectures()
                  .where((l) => l.subject == subject)
                  .toList();
              if (lectures.isNotEmpty) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => LecturePlayerScreen(lecture: lectures.first),
                ));
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: Text(unit.isCompleted ? '다시 보기' : '이어서 학습',
              style: TextStyle(fontSize: 12, color: _subjectColor(subject), fontWeight: FontWeight.w600)),
          ),
        ]),
      ]),
    );
  }

  Widget _buildStatsGrid(AppState appState) {
    final stats = [
      {'icon': Icons.local_fire_department_rounded, 'color': AppColors.accent, 'value': '${appState.streakDays}일', 'label': '연속 학습일'},
      {'icon': Icons.access_time_rounded, 'color': AppColors.primary, 'value': '${appState.totalStudyMinutes}분', 'label': '총 학습 시간'},
      {'icon': Icons.play_circle_outline_rounded, 'color': AppColors.math, 'value': '${appState.completedLectures}개', 'label': '완료 강의'},
      {'icon': Icons.bookmark_rounded, 'color': AppColors.social, 'value': '${appState.favoriteIds.length}개', 'label': '즐겨찾기'},
    ];

    return GridView.count(
      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
      childAspectRatio: 1.8, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      children: stats.map((s) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: (s['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(s['value'] as String,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            Text(s['label'] as String,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ]),
      )).toList(),
    );
  }

  Widget _buildStatChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Color _subjectColor(String subject) {
    switch (subject) {
      case '국어': return AppColors.korean;
      case '영어': return AppColors.english;
      case '수학': return AppColors.math;
      case '과학': return AppColors.science;
      case '사회': return AppColors.social;
      default: return AppColors.other;
    }
  }
}
