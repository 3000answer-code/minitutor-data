import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../services/translations.dart';
import '../../theme/app_theme.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});
  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPlanIndex = 1;

  final List<Map<String, dynamic>> _plans = [
    {'days': 7, 'price': '3,900', 'label': '7일 이용권', 'badge': '', 'desc': '체험용 단기 이용권'},
    {'days': 30, 'price': '9,900', 'label': '30일 이용권', 'badge': '인기', 'desc': '가장 많이 선택하는 이용권'},
    {'days': 90, 'price': '24,900', 'label': '90일 이용권', 'badge': '할인', 'desc': '3개월 집중 학습 패키지'},
    {'days': 180, 'price': '44,900', 'label': '180일 이용권', 'badge': '최저가', 'desc': '6개월 장기 학습 최대 할인'},
  ];

  final List<Map<String, dynamic>> _paymentHistory = [
    {'type': '30일 이용권', 'date': '2025.03.01', 'amount': '9,900원', 'status': '결제완료'},
    {'type': '30일 이용권', 'date': '2025.02.01', 'amount': '9,900원', 'status': '결제완료'},
    {'type': '7일 이용권', 'date': '2025.01.25', 'amount': '3,900원', 'status': '결제완료'},
  ];

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

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(T('store_title'), style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: T('store_title')), Tab(text: T('payment_history_tab'))],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          dividerColor: AppColors.divider,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildStoreTab(lang), _buildPaymentTab(lang)],
      ),
    );
  }

  Widget _buildStoreTab(String lang) {
    final T = (String key) => AppTranslations.tLang(lang, key);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(T('premium_benefits'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            Text(T('unlimited_lectures'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(T('store_subtitle'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: ['광고 없음', '오프라인 다운로드', '강의 Q&A'].map((b) =>
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20)),
                child: Text('✓ $b', style: const TextStyle(color: Colors.white, fontSize: 12)),
              )
            ).toList()),
          ]),
        ),
        const SizedBox(height: 24),
        Text(T('select_plan'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ...List.generate(_plans.length, (i) {
          final plan = _plans[i];
          final isSelected = _selectedPlanIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedPlanIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 12, offset: const Offset(0, 4))] : [],
              ),
              child: Row(children: [
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider, width: 2),
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                  child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(plan['label'] as String,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                    if ((plan['badge'] as String).isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: plan['badge'] == '인기' ? AppColors.accent : AppColors.primary,
                          borderRadius: BorderRadius.circular(10)),
                        child: Text(plan['badge'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(plan['desc'] as String,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ])),
                Text('${plan['price']}원',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary)),
              ]),
            ),
          );
        }),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => _showPurchaseConfirm(lang),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              '${_plans[_selectedPlanIndex]['label']} ${T('buy_plan')} (${_plans[_selectedPlanIndex]['price']}원)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(T('payment_notice'),
            style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        ),
      ]),
    );
  }

  Widget _buildPaymentTab(String lang) {
    final T = (String key) => AppTranslations.tLang(lang, key);
    if (_paymentHistory.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.divider),
          const SizedBox(height: 12),
          Text(T('no_payment_history'), style: const TextStyle(color: AppColors.textSecondary)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _paymentHistory.length,
      itemBuilder: (context, i) {
        final p = _paymentHistory[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.receipt_outlined, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['type'] as String,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(p['date'] as String,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(p['amount'] as String,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(p['status'] as String,
                  style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
              ),
            ]),
          ]),
        );
      },
    );
  }

  void _showPurchaseConfirm(String lang) {
    final T = (String key) => AppTranslations.tLang(lang, key);
    final plan = _plans[_selectedPlanIndex];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(T('buy_confirm_title'), style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${plan['label']}을 구매하시겠습니까?',
            style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 8),
          Text('${plan['price']}원',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(T('cancel'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${plan['label']} ${T('buy_plan')}!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(T('buy_plan'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
