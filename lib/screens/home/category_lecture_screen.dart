import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/lecture.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../lecture/lecture_player_screen.dart';
import '../../widgets/lecture_card.dart';

// ══════════════════════════════════════════════════════════════
// 과학 대분류 선택 화면 (중등 과학 + 고등 세분화 과목)
// ══════════════════════════════════════════════════════════════
class ScienceCategoryScreen extends StatelessWidget {
  const ScienceCategoryScreen({super.key});

  static const List<Map<String, dynamic>> _subjects = [
    {
      'label': '과학',
      'subtitle': '중등 과학',
      'grade': 'middle',
      'color': AppColors.science,
      'icon': Icons.science_rounded,
    },
    {
      'label': '공통과학',
      'subtitle': '고등 공통과학',
      'grade': 'high',
      'color': AppColors.commonScience,
      'icon': Icons.menu_book_rounded,
    },
    {
      'label': '물리',
      'subtitle': '고등 물리학',
      'grade': 'high',
      'color': AppColors.physics,
      'icon': Icons.electric_bolt_rounded,
    },
    {
      'label': '화학',
      'subtitle': '고등 화학',
      'grade': 'high',
      'color': AppColors.chemistry,
      'icon': Icons.biotech_rounded,
    },
    {
      'label': '생명과학',
      'subtitle': '고등 생명과학',
      'grade': 'high',
      'color': AppColors.biology,
      'icon': Icons.eco_rounded,
    },
    {
      'label': '지구과학',
      'subtitle': '고등 지구과학',
      'grade': 'high',
      'color': AppColors.earth,
      'icon': Icons.public_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final allLectures = appState.apiLectures;
    // 전체 과학 강의 수
    final totalScienceCount = allLectures.where((l) =>
        ['과학','공통과학','물리','화학','생명과학','지구과학'].contains(l.subject)).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('과학', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          const Text('🔬', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          const Text('강의', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        ]),
        titleSpacing: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // ── 배너 헤더
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(children: [
                // 아이콘 배지
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🔬', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('과학',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('중등 · 고등 세분화  |  총 ${totalScienceCount > 0 ? totalScienceCount : '?'}개',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('과목 선택 →',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // ── 과목 카드 그리드
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.55, // 충분한 높이 확보 → 이모지+과목명+설명 모두 표시
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final s = _subjects[i];
                  final color = s['color'] as Color;
                  final label = s['label'] as String;
                  final subtitle = s['subtitle'] as String;
                  final icon = s['icon'] as IconData;
                  final count = allLectures.where((l) => l.subject == label).length;

                  // 과목별 그라디언트 정의
                  final List<Color> gradColors;
                  final String emoji;
                  switch (label) {
                    case '과학':
                      gradColors = [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)];
                      emoji = '🔬';
                      break;
                    case '공통과학':
                      gradColors = [const Color(0xFF7C3AED), const Color(0xFF5B21B6)];
                      emoji = '📗';
                      break;
                    case '물리':
                      gradColors = [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)];
                      emoji = '⚡';
                      break;
                    case '화학':
                      gradColors = [const Color(0xFFF97316), const Color(0xFFEA580C)];
                      emoji = '🧪';
                      break;
                    case '생명과학':
                      gradColors = [const Color(0xFF10B981), const Color(0xFF059669)];
                      emoji = '🌿';
                      break;
                    case '지구과학':
                      gradColors = [const Color(0xFF06B6D4), const Color(0xFF0284C7)];
                      emoji = '🌍';
                      break;
                    default:
                      gradColors = [color, color.withValues(alpha: 0.7)];
                      emoji = '📚';
                  }

                  // 과목별 카드 배경 이미지 결정
                  String? cardImg;
                  switch (label) {
                    case '과학':       cardImg = 'assets/images/subjects/science_card.jpg'; break;
                    case '공통과학':   cardImg = 'assets/images/subjects/common_science_card.jpg'; break;
                    case '물리':       cardImg = 'assets/images/subjects/physics_card.jpg'; break;
                    case '화학':       cardImg = 'assets/images/subjects/chemistry_card.jpg'; break;
                    case '생명과학':   cardImg = 'assets/images/subjects/biology_card.jpg'; break;
                    case '지구과학':   cardImg = 'assets/images/subjects/earth_card.jpg'; break;
                    default:          cardImg = null;
                  }

                  // 과목별 배너 이미지 결정
                  String? bannerImg;
                  switch (label) {
                    case '과학':     bannerImg = 'assets/images/banners/banner_science.png'; break;
                    case '공통과학': bannerImg = 'assets/images/banners/banner_science.png'; break;
                    case '물리':     bannerImg = 'assets/images/banners/banner_science.png'; break;
                    case '화학':     bannerImg = 'assets/images/banners/banner_science.png'; break;
                    case '생명과학': bannerImg = 'assets/images/banners/banner_science.png'; break;
                    case '지구과학': bannerImg = 'assets/images/banners/banner_science.png'; break;
                    default: bannerImg = null;
                  }

                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CategoryLectureScreen(
                        subject: label,
                        primaryColor: gradColors[0],
                        secondaryColor: gradColors[1],
                        categoryIcon: icon,
                        bannerImagePath: bannerImg,
                      ),
                    )),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: gradColors[0].withValues(alpha: 0.38),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 배경 이미지
                            if (cardImg != null)
                              Image.asset(
                                cardImg,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: gradColors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: gradColors,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            // 어두운 오버레이 (텍스트 가독성)
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.15),
                                    Colors.black.withValues(alpha: 0.55),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            // 텍스트 콘텐츠
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // 상단: 이모지 + 강수 배지
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(emoji,
                                        style: const TextStyle(fontSize: 24)),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.35),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text('$count강',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800)),
                                      ),
                                    ],
                                  ),
                                  // 하단: 과목명 + 설명
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          height: 1.2,
                                          shadows: [
                                            Shadow(color: Colors.black54, blurRadius: 4),
                                          ],
                                        )),
                                      const SizedBox(height: 3),
                                      Text(subtitle,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.92),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          shadows: const [
                                            Shadow(color: Colors.black54, blurRadius: 4),
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: _subjects.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // ── 학습 가이드 섹션 (수학 메뉴 스타일 참고)
          SliverToBoxAdapter(child: _buildStudyGuideSection()),

          // ── 과목별 핵심 포인트 카드
          SliverToBoxAdapter(child: _buildSubjectHighlightsSection()),

          // ── 학습 TIP 카드
          SliverToBoxAdapter(child: _buildStudyTipsSection()),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  /// 학습 가이드 섹션 (과목 소개 & 학습 로드맵)
  Widget _buildStudyGuideSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Row(children: [
            const Text('📚', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('과학 학습 가이드',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              )),
          ]),
          const SizedBox(height: 12),
          // 학습 순서 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📖 추천 학습 순서',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  )),
                const SizedBox(height: 10),
                _buildStepRow('1단계', '과학 (중등)', '기초 개념 → 탐구 원리 정립', const Color(0xFF8B5CF6)),
                _buildStepRow('2단계', '물리 / 화학', '고등 핵심 과목 집중 학습', const Color(0xFF3B82F6)),
                _buildStepRow('3단계', '생명과학 / 지구과학', '선택 과목 심화 완성', const Color(0xFF10B981)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(String step, String subject, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(step,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              )),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  )),
                Text(desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 과목별 핵심 포인트 카드
  Widget _buildSubjectHighlightsSection() {
    final highlights = [
      {
        'emoji': '🔬',
        'subject': '과학 (중등)',
        'point': '지구·생명·물질·에너지 4개 영역 통합 학습',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'emoji': '⚡',
        'subject': '물리',
        'point': '역학·전기·파동·광학 개념과 수식 이해',
        'color': const Color(0xFF3B82F6),
      },
      {
        'emoji': '🧪',
        'subject': '화학',
        'point': '원자 구조·화학 결합·반응·평형 마스터',
        'color': const Color(0xFFF97316),
      },
      {
        'emoji': '🌿',
        'subject': '생명과학',
        'point': '세포·유전·진화·생태계 체계적 이해',
        'color': const Color(0xFF10B981),
      },
      {
        'emoji': '🌍',
        'subject': '지구과학',
        'point': '지구 내부·대기·해양·천문 핵심 개념',
        'color': const Color(0xFF06B6D4),
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('✨', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('과목별 핵심 포인트',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              )),
          ]),
          const SizedBox(height: 12),
          ...highlights.map((h) {
            final color = h['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withValues(alpha: 0.20),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(h['emoji'] as String,
                    style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h['subject'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color,
                        )),
                      const SizedBox(height: 2),
                      Text(h['point'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        )),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.5),
                  size: 20),
              ]),
            );
          }),
        ],
      ),
    );
  }

  /// 학습 TIP 카드 (수학 메뉴 하단 스타일)
  Widget _buildStudyTipsSection() {
    final tips = [
      {
        'icon': Icons.lightbulb_rounded,
        'color': const Color(0xFFF59E0B),
        'title': '개념 우선 이해',
        'desc': '암기보다 원리와 개념 이해가 핵심입니다.',
      },
      {
        'icon': Icons.repeat_rounded,
        'color': const Color(0xFF3B82F6),
        'title': '두번설명 강의 활용',
        'desc': '어려운 단원은 두번설명으로 완전 정복하세요.',
      },
      {
        'icon': Icons.quiz_rounded,
        'color': const Color(0xFF10B981),
        'title': '문제 적용 연습',
        'desc': '개념 후 관련 문제 풀이로 실력을 다지세요.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('💡', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('학습 TIP',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              )),
          ]),
          const SizedBox(height: 12),
          Row(
            children: tips.map((t) {
              final color = t['color'] as Color;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(t['icon'] as IconData,
                        color: Colors.white,
                        size: 22),
                      const SizedBox(height: 8),
                      Text(t['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        )),
                      const SizedBox(height: 4),
                      Text(t['desc'] as String,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10,
                          height: 1.3,
                        )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class CategoryLectureScreen extends StatefulWidget {
  final String subject;        // '수학', '과학' 등
  final Color primaryColor;
  final Color secondaryColor;
  final IconData categoryIcon;
  // 상단 배너 이미지 경로 (선택사항)
  final String? bannerImagePath;

  const CategoryLectureScreen({
    super.key,
    required this.subject,
    required this.primaryColor,
    required this.secondaryColor,
    required this.categoryIcon,
    this.bannerImagePath,
  });

  @override
  State<CategoryLectureScreen> createState() => _CategoryLectureScreenState();
}

class _CategoryLectureScreenState extends State<CategoryLectureScreen> {
  String _selectedGrade = '전체';
  String _sortBy = '최신순';

  final List<String> _grades = ['전체', '예비중', '중등', '고등'];
  final List<String> _sorts = ['최신순', '인기순', '시리즈순'];

  List<Lecture> _getFilteredLectures(List<Lecture> all) {
    var list = all.where((l) => l.subject == widget.subject).toList();

    // 학년 필터
    if (_selectedGrade != '전체') {
      final gradeKey = _selectedGrade == '예비중' ? 'elementary'
          : _selectedGrade == '중등' ? 'middle' : 'high';
      list = list.where((l) => l.grade == gradeKey).toList();
    }

    // 정렬
    switch (_sortBy) {
      case '인기순':
        list.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case '시리즈순':
        list.sort((a, b) {
          final sc = a.series.compareTo(b.series);
          return sc != 0 ? sc : a.lectureNumber.compareTo(b.lectureNumber);
        });
        break;
      default: // 최신순
        list.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lectures = _getFilteredLectures(appState.apiLectures);

    // 시리즈별 그룹 (시리즈순 정렬일 때)
    final Map<String, List<Lecture>> seriesMap = {};
    if (_sortBy == '시리즈순') {
      for (final l in lectures) {
        final key = l.series.isNotEmpty ? l.series : '기타';
        seriesMap.putIfAbsent(key, () => []).add(l);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // ── 헤더 SliverAppBar
          SliverAppBar(
            expandedHeight: widget.bannerImagePath != null ? 160.0 : 0.0,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: widget.bannerImagePath != null
                ? FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 배너 이미지
                        Image.asset(
                          widget.bannerImagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [widget.primaryColor, widget.secondaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                        // 어두운 그라디언트 오버레이
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.black.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                        ),
                        // 하단 텍스트
                        Positioned(
                          left: 16, right: 16, bottom: 14,
                          child: Row(children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(widget.categoryIcon,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(widget.subject,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                                  )),
                                Text('총 ${lectures.length}개 강의',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  )),
                              ],
                            )),
                          ]),
                        ),
                      ],
                    ),
                  )
                : null,
            title: widget.bannerImagePath == null
                ? Row(children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(widget.categoryIcon,
                          color: widget.primaryColor, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.subject,
                      style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w800,
                          fontSize: 17),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '총 ${lectures.length}개',
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w400,
                          fontSize: 12),
                    ),
                  ])
                : null,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1,
                  color: widget.bannerImagePath != null
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey.shade200),
            ),
          ),

          // ── 필터 바
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterBarDelegate(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 학년 필터
                    Row(children: [
                      ..._grades.map((g) {
                        final sel = _selectedGrade == g;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedGrade = g),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: sel ? widget.primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel ? widget.primaryColor : const Color(0xFFDDDDDD),
                              ),
                            ),
                            child: Text(g,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : const Color(0xFF666666),
                              )),
                          ),
                        );
                      }),
                      const Spacer(),
                      // 정렬 드롭다운
                      GestureDetector(
                        onTap: () => _showSortSheet(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFDDDDDD)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(children: [
                            Text(_sortBy,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                          ]),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              height: 56,
            ),
          ),

          // ── 강의 목록
          if (lectures.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(widget.categoryIcon,
                    size: 56,
                    color: widget.primaryColor.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    '$_selectedGrade ${widget.subject} 강의가 없습니다',
                    style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedGrade = '전체'),
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                    label: const Text('필터 초기화'),
                  ),
                ]),
              ),
            )
          else if (_sortBy == '시리즈순')
            // 시리즈별 섹션
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, idx) {
                  final entries = seriesMap.entries.toList();
                  final entry = entries[idx];
                  return _buildSeriesSection(entry.key, entry.value);
                },
                childCount: seriesMap.length,
              ),
            )
          else
            // 일반 목록
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final lec = lectures[i];
                    return LectureCard(
                      lecture: lec,
                      onTap: () => _openLecture(lec),
                    );
                  },
                  childCount: lectures.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeriesSection(String seriesName, List<Lecture> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 시리즈 헤더
      Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: widget.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.primaryColor.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(Icons.collections_bookmark_rounded, size: 16, color: widget.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              seriesName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: widget.primaryColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: widget.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${items.length}강',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
      // 강의 목록
      ...items.map((lec) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LectureCard(
          lecture: lec,
          onTap: () => _openLecture(lec),
        ),
      )),
      const SizedBox(height: 8),
    ]);
  }

  void _openLecture(Lecture lec) {
    context.read<AppState>().addRecentView(lec.id);

    // 시리즈순 정렬 중이면 같은 시리즈 강의 목록을 자동재생 리스트로 전달
    List<Lecture>? autoList;
    int autoIdx = 0;

    if (_sortBy == '시리즈순' && lec.series.isNotEmpty) {
      final appState = context.read<AppState>();
      final all = _getFilteredLectures(appState.apiLectures);
      // 같은 시리즈의 강의만 추출 (lectureNumber 순)
      final seriesLectures = all
          .where((l) => l.series == lec.series)
          .toList()
        ..sort((a, b) => a.lectureNumber.compareTo(b.lectureNumber));
      if (seriesLectures.length > 1) {
        autoList = seriesLectures;
        autoIdx = seriesLectures.indexWhere((l) => l.id == lec.id);
        if (autoIdx < 0) autoIdx = 0;
      }
    } else if (_sortBy != '시리즈순') {
      // 일반 목록에서도 현재 필터된 전체 목록을 자동재생 리스트로 제공
      final appState = context.read<AppState>();
      final all = _getFilteredLectures(appState.apiLectures);
      if (all.length > 1) {
        autoList = all;
        autoIdx = all.indexWhere((l) => l.id == lec.id);
        if (autoIdx < 0) autoIdx = 0;
      }
    }

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => LecturePlayerScreen(
        lecture: lec,
        autoPlayList: autoList,
        autoPlayIndex: autoIdx,
      ),
    ));
  }

  void _showSortSheet() {
    // 정렬 옵션별 아이콘
    final Map<String, IconData> _sortIcons = {
      '최신순': Icons.schedule_rounded,
      '인기순': Icons.local_fire_department_rounded,
      '시리즈순': Icons.view_list_rounded,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 드래그 핸들
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // 제목
                  Row(children: [
                    Icon(Icons.sort_rounded, size: 18, color: widget.primaryColor),
                    const SizedBox(width: 6),
                    Text('정렬',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      )),
                  ]),
                  const SizedBox(height: 8),
                  // 구분선
                  Divider(color: Colors.grey[100], thickness: 1, height: 1),
                  const SizedBox(height: 4),
                  // 정렬 옵션 목록
                  ..._sorts.map((s) {
                    final bool selected = _sortBy == s;
                    return InkWell(
                      onTap: () {
                        setState(() => _sortBy = s);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? widget.primaryColor.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: selected
                                  ? widget.primaryColor.withValues(alpha: 0.15)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _sortIcons[s] ?? Icons.sort_rounded,
                              size: 17,
                              color: selected ? widget.primaryColor : Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(s,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                color: selected ? widget.primaryColor : Colors.grey[800],
                              )),
                          ),
                          if (selected)
                            Icon(Icons.check_circle_rounded,
                              size: 18, color: widget.primaryColor),
                        ]),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── SliverPersistentHeaderDelegate ─────────────────────────
class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const _FilterBarDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: overlapsContent ? 2 : 0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_FilterBarDelegate old) => old.child != child;
}
