import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lecture.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class LectureCard extends StatelessWidget {
  final Lecture lecture;
  final VoidCallback? onTap;
  final bool isHorizontal;

  const LectureCard({
    super.key,
    required this.lecture,
    this.onTap,
    this.isHorizontal = false,
  });

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

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'elementary': return AppColors.elementary;
      case 'middle': return AppColors.middle;
      default: return AppColors.high;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isFav = appState.isFavorite(lecture.id);

    if (isHorizontal) return _buildHorizontalCard(context, isFav, appState);
    return _buildVerticalCard(context, isFav, appState);
  }

  Widget _buildVerticalCard(BuildContext context, bool isFav, AppState appState) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Image.network(lecture.thumbnailUrl, width: 200, height: 112,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 200, height: 112,
                      color: _subjectColor(lecture.subject).withValues(alpha: 0.2),
                      child: Icon(Icons.play_circle_outline, size: 40, color: _subjectColor(lecture.subject)),
                    )),
                  Positioned(bottom: 6, right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(6)),
                      child: Text(lecture.durationText, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    )),
                  Positioned(top: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: _subjectColor(lecture.subject), borderRadius: BorderRadius.circular(6)),
                      child: Text(lecture.subject, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    )),
                  if (lecture.lectureType != 'concept')
                    Positioned(top: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(6)),
                        child: Text(lecture.lectureTypeText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      )),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lecture.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: _gradeColor(lecture.grade).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(lecture.gradeText, style: TextStyle(fontSize: 10, color: _gradeColor(lecture.grade), fontWeight: FontWeight.w600))),
                    const SizedBox(width: 4),
                    Text(lecture.instructor, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFBBF24)),
                    const SizedBox(width: 2),
                    Text(lecture.rating.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(width: 8),
                    const Icon(Icons.visibility_outlined, size: 13, color: AppColors.textHint),
                    const SizedBox(width: 2),
                    Text(lecture.viewCountText, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => appState.toggleFavorite(lecture.id),
                      child: Icon(isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        size: 18, color: isFav ? AppColors.primary : AppColors.textHint),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context, bool isFav, AppState appState) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Stack(
                children: [
                  Image.network(lecture.thumbnailUrl, width: 120, height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 120, height: 80,
                      color: _subjectColor(lecture.subject).withValues(alpha: 0.2),
                      child: Icon(Icons.play_circle_outline, color: _subjectColor(lecture.subject)),
                    )),
                  Positioned(bottom: 4, right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(4)),
                      child: Text(lecture.durationText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    )),
                  Positioned(top: 4, left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: _subjectColor(lecture.subject), borderRadius: BorderRadius.circular(4)),
                      child: Text(lecture.subject, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                    )),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lecture.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(lecture.instructor, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFBBF24)),
                      Text(' ${lecture.rating}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      const Icon(Icons.visibility_outlined, size: 12, color: AppColors.textHint),
                      Text(' ${lecture.viewCountText}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => appState.toggleFavorite(lecture.id),
                        child: Icon(isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          size: 18, color: isFav ? AppColors.primary : AppColors.textHint),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
