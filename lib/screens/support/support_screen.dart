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
      backgroundColor: AppColors.background,
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
}
