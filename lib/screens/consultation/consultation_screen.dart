import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/consultation.dart';
import '../../services/app_state.dart';
import '../../services/translations.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_drawer.dart';

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
      endDrawer: const ProfileDrawer(),
      appBar: AppBar(
        title: Text(T('consultation_expert'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ── 정렬 메뉴: 줄 간격 조밀하게 (dense) ──
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, color: AppColors.textPrimary),
            onSelected: appState.setConsultationSort,
            // padding 최소화해 항목 높이 축소
            itemBuilder: (_) =>
                [T('sort_latest'), T('sort_views2'), T('sort_answered')]
                    .map((opt) => PopupMenuItem(
                          value: opt,
                          height: 36, // 기본 48 → 36으로 축소
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 0),
                          child: Text(opt,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      appState.consultationSort == opt
                                          ? FontWeight.w700
                                          : FontWeight.normal)),
                        ))
                    .toList(),
          ),
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded,
                  color: AppColors.textPrimary, size: 24),
              tooltip: '메뉴',
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: Column(
        children: [
          _buildStatsBanner(context, consultations),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: consultations.length,
              itemBuilder: (_, i) =>
                  _buildConsultationCard(context, consultations[i]),
            ),
          ),
        ],
      ),
      // ── 질문하기 버튼: 슬림한 소형 FAB ──
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _showWriteDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: T('ask_question'),
        child: const Icon(Icons.add_comment_rounded, size: 20),
      ),
    );
  }

  // ── 통계 배너 ──────────────────────────────────────────────
  Widget _buildStatsBanner(
      BuildContext context, List<Consultation> consultations) {
    final lang = context.read<AppState>().selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    final answered = consultations.where((c) => c.isAnswered).length;
    final total = consultations.length;
    final rate = total > 0 ? (answered / total * 100).toInt() : 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(T('consultation_expert'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('평균 답변 시간: 4시간 이내',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11)),
            ])),
        Column(children: [
          Text('$rate%',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          Text(T('response_rate'),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85), fontSize: 10)),
        ]),
      ]),
    );
  }

  // ── 질문 카드 (휴지통 포함) ────────────────────────────────
  Widget _buildConsultationCard(BuildContext context, Consultation c) {
    final appState = context.read<AppState>();
    final isMine = appState.isMyConsultation(c.id);

    return GestureDetector(
      onTap: () => _openDetail(context, c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.background,
              backgroundImage: NetworkImage(c.authorProfileUrl),
            ),
            const SizedBox(width: 8),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(c.authorNickname,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(c.timeAgo,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textHint)),
                ])),
            // 상태 배지
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: c.isAnswered
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                    c.isAnswered
                        ? Icons.check_circle_rounded
                        : Icons.schedule_rounded,
                    size: 11,
                    color:
                        c.isAnswered ? AppColors.success : AppColors.warning),
                const SizedBox(width: 2),
                Text(c.statusText,
                    style: TextStyle(
                        fontSize: 10,
                        color: c.isAnswered
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            // ── 내 질문이면 휴지통 아이콘 표시 ──
            if (isMine) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _confirmDelete(context, c.id),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.textHint),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _tag(c.subject, AppColors.primary),
            const SizedBox(width: 5),
            _tag(
                c.grade == 'middle'
                    ? '중등'
                    : c.grade == 'high'
                        ? '고등'
                        : '예비중',
                AppColors.textSecondary),
          ]),
          const SizedBox(height: 5),
          Text(c.title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(c.content,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (c.isAnswered && c.answer != null) ...[
            const Divider(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 3,
                  height: 32,
                  decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 7),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(c.answerAuthor ?? '내 상담',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success)),
                    Text(c.answer!,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ])),
            ]),
          ],
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.visibility_outlined,
                size: 11, color: AppColors.textHint),
            const SizedBox(width: 2),
            Text('${c.viewCount}',
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textHint)),
            const SizedBox(width: 7),
            const Icon(Icons.access_time_rounded,
                size: 11, color: AppColors.textHint),
            const SizedBox(width: 2),
            Text(c.timeAgo,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textHint)),
          ]),
        ]),
      ),
    );
  }

  Widget _tag(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4)),
        child: Text(label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      );

  // ── 삭제 확인 다이얼로그 ───────────────────────────────────
  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('질문 삭제',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Text('이 질문을 삭제하시겠어요?\n삭제 후 복구할 수 없습니다.',
            style: TextStyle(fontSize: 13, height: 1.5)),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소',
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              context.read<AppState>().deleteConsultation(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('질문이 삭제되었습니다'),
                  duration: Duration(seconds: 2)));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            child: const Text('삭제', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── 상세 보기 바텀시트 ─────────────────────────────────────
  void _openDetail(BuildContext context, Consultation c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          children: [
            Center(
                child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            Row(children: [
              CircleAvatar(
                  radius: 17,
                  backgroundImage: NetworkImage(c.authorProfileUrl)),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.authorNickname,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(c.timeAgo,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint)),
              ]),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                    color: c.isAnswered
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(c.statusText,
                    style: TextStyle(
                        fontSize: 11,
                        color:
                            c.isAnswered ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 12),
            Text(c.title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(c.content,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6)),
            if (c.isAnswered && c.answer != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 5),
                    Text(c.answerAuthor ?? '내 상담',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success)),
                    const Spacer(),
                    if (c.answeredAt != null)
                      Text(
                          c.answeredAt!
                                      .difference(DateTime.now())
                                      .abs()
                                      .inHours <
                                  24
                              ? '${c.answeredAt!.difference(DateTime.now()).abs().inHours}시간 전'
                              : '${c.answeredAt!.difference(DateTime.now()).abs().inDays}일 전',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textHint)),
                  ]),
                  const SizedBox(height: 6),
                  Text(c.answer!,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.6)),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── 질문 작성 팝업 (슬림 + 드롭다운 조밀) ─────────────────
  void _showWriteDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedSubject = '수학';
    String selectedGrade = 'middle';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          // 키보드 올라올 때 viewInsets 반영
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 드래그 핸들
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.divider,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 10),
                const Text('질문 작성',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),

                // ── 과목 / 학제 드롭다운 (줄 간격 조밀) ──
                Row(children: [
                  _compactDropdown<String>(
                    value: selectedSubject,
                    items: ['수학', '과학', '두번설명'],
                    labels: {'수학': '수학', '과학': '과학', '두번설명': '두번설명'},
                    onChanged: (v) => setState(() => selectedSubject = v!),
                  ),
                  const SizedBox(width: 8),
                  _compactDropdown<String>(
                    value: selectedGrade,
                    items: ['elementary', 'middle', 'high'],
                    labels: {
                      'elementary': '예비중',
                      'middle': '중등',
                      'high': '고등'
                    },
                    onChanged: (v) => setState(() => selectedGrade = v!),
                  ),
                ]),
                const SizedBox(height: 8),

                // 제목 입력
                SizedBox(
                  height: 44,
                  child: TextField(
                    controller: titleCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '질문 제목',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: AppColors.textHint),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: AppColors.divider)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: AppColors.divider)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.primary)),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // 내용 입력
                SizedBox(
                  height: 90,
                  child: TextField(
                    controller: contentCtrl,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '질문 내용을 자세히 작성해주세요',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: AppColors.textHint),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: AppColors.divider)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: AppColors.divider)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.primary)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 등록 버튼
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      final content = contentCtrl.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('제목을 입력해주세요')));
                        return;
                      }
                      // 새 질문 등록
                      final newC = Consultation(
                        id:
                            'my_${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        content: content.isEmpty ? '(내용 없음)' : content,
                        authorNickname: '나',
                        authorProfileUrl:
                            'https://picsum.photos/seed/me/80/80',
                        subject: selectedSubject,
                        grade: selectedGrade,
                        createdAt: DateTime.now(),
                        isAnswered: false,
                        viewCount: 0,
                        attachments: [],
                      );
                      context.read<AppState>().addConsultation(newC);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text('질문이 등록되었습니다! 곧 답변드릴게요.')));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('질문 등록하기',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  /// 조밀한 드롭다운 위젯 (줄 간격 최소화)
  Widget _compactDropdown<T>({
    required T value,
    required List<T> items,
    required Map<T, String> labels,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          // 펼쳐진 메뉴 전체 최대 높이 → 항목수 × 36px 로 타이트하게 제한
          menuMaxHeight: items.length * 36.0,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600),
          onChanged: onChanged,
          // DropdownMenuItem 자체 높이는 고정 불가(이 Flutter 버전)
          // → SizedBox로 내부 위젯 높이를 34px로 제한해 시각적 간격 축소
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: SizedBox(
                height: 34,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    labels[item] ?? item.toString(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
