import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../services/content_service.dart';
import '../../theme/app_theme.dart';

class NoticeItem {
  final String id;
  final String category;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isPinned;
  final bool isNew;

  const NoticeItem({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.createdAt,
    this.isPinned = false,
    this.isNew = false,
  });

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return '방금 전';
      return '${diff.inHours}시간 전';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${createdAt.month}월 ${createdAt.day}일';
    }
  }
}

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = '전체';

  final List<String> _categories = ['전체', '공지', '업데이트', '이벤트', '정책'];

  final List<NoticeItem> _notices = [
    NoticeItem(
      id: 'n1',
      category: '공지',
      title: '🎉 Asome Tutor 앱 정식 출시 안내',
      content:
          '안녕하세요, Asome Tutor입니다!\n\nAsome Tutor에서 새롭게 리뉴얼된 Asome Tutor 앱이 드디어 정식 출시되었습니다.\n\nAsome Tutor는 바쁜 일상 속에서도 하루 단 2분으로 핵심 개념을 이해할 수 있도록 설계된 학습 플랫폼입니다.\n\n주요 변경사항:\n• 전면 리뉴얼된 UI/UX\n• 2분 핵심 강의 전면 도입\n• 노트 필기 기능 강화\n• 전문가 상담 시스템 개선\n\n더 나은 학습 경험을 위해 최선을 다하겠습니다. 감사합니다!',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isPinned: true,
      isNew: true,
    ),
    NoticeItem(
      id: 'n2',
      category: '이벤트',
      title: '🎁 출시 기념 프리미엄 30일 무료 이벤트',
      content:
          'Asome Tutor 출시를 기념하여 특별 이벤트를 진행합니다!\n\n■ 이벤트 기간\n2024년 12월 1일 ~ 2024년 12월 31일\n\n■ 이벤트 내용\n신규 가입 회원 전원에게 프리미엄 30일 무료 제공\n\n■ 참여 방법\n1. Asome Tutor 앱 다운로드\n2. 회원가입\n3. 자동으로 프리미엄 30일 적용!\n\n이 기회를 놓치지 마세요. 친구에게도 알려주세요! 😊',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      isPinned: true,
      isNew: true,
    ),
    NoticeItem(
      id: 'n3',
      category: '업데이트',
      title: '📱 버전 1.0.1 업데이트 안내',
      content:
          'Asome Tutor 버전 1.0.1이 업데이트 되었습니다.\n\n■ 개선사항\n• 강의 재생 속도 조절 안정화\n• 노트 저장 버그 수정\n• 검색 속도 개선\n• 일부 기기에서 발생하던 앱 종료 문제 해결\n\n■ 추가 기능\n• 강의 다운로드 예약 기능 (추후 업데이트 예정)\n• 학습 통계 화면 UI 개선\n\n항상 더 나은 Asome Tutor를 위해 노력하겠습니다!',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isNew: true,
    ),
    NoticeItem(
      id: 'n4',
      category: '공지',
      title: '📚 2025 수능 대비 특별 강의 오픈',
      content:
          '2025 수능을 준비하는 수험생 여러분을 위한 특별 강의 시리즈가 오픈되었습니다.\n\n■ 제공 과목\n• 수학 (공통, 미적분, 확률과 통계)\n• 과학탐구 (물리, 화학, 생명과학, 지구과학)\n\n■ 강의 특징\n• 개념별 2분 핵심 요약\n• 빈출 문제 유형 분석\n• 국내 최고 강사진 참여\n\n합격의 그날까지 Asome Tutor가 함께하겠습니다! 파이팅!',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    NoticeItem(
      id: 'n5',
      category: '이벤트',
      title: '🏆 학습 챌린지: 7일 연속 달성 이벤트',
      content:
          '7일 연속 학습 챌린지에 도전해보세요!\n\n■ 참여 조건\n7일 연속으로 1개 이상의 강의를 수강\n\n■ 보상\n• 7일 달성: 포인트 1,000점\n• 14일 달성: 포인트 3,000점 + 프리미엄 7일 연장\n• 30일 달성: 포인트 10,000점 + 프리미엄 30일 연장\n\n■ 주의사항\n• 하루에 최소 1강의 이상 수강해야 카운트 됩니다\n• 중간에 끊기면 카운트가 초기화됩니다\n\n지금 바로 시작하세요! 🔥',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    NoticeItem(
      id: 'n6',
      category: '정책',
      title: '📋 이용약관 및 개인정보처리방침 개정 안내',
      content:
          'Asome Tutor 서비스 이용약관 및 개인정보처리방침이 일부 개정됩니다.\n\n■ 시행일\n2024년 12월 15일부터\n\n■ 주요 변경 내용\n\n[이용약관]\n• 제7조 (서비스 이용시간) 내용 추가\n• 제12조 (저작권) 관련 조항 명확화\n\n[개인정보처리방침]\n• 개인정보 보유기간 명시 강화\n• 제3자 제공 관련 내용 정비\n\n자세한 내용은 앱 내 설정 > 이용약관에서 확인하실 수 있습니다.\n궁금하신 점은 고객센터로 문의해 주세요.',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    NoticeItem(
      id: 'n7',
      category: '공지',
      title: '🛠️ 서버 점검 안내 (완료)',
      content:
          '안정적인 서비스 제공을 위한 서버 점검이 완료되었습니다.\n\n■ 점검 일시\n2024년 11월 20일 02:00 ~ 04:00\n\n■ 점검 내용\n• 데이터베이스 최적화\n• 보안 패치 적용\n• CDN 서버 증설\n\n점검 시간 동안 불편을 드린 점 사과드립니다. 앞으로도 안정적인 서비스를 위해 최선을 다하겠습니다.',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
  ];

  List<NoticeItem> get _filteredNotices {
    if (_selectedCategory == '전체') return _notices;
    return _notices.where((n) => n.category == _selectedCategory).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case '공지':
        return AppColors.primary;
      case '업데이트':
        return AppColors.success;
      case '이벤트':
        return AppColors.accent;
      case '정책':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('공지사항', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '공지사항'), Tab(text: '이벤트')],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          dividerColor: AppColors.divider,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNoticeTab(),
          _buildEventTab(),
        ],
      ),
    );
  }

  Widget _buildNoticeTab() {
    return Column(
      children: [
        // 카테고리 필터
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat,
                        style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400)),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat),
                    selectedColor: AppColors.primary.withValues(alpha: 0.12),
                    checkmarkColor: AppColors.primary,
                    backgroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 0),
        // 공지 목록
        Expanded(
          child: _filteredNotices.isEmpty
              ? const Center(
                  child: Text('해당 카테고리의 공지사항이 없습니다',
                      style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  itemCount: _filteredNotices.length,
                  itemBuilder: (_, i) =>
                      _buildNoticeCard(_filteredNotices[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildNoticeCard(NoticeItem notice) {
    return GestureDetector(
      onTap: () => _showNoticeDetail(notice),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: notice.isPinned
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
              : null,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (notice.isPinned) ...[
                  const Icon(Icons.push_pin_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _categoryColor(notice.category)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(notice.category,
                      style: TextStyle(
                          fontSize: 11,
                          color: _categoryColor(notice.category),
                          fontWeight: FontWeight.w700)),
                ),
                if (notice.isNew) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('NEW',
                        style: TextStyle(
                            fontSize: 9,
                            color: AppColors.error,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
                const Spacer(),
                Text(notice.timeAgo,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint)),
              ]),
              const SizedBox(height: 8),
              Text(notice.title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: notice.isPinned
                          ? AppColors.primary
                          : AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(notice.content,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoticeDetail(NoticeItem notice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _NoticeDetailScreen(notice: notice),
      ),
    );
  }

  Widget _buildEventTab() {
    final noticeEvents = _notices.where((n) => n.category == '이벤트').toList();
    // Asome Tutor 행사/이벤트 (content_service에서 isAppEvent == true인 항목)
    final appEvents = ContentService().getScheduleEvents()
        .where((e) => e.isAppEvent).toList();

    if (noticeEvents.isEmpty && appEvents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration_outlined, size: 64, color: AppColors.textHint),
            SizedBox(height: 14),
            Text('진행 중인 이벤트가 없습니다',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            SizedBox(height: 6),
            Text('새로운 이벤트를 기대해주세요!',
                style: TextStyle(fontSize: 13, color: AppColors.textHint)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      children: [
        // 공지 이벤트 카드
        ...noticeEvents.map((e) => _buildEventCard(e)),
        // Asome Tutor 행사/이벤트 카드
        if (appEvents.isNotEmpty) ...[
          if (noticeEvents.isNotEmpty) const SizedBox(height: 8),
          ...appEvents.map((e) => _buildAppEventCard(e)),
        ],
      ],
    );
  }

  String _weekdayText(int weekday) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[weekday - 1];
  }

  Widget _buildAppEventCard(ScheduleEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [event.color, event.color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(
            color: event.color.withValues(alpha: 0.3),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 헤더
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20)),
                child: const Text('어썸튜터 이벤트',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              Text(event.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            ])),
            const Icon(Icons.celebration_rounded, color: Colors.white, size: 40),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: 6),
              Text(
                '${event.dateTime.month}월 ${event.dateTime.day}일 (${_weekdayText(event.dateTime.weekday)}) ${event.dateTime.hour.toString().padLeft(2, '0')}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
            const SizedBox(height: 6),
            if (event.content.isNotEmpty)
              Text(event.content,
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85), height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }

  Widget _buildEventCard(NoticeItem event) {
    return GestureDetector(
      onTap: () => _showNoticeDetail(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withValues(alpha: 0.85),
              AppColors.primary.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.celebration_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 6),
                const Text('EVENT',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5)),
                const Spacer(),
                Text(event.timeAgo,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11)),
              ]),
              const SizedBox(height: 10),
              Text(event.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(event.content,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('자세히 보기',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 14),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 공지 상세 화면 ────────────────────────────────────
class _NoticeDetailScreen extends StatelessWidget {
  final NoticeItem notice;

  const _NoticeDetailScreen({required this.notice});

  Color _categoryColor(String cat) {
    switch (cat) {
      case '공지':
        return AppColors.primary;
      case '업데이트':
        return AppColors.success;
      case '이벤트':
        return AppColors.accent;
      case '정책':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('공지사항 상세',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (notice.isPinned) ...[
                      const Icon(Icons.push_pin_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            _categoryColor(notice.category).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(notice.category,
                          style: TextStyle(
                              fontSize: 12,
                              color: _categoryColor(notice.category),
                              fontWeight: FontWeight.w700)),
                    ),
                    if (notice.isNew) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('NEW',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.error,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                    const Spacer(),
                    Text(notice.timeAgo,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textHint)),
                  ]),
                  const SizedBox(height: 12),
                  Text(notice.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 본문 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Text(
                notice.content,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.8),
              ),
            ),
            const SizedBox(height: 20),
            // 하단 공유/목록 버튼
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('공유'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('공유 기능은 앱에서 지원됩니다')));
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.list_rounded, size: 16),
                  label: const Text('목록으로'),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
