import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lecture.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
///  통합 강의 카드 — 모든 화면에서 동일한 형태 유지
///
///  핵심 설계 원칙
///  ① CachedNetworkImage 사용 → ModalBottomSheet 포함 어디서나 썸네일 안정 표시
///  ② effectiveThumbnailUrl 로 URL 자동 처리 (Drive/YouTube/NAS)
///  ③ AppState 의존성 최소화 — onTagTap 콜백 우선 사용
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class LectureCard extends StatelessWidget {
  final Lecture lecture;
  final VoidCallback? onTap;
  final void Function(String tag)? onTagTap;
  final bool isHorizontal; // 하위 호환성용 (무시됨)

  const LectureCard({
    super.key,
    required this.lecture,
    this.onTap,
    this.onTagTap,
    this.isHorizontal = false,
  });

  // ── 색상 헬퍼 ─────────────────────────────────────────
  Color _subjectColor() {
    switch (lecture.subject) {
      case '수학':     return AppColors.math;
      case '과학':     return AppColors.science;
      case '공통과학': return AppColors.commonScience;
      case '물리':     return AppColors.physics;
      case '화학':     return AppColors.chemistry;
      case '생명과학': return AppColors.biology;
      case '지구과학': return AppColors.earth;
      case '국어':     return AppColors.korean;
      case '영어':     return AppColors.english;
      default:         return AppColors.other;
    }
  }

  Color _gradeColor() {
    switch (lecture.grade) {
      case 'elementary': return AppColors.elementary;
      case 'middle':     return AppColors.middle;
      default:           return AppColors.high;
    }
  }

  // ── 기본 썸네일 asset ─────────────────────────────────
  String _defaultThumbAsset() {
    switch (lecture.subject) {
      case '과학':
      case '공통과학':
      case '물리':
      case '화학':
      case '생명과학':
      case '지구과학':
        return 'assets/images/thumb_science_default.jpg';
      default:
        return 'assets/images/thumb_math_default.jpg';
    }
  }

  // ── 빌드 ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final subjectColor = _subjectColor();

    // AppState: 태그 탭 처리에만 선택적 사용 (ModalBottomSheet 등 별도 Route에서도 동작)
    AppState? appState;
    try {
      appState = context.read<AppState>();
    } catch (_) {
      appState = null;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: subjectColor.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── 상단: 썸네일 + 강의 정보 + 재생버튼 ──
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 썸네일 — CachedNetworkImage로 안정적 표시
                    _buildThumbnail(105, 78, subjectColor),

                    // 강의 정보
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              lecture.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            _buildSeriesRow(),
                            const SizedBox(height: 4),
                            _buildMetaRow(),
                          ],
                        ),
                      ),
                    ),

                    // 재생 버튼
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 10, 0),
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: subjectColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: subjectColor, size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── 해시태그 영역 ───────────────────────
              if (lecture.hashtags.isNotEmpty)
                _HashtagArea(
                  tags: lecture.hashtags,
                  color: subjectColor,
                  onTagTap: (tag) {
                    if (onTagTap != null) {
                      onTagTap!(tag);
                    } else if (appState != null) {
                      appState.setSearchQuery(tag);
                      appState.setNavIndex(3);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 시리즈명 행 ─────────────────────────────────────
  Widget _buildSeriesRow() {
    // 시리즈가 있으면 시리즈명, 없으면 "시리즈" 라고 표기 (520 규칙)
    final displayText = lecture.series.isNotEmpty ? lecture.series : '시리즈';
    return Row(
      children: [
        const Icon(Icons.playlist_play_rounded, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            displayText,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── 메타 정보 행 (2행: 배지행 + 강사명행) ───────────
  Widget _buildMetaRow() {
    final gc = _gradeColor();
    final sc = _subjectColor();
    final gradeLabel = lecture.gradeText;
    final yearLabel = lecture.gradeYear.isEmpty || lecture.gradeYear == 'All'
        ? 'All'
        : '${lecture.gradeYear}학년';
    const Color allBadgeColor = Color(0xFFF97316);

    // 520 규칙: 항상 배지 + 강사명을 한 줄에 표시
    return Row(
      children: [
        _badge(gradeLabel, gc),
        const SizedBox(width: 3),
        _badge(yearLabel, yearLabel == 'All' ? allBadgeColor : gc.withValues(alpha: 0.65)),
        const SizedBox(width: 3),
        _badge(lecture.subject, sc),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            lecture.instructor,
            style: const TextStyle(
              fontSize: 10.5, color: AppColors.textSecondary,
              fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
    ),
    child: Text(label,
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
  );

  // ── 썸네일 빌더 — CachedNetworkImage 사용 ──────────
  Widget _buildThumbnail(double w, double h, Color c) {
    final url = lecture.effectiveThumbnailUrl;
    final fallbackUrl = lecture.fallbackThumbnailUrl;

    Widget placeholder() => Container(
      width: w, height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.withValues(alpha: 0.15), c.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: c),
        ),
      ),
    );

    Widget fallbackWidget() => Image.asset(
      _defaultThumbAsset(),
      width: w, height: h, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: w, height: h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c.withValues(alpha: 0.25), c.withValues(alpha: 0.10)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(Icons.play_circle_outline_rounded,
            size: h * 0.42, color: c.withValues(alpha: 0.8)),
      ),
    );

    Widget thumb;

    if (url.isEmpty || url == 'nas_default' || url.contains('trycloudflare.com')) {
      thumb = fallbackWidget();
    } else {
      // CachedNetworkImage: 캐시 + 에러 폴백 자동 처리
      thumb = CachedNetworkImage(
        imageUrl: url,
        width: w, height: h,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder(),
        errorWidget: (_, __, ___) {
          // 1차 실패 → fallbackUrl 시도
          if (fallbackUrl.isNotEmpty && fallbackUrl != url) {
            return CachedNetworkImage(
              imageUrl: fallbackUrl,
              width: w, height: h, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => fallbackWidget(),
              placeholder: (_, __) => placeholder(),
            );
          }
          return fallbackWidget();
        },
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(13),
        bottomLeft: Radius.circular(13),
      ),
      child: Stack(
        children: [
          SizedBox(width: w, height: h, child: thumb),
          // 재생시간 배지
          Positioned(
            top: 5, right: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                lecture.durationText,
                style: const TextStyle(
                  color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  해시태그 영역 — 2줄 이하: Wrap / 3줄 이상: 가로 스크롤
// ═══════════════════════════════════════════════════════════
class _HashtagArea extends StatelessWidget {
  final List<String> tags;
  final Color color;
  final void Function(String tag) onTagTap;

  const _HashtagArea({
    required this.tags,
    required this.color,
    required this.onTagTap,
  });

  double _chipWidth(String tag) {
    final text = '#$tag';
    double w = 0;
    for (final ch in text.runes) {
      w += (ch > 0x2E7F) ? 9.0 : 6.0;
    }
    return w + 19;
  }

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    // 어썸튜터 스타일: 연보라 배경 + 진보라 텍스트 + 옅은 보라 테두리 (고정색)
    const tagBg    = Color(0xFFEAF6FF); // 미니튀터 동일 하늘색 배경
    const tagText  = Color(0xFF42A8F0); // 미니튀터 동일 스카이블루 텍스트
    const tagBorder= Color(0xFFD7E9F9); // 미니튀터 동일 연한 테두리

    Widget chip(String tag) => GestureDetector(
      onTap: () => onTagTap(tag),
      child: Container(
        margin: const EdgeInsets.only(right: 5, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: tagBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: tagBorder, width: 0.8),
        ),
        child: const Text(
          '',
          style: TextStyle(
            fontSize: 10,
            color: tagText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    // 실제 태그 텍스트 포함 chip
    Widget tagChip(String tag) => GestureDetector(
      onTap: () => onTagTap(tag),
      child: Container(
        margin: const EdgeInsets.only(right: 5, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: const BoxDecoration(
          color: tagBg,
          borderRadius: BorderRadius.all(Radius.circular(6)),
          border: Border.fromBorderSide(BorderSide(color: tagBorder, width: 0.8)),
        ),
        child: Text(
          '#$tag',
          style: const TextStyle(
            fontSize: 10,
            color: tagText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 0.8),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 5),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final avail = constraints.maxWidth;
          if (avail <= 0) {
            return Wrap(children: tags.map(tagChip).toList());
          }

          int lineCount = 1;
          double lineW = 0;
          for (final t in tags) {
            final cw = _chipWidth(t);
            if (lineW + cw > avail) {
              lineCount++;
              lineW = cw;
            } else {
              lineW += cw;
            }
          }

          if (lineCount <= 2) {
            return Wrap(children: tags.map(tagChip).toList());
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(children: tags.map(tagChip).toList()),
          );
        },
      ),
    );
  }
}
