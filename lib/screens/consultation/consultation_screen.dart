import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/consultation.dart';
import '../../services/app_state.dart';
import '../../services/translations.dart';
import '../../theme/app_theme.dart';

class ConsultationScreen extends StatelessWidget {
  const ConsultationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    final consultations = appState.consultations;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(T('consultation_expert'), style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, color: AppColors.textPrimary),
            onSelected: appState.setConsultationSort,
            itemBuilder: (_) => [T('sort_latest'), T('sort_views2'), T('sort_answered')].map((opt) =>
              PopupMenuItem(value: opt, child: Text(opt,
                style: TextStyle(fontWeight: appState.consultationSort == opt ? FontWeight.bold : FontWeight.normal)))).toList(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: Column(
        children: [
          // 통계 배너
          _buildStatsBanner(context, consultations),
          // 목록
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: consultations.length,
              itemBuilder: (_, i) => _buildConsultationCard(context, consultations[i]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWriteDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: Text(T('ask_question'), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildStatsBanner(BuildContext context, List<Consultation> consultations) {
    final lang = context.read<AppState>().selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    final answered = consultations.where((c) => c.isAnswered).length;
    final total = consultations.length;
    final rate = total > 0 ? (answered / total * 100).toInt() : 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(T('consultation_expert'),
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('평균 답변 시간: 4시간 이내', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
        ])),
        Column(children: [
          Text('$rate%', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          Text(T('response_rate'), style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _buildConsultationCard(BuildContext context, Consultation c) {
    return GestureDetector(
      onTap: () => _openDetail(context, c),
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
            CircleAvatar(
              radius: 16, backgroundColor: AppColors.background,
              backgroundImage: NetworkImage(c.authorProfileUrl),
            ),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.authorNickname, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text(c.timeAgo, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            ])),
            // 상태 배지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.isAnswered ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(c.isAnswered ? Icons.check_circle_rounded : Icons.schedule_rounded,
                  size: 12, color: c.isAnswered ? AppColors.success : AppColors.warning),
                const SizedBox(width: 3),
                Text(c.statusText,
                  style: TextStyle(fontSize: 11, color: c.isAnswered ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          // 과목 태그
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(c.subject, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600))),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(4)),
              child: Text(c.grade == 'middle' ? '중등' : c.grade == 'high' ? '고등' : '초등',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          ]),
          const SizedBox(height: 6),
          Text(c.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(c.content,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          if (c.isAnswered && c.answer != null) ...[
            const Divider(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 3, height: 40,
                decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.answerAuthor ?? '전문가', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
                Text(c.answer!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              ])),
            ]),
          ],
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.visibility_outlined, size: 12, color: AppColors.textHint),
            const SizedBox(width: 3),
            Text('${c.viewCount}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(width: 8),
            const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textHint),
            const SizedBox(width: 3),
            Text(c.timeAgo, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
          ]),
        ]),
      ),
    );
  }

  void _openDetail(BuildContext context, Consultation c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
              color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              CircleAvatar(radius: 18, backgroundImage: NetworkImage(c.authorProfileUrl)),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.authorNickname, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(c.timeAgo, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ]),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.isAnswered ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(c.statusText,
                  style: TextStyle(fontSize: 12, color: c.isAnswered ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 16),
            Text(c.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(c.content, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
            if (c.isAnswered && c.answer != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(c.answerAuthor ?? '전문가', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                    const Spacer(),
                    if (c.answeredAt != null)
                      Text(c.answeredAt!.difference(DateTime.now()).abs().inHours < 24
                          ? '${c.answeredAt!.difference(DateTime.now()).abs().inHours}시간 전'
                          : '${c.answeredAt!.difference(DateTime.now()).abs().inDays}일 전',
                        style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ]),
                  const SizedBox(height: 8),
                  Text(c.answer!, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.6)),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  void _showWriteDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedSubject = '수학';
    String selectedGrade = 'middle';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) =>
        Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('질문 작성', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            // 과목/학제 선택
            Row(children: [
              DropdownButton<String>(
                value: selectedSubject,
                onChanged: (v) => setState(() => selectedSubject = v!),
                items: ['국어', '영어', '수학', '과학', '사회'].map((s) =>
                  DropdownMenuItem(value: s, child: Text(s))).toList(),
                underline: const SizedBox(),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: selectedGrade,
                onChanged: (v) => setState(() => selectedGrade = v!),
                items: const [
                  DropdownMenuItem(value: 'elementary', child: Text('초등')),
                  DropdownMenuItem(value: 'middle', child: Text('중등')),
                  DropdownMenuItem(value: 'high', child: Text('고등')),
                ],
                underline: const SizedBox(),
              ),
            ]),
            const SizedBox(height: 8),
            TextField(controller: titleCtrl,
              decoration: const InputDecoration(labelText: '제목', hintText: '질문 제목을 입력하세요')),
            const SizedBox(height: 8),
            TextField(controller: contentCtrl, maxLines: 4,
              decoration: const InputDecoration(labelText: '내용', hintText: '질문 내용을 자세히 작성해주세요. 이미지도 첨부할 수 있어요.')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('질문이 등록되었습니다! 전문가가 곧 답변드릴게요.')));
                },
                child: const Text('질문 등록하기'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
