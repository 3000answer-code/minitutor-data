import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../services/content_service.dart';
import '../../theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  late List<FaqItem> _faqItems;
  String _selectedFaqCategory = '전체';

  final List<String> _faqCategories = ['전체', '이용방법', '결제/이용권', '계정/회원', '강의', '기술/오류'];

  // 파스텔 톤 색상 팔레트 (카테고리별)
  static const Map<String, Color> _pastelColors = {
    '이용방법': Color(0xFFE8F5E9),     // 파스텔 그린
    '결제/이용권': Color(0xFFFFF3E0),  // 파스텔 오렌지
    '계정/회원': Color(0xFFE3F2FD),    // 파스텔 블루
    '강의': Color(0xFFF3E5F5),         // 파스텔 퍼플
    '기술/오류': Color(0xFFFFEBEE),    // 파스텔 레드
  };

  static const Map<String, Color> _pastelAccents = {
    '이용방법': Color(0xFF66BB6A),
    '결제/이용권': Color(0xFFFFA726),
    '계정/회원': Color(0xFF42A5F5),
    '강의': Color(0xFFAB47BC),
    '기술/오류': Color(0xFFEF5350),
  };

  @override
  void initState() {
    super.initState();
    _faqItems = ContentService().getFaqItems();
  }

  List<FaqItem> get _filteredFaq => _selectedFaqCategory == '전체'
      ? _faqItems
      : _faqItems.where((f) => f.category == _selectedFaqCategory).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text('고객센터', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildFaqTab(),
    );
  }

  // ── FAQ 탭 ────────────────────────────────────────
  Widget _buildFaqTab() {
    return Column(children: [
      // 카테고리 필터
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _faqCategories.map((cat) {
              final isSelected = _selectedFaqCategory == cat;
              final accent = _pastelAccents[cat] ?? AppColors.primary;
              final bg = _pastelColors[cat] ?? AppColors.primary.withValues(alpha: 0.08);
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(cat, style: TextStyle(
                    fontSize: 11.5,
                    color: isSelected ? accent : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedFaqCategory = cat),
                  selectedColor: isSelected ? bg : AppColors.background,
                  checkmarkColor: accent,
                  backgroundColor: const Color(0xFFF5F5F5),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  side: BorderSide(
                    color: isSelected ? accent.withValues(alpha: 0.4) : const Color(0xFFE8E8E8),
                    width: 0.8,
                  ),
                  visualDensity: const VisualDensity(vertical: -4),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      Divider(height: 0, color: Colors.grey.shade200),
      // FAQ 리스트
      Expanded(
        child: _filteredFaq.isEmpty
            ? const Center(child: Text('해당 카테고리의 FAQ가 없습니다', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                itemCount: _filteredFaq.length,
                itemBuilder: (_, i) => _buildFaqCard(_filteredFaq[i]),
              ),
      ),
    ]);
  }

  Widget _buildFaqCard(FaqItem faq) {
    final catColor = _pastelAccents[faq.category] ?? AppColors.primary;
    final catBg = _pastelColors[faq.category] ?? AppColors.primary.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          key: PageStorageKey(faq.id),
          initiallyExpanded: faq.isExpanded,
          onExpansionChanged: (v) => setState(() => faq.isExpanded = v),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: EdgeInsets.zero,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          dense: true,
          visualDensity: const VisualDensity(vertical: -2),
          leading: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: catBg,
              borderRadius: BorderRadius.circular(7)),
            child: Center(
              child: Text('Q', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: catColor))),
          ),
          title: Text(faq.question,
            style: TextStyle(
              fontSize: 13,
              fontWeight: faq.isExpanded ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.3)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: catBg,
                borderRadius: BorderRadius.circular(4)),
              child: Text(faq.category,
                style: TextStyle(fontSize: 9.5, color: catColor, fontWeight: FontWeight.w600)),
            ),
          ),
          trailing: AnimatedRotation(
            turns: faq.isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.keyboard_arrow_down_rounded, color: catColor.withValues(alpha: 0.6), size: 20),
          ),
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: catBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: catColor.withValues(alpha: 0.15))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6)),
                    child: Center(
                      child: Text('A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: catColor))),
                  ),
                  const SizedBox(width: 6),
                  Text('답변', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: catColor)),
                ]),
                const SizedBox(height: 6),
                Text(faq.answer,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.6)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
