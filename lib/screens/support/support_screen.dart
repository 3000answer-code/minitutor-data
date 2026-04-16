import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../services/content_service.dart';
import '../../theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<FaqItem> _faqItems;
  List<Inquiry> _inquiries = [];
  String _selectedFaqCategory = '전체';

  final List<String> _faqCategories = ['전체', '이용방법', '결제/이용권', '계정/회원', '강의', '기술/오류'];
  final List<String> _inquiryCategories = ['이용방법', '장애/오류', '결제', '강의 요청', '기타'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _faqItems = ContentService().getFaqItems();
    _inquiries = ContentService().getMyInquiries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<FaqItem> get _filteredFaq => _selectedFaqCategory == '전체'
      ? _faqItems
      : _faqItems.where((f) => f.category == _selectedFaqCategory).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('고객센터', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '자주 묻는 질문'), Tab(text: '1:1 문의')],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          dividerColor: AppColors.divider,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFaqTab(), _buildInquiryTab()],
      ),
    );
  }

  // ── FAQ 탭 ────────────────────────────────────────
  Widget _buildFaqTab() {
    return Column(children: [
      // 카테고리 필터
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _faqCategories.map((cat) {
              final isSelected = _selectedFaqCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat, style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedFaqCategory = cat),
                  selectedColor: AppColors.primary.withValues(alpha: 0.12),
                  checkmarkColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      const Divider(height: 0),
      // FAQ 리스트
      Expanded(
        child: _filteredFaq.isEmpty
            ? const Center(child: Text('해당 카테고리의 FAQ가 없습니다', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                itemCount: _filteredFaq.length,
                itemBuilder: (_, i) => _buildFaqCard(_filteredFaq[i]),
              ),
      ),
    ]);
  }

  Widget _buildFaqCard(FaqItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          key: PageStorageKey(faq.id),
          initiallyExpanded: faq.isExpanded,
          onExpansionChanged: (v) => setState(() => faq.isExpanded = v),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
            child: const Center(
              child: Text('Q', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary))),
          ),
          title: Text(faq.question,
            style: TextStyle(
              fontSize: 13,
              fontWeight: faq.isExpanded ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textPrimary)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(4)),
              child: Text(faq.category,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ),
          ),
          trailing: AnimatedRotation(
            turns: faq.isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          ),
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: const Center(
                      child: Text('A', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.accent))),
                  ),
                  const SizedBox(width: 8),
                  const Text('답변', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
                ]),
                const SizedBox(height: 8),
                Text(faq.answer,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.7)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1:1 문의 탭 ──────────────────────────────────
  Widget _buildInquiryTab() {
    return Column(children: [
      // 문의 작성 버튼
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('문의 작성하기'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          onPressed: _showInquirySheet,
        ),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Row(children: [
          Icon(Icons.access_time_rounded, size: 13, color: AppColors.textHint),
          SizedBox(width: 4),
          Text('평균 답변 시간: 영업일 기준 1~2일',
            style: TextStyle(fontSize: 12, color: AppColors.textHint)),
        ]),
      ),
      const Divider(height: 0),
      // 문의 목록
      Expanded(
        child: _inquiries.isEmpty
            ? _buildEmptyInquiry()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                itemCount: _inquiries.length,
                itemBuilder: (_, i) => _buildInquiryCard(_inquiries[i]),
              ),
      ),
    ]);
  }

  // ── 문의 삭제 ───────────────────────────────────
  void _deleteInquiry(Inquiry inquiry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('문의 삭제', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('이 문의를 삭제하시겠습니까?\n삭제된 문의는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _inquiries.removeWhere((q) => q.id == inquiry.id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('문의가 삭제되었습니다.')));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryCard(Inquiry inquiry) {
    return GestureDetector(
      onTap: () => _showInquiryDetail(inquiry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6)),
              child: Text(inquiry.category,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: inquiry.isAnswered ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(inquiry.isAnswered ? Icons.check_circle_rounded : Icons.schedule_rounded,
                  size: 11, color: inquiry.isAnswered ? AppColors.success : AppColors.warning),
                const SizedBox(width: 3),
                Text(inquiry.isAnswered ? '답변완료' : '답변대기',
                  style: TextStyle(fontSize: 10,
                    color: inquiry.isAnswered ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w700)),
              ]),
            ),
            // 답변대기 상태만 삭제 버튼 표시
            if (!inquiry.isAnswered) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _deleteInquiry(inquiry),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
<<<<<<< Updated upstream
                  child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
=======
                  child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
>>>>>>> Stashed changes
                ),
              ),
            ],
          ]),
          const SizedBox(height: 8),
          Text(inquiry.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(inquiry.content,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(inquiry.timeAgo, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        ]),
      ),
    );
  }

  Widget _buildEmptyInquiry() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.support_agent_outlined, size: 64, color: AppColors.textHint),
        const SizedBox(height: 14),
        const Text('문의 내역이 없어요', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        const Text('궁금한 점을 문의해주세요', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_rounded, size: 16),
          label: const Text('문의 작성하기'),
          onPressed: _showInquirySheet,
        ),
      ]),
    );
  }

  void _showInquiryDetail(Inquiry inquiry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75, maxChildSize: 0.95, expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(controller: scrollCtrl, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6)),
                child: Text(inquiry.category, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
              const Spacer(),
              Text(inquiry.timeAgo, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
            ]),
            const SizedBox(height: 12),
            Text(inquiry.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(inquiry.content, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
            if (inquiry.isAnswered && inquiry.answer != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.25))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.support_agent_rounded, color: AppColors.success, size: 18),
                    const SizedBox(width: 6),
                    const Text('Asome Tutor 고객센터 답변', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                  ]),
                  const SizedBox(height: 10),
                  Text(inquiry.answer!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.7)),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  void _showInquirySheet() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedCategory = '이용방법';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottomPad = MediaQuery.of(ctx).viewInsets.bottom;
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.5,
            maxChildSize: 0.92,
            expand: false,
            builder: (_, scrollCtrl) => Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 16),
              child: ListView(
                controller: scrollCtrl,
                shrinkWrap: true,
                children: [
                  // 핸들바
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('1:1 문의 작성',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  // 문의 유형 라벨
                  const Text('문의 유형',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  // ── Chip 간격 타이트하게 ──
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _inquiryCategories.map((cat) => ChoiceChip(
                      label: Text(cat,
                          style: TextStyle(
                              fontSize: 12,
                              color: selectedCategory == cat
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: selectedCategory == cat
                                  ? FontWeight.w700
                                  : FontWeight.w400)),
                      selected: selectedCategory == cat,
                      onSelected: (_) =>
                          setModalState(() => selectedCategory = cat),
                      selectedColor: AppColors.primary.withValues(alpha: 0.12),
                      backgroundColor: AppColors.background,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(
                          color: selectedCategory == cat
                              ? AppColors.primary
                              : AppColors.divider),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  // 제목
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                        labelText: '제목 *',
                        hintText: '문의 제목을 입력하세요',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  ),
                  const SizedBox(height: 8),
                  // 내용
                  TextField(
                    controller: contentCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '내용 *',
                      hintText: '문의 내용을 자세히 작성해주세요.',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('* 이미지 첨부는 앱에서 지원됩니다',
                      style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                  const SizedBox(height: 14),
                  // 등록 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
<<<<<<< Updated upstream
                            const SnackBar(
                              content: Text('제목과 내용을 입력해주세요'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
=======
                              const SnackBar(content: Text('제목과 내용을 입력해주세요')));
>>>>>>> Stashed changes
                          return;
                        }
                        final newInquiry = Inquiry(
                          id: 'inq_${DateTime.now().millisecondsSinceEpoch}',
                          category: selectedCategory,
                          title: titleCtrl.text,
                          content: contentCtrl.text,
                          createdAt: DateTime.now(),
                          isAnswered: false,
                        );
                        setState(() => _inquiries.insert(0, newInquiry));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
<<<<<<< Updated upstream
                            content: Text('문의가 접수되었습니다. 1~2일 내 답변드릴게요.'),
                            duration: Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
=======
                              content: Text(
                                  '문의가 접수되었습니다. 영업일 기준 1~2일 내 답변드릴게요!')));
>>>>>>> Stashed changes
                      },
                      child: const Text('문의 등록'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
