import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/instructor.dart';
import '../../services/app_state.dart';
import '../../services/data_service.dart';
import '../../services/translations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lecture_card.dart';
import '../lecture/lecture_player_screen.dart';

class InstructorScreen extends StatelessWidget {
  const InstructorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    final dataService = DataService();
    final allInstructors = dataService.getAllInstructors();
    final gradeMap = {'elementary': T('grade_elementary'), 'middle': T('grade_middle'), 'high': T('grade_high')};

    final filtered = allInstructors
        .where((i) => i.grade == appState.instructorGrade)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(T('instructor_by'), style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Container(
            color: Colors.white,
            child: Column(children: [
              Row(children: ['elementary', 'middle', 'high'].map((g) =>
                Expanded(child: GestureDetector(
                  onTap: () => appState.setInstructorGrade(g),
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
            ]),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? Center(child: Text(T('no_lectures'), style: const TextStyle(color: AppColors.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _buildInstructorCard(context, filtered[i], dataService),
            ),
    );
  }

  Widget _buildInstructorCard(BuildContext context, Instructor instructor, DataService dataService) {
    final lectures = dataService.getLecturesBySubject(instructor.subject)
        .where((l) => l.instructor == instructor.name)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 강사 프로필
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.background,
              backgroundImage: NetworkImage(instructor.profileImageUrl),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(instructor.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(instructor.subject, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 4),
              Text(instructor.introduction,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFBBF24)),
                Text(' ${instructor.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                const Icon(Icons.play_lesson_outlined, size: 14, color: AppColors.textHint),
                Text(' 강의 ${instructor.lectureCount}개', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 12),
                const Icon(Icons.people_outlined, size: 14, color: AppColors.textHint),
                Text(' ${_formatCount(instructor.followerCount)}명', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ])),
            // 팔로우 버튼
            OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${instructor.name} 강사를 팔로우했습니다!'))),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: const Text('팔로우', style: TextStyle(fontSize: 12)),
            ),
          ]),
        ),
        // 시리즈 목록
        if (instructor.series.isNotEmpty) ...[
          const Divider(height: 0),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: const Text('시리즈', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
          SizedBox(
            height: 36,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              children: instructor.series.map((s) => Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider)),
                child: Text(s, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
              )).toList()),
          ),
        ],
        // 강의 목록 (최대 2개 미리보기)
        if (lectures.isNotEmpty) ...[
          const Divider(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(children: [
              Text('강의 ${lectures.length}개', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(onPressed: () => _openAllLectures(context, instructor, lectures),
                child: const Text('전체보기', style: TextStyle(fontSize: 12))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: lectures.take(2).map((l) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LectureCard(lecture: l, isHorizontal: true,
                  onTap: () {
                    context.read<AppState>().addRecentView(l.id);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => LecturePlayerScreen(lecture: l)));
                  }),
              )
            ).toList()),
          ),
        ],
      ]),
    );
  }

  void _openAllLectures(BuildContext context, Instructor instructor, lectures) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            Text('${instructor.name} 강사의 강의', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Expanded(child: ListView.builder(
              controller: scrollCtrl,
              itemCount: lectures.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LectureCard(lecture: lectures[i], isHorizontal: true,
                  onTap: () {
                    context.read<AppState>().addRecentView(lectures[i].id);
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => LecturePlayerScreen(lecture: lectures[i])));
                  }),
              ),
            )),
          ]),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}만';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}천';
    return count.toString();
  }
}
