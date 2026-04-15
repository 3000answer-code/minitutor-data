import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../services/note_repository.dart';
import '../../services/translations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lecture_card.dart';
import '../lecture/lecture_player_screen.dart';
import 'my_note_viewer_screen.dart';

class MyActivityScreen extends StatefulWidget {
  final int initialTab;
  final String? highlightLectureId;   // 강의플레이어에서 바로 이동 시 해당 강의 강조
  const MyActivityScreen({super.key, this.initialTab = 0, this.highlightLectureId});

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NoteMetaData> _notes = [];
  bool _notesLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab.clamp(0, 3));
    _tabController.addListener(() {
      if (_tabController.index == 1) _loadNotes();
    });
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    if (!mounted) return;
    setState(() => _notesLoading = true);
    final list = await NoteRepository().getAllNotes();
    if (!mounted) return;
    setState(() {
      _notes = list;
      _notesLoading = false;
    });
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
        title: Text(T('my_activity_title'), style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: [
            Tab(child: Text(T('tab_recent'), style: const TextStyle(fontSize: 13))),
            Tab(child: Text(T('tab_notes'), style: const TextStyle(fontSize: 13))),
            Tab(child: Text(T('tab_my_qa'), style: const TextStyle(fontSize: 13))),
            Tab(child: Text(T('tab_expert'), style: const TextStyle(fontSize: 13))),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          dividerColor: AppColors.divider,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          labelPadding: EdgeInsets.zero,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecentTab(lang),
          _buildNoteTab(lang),
          _buildQATab(lang),
          _buildConsultationTab(lang),
        ],
      ),
    );
  }

  // ── 탭 1: 최근 본 영상 ────────────────────────────
  Widget _buildRecentTab(String lang) {
    final T = (String key) => AppTranslations.tLang(lang, key);
    final appState = context.watch<AppState>();
    final recent = appState.recentViewedLectures;

    return Column(children: [
      if (recent.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            Text('${T('total_count').replaceAll('{n}', '${recent.length}')}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const Spacer(),
            TextButton(
              onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
                title: Text(T('delete_recent_title')),
                content: Text(T('delete_recent_content')),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text(T('cancel'))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                    onPressed: () => Navigator.pop(context),
                    child: Text(T('delete_btn'))),
                ],
              )),
              child: Text(T('delete_all'), style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
            ),
          ]),
        ),
      Expanded(
        child: recent.isEmpty
            ? _buildEmptyState(Icons.history_rounded, T('empty_recent'), T('empty_recent_sub'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                itemCount: recent.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LectureCard(
                    lecture: recent[i], isHorizontal: true,
                    onTap: () {
                      appState.addRecentView(recent[i].id);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => LecturePlayerScreen(lecture: recent[i])));
                    },
                  ),
                ),
              ),
      ),
    ]);
  }

  // ── 탭 2: 내 노트 목록 (NoteRepository 기반) ──────────
  Widget _buildNoteTab(String lang) {
    final T = (String key) => AppTranslations.tLang(lang, key);
    final appState = context.read<AppState>();

    if (_notesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final notes = _notes;
    if (notes.isEmpty) {
      return Column(children: [
        Expanded(child: _buildEmptyState(
          Icons.note_alt_outlined, T('empty_notes'), T('empty_notes_sub'))),
      ]);
    }

    // highlightLectureId가 있으면 해당 노트를 맨 앞으로 정렬
    List<NoteMetaData> sortedNotes;
    if (widget.highlightLectureId != null) {
      sortedNotes = List<NoteMetaData>.from(notes);
      sortedNotes.sort((a, b) {
        if (a.lectureId == widget.highlightLectureId) return -1;
        if (b.lectureId == widget.highlightLectureId) return 1;
        return 0;
      });
    } else {
      sortedNotes = notes;
    }

    return RefreshIndicator(
      onRefresh: _loadNotes,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: sortedNotes.length,
        itemBuilder: (_, i) {
          final note = sortedNotes[i];
          final isHighlighted = widget.highlightLectureId != null &&
              note.lectureId == widget.highlightLectureId;
            final subjectColor = _subjectColor(note.subject);
            // 교안 첫 페이지 이미지 (있으면 미리보기)
            final previewUrl = note.handoutUrls.isNotEmpty
                ? note.handoutUrls.first
                : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isHighlighted
                    ? Border.all(color: const Color(0xFF0EA5E9), width: 2)
                    : null,
                boxShadow: [BoxShadow(
                  color: isHighlighted
                      ? const Color(0xFF0EA5E9).withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: isHighlighted ? 16 : 8,
                  offset: const Offset(0, 2))],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  final lecture = appState.allLectures
                      .where((l) => l.id == note.lectureId)
                      .firstOrNull;
                  if (lecture != null) {
                    // 교안이 있는 강의들만 필터링 (이전/다음 이동용)
                    final lecturesWithHandouts = appState.allLectures
                        .where((l) => l.handoutUrls.isNotEmpty)
                        .toList();
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => MyNoteViewerScreen(
                        lecture: lecture,
                        lectureList: lecturesWithHandouts,
                      )))
                    .then((_) => _loadNotes());
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // ── 교안 미리보기 썸네일 ──
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 100, height: 100,
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: previewUrl != null
                            ? (previewUrl.startsWith('assets/')
                                ? Image.asset(previewUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        _noteThumbnailFallback(subjectColor))
                                : Image.network(previewUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        _noteThumbnailFallback(subjectColor)))
                            : _noteThumbnailFallback(subjectColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ── 텍스트 정보 ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 과목 배지 + 강사명
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: subjectColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4)),
                              child: Text(note.subject,
                                style: TextStyle(fontSize: 10,
                                  color: subjectColor,
                                  fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 6),
                            Text(note.instructorName,
                              style: const TextStyle(fontSize: 11,
                                color: AppColors.textSecondary)),
                          ]),
                          const SizedBox(height: 4),
                          // 강의 제목
                          Text(note.lectureTitle,
                            style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          // 필기 수 · 메모 수 · 저장 시각
                          Row(children: [
                            Icon(Icons.edit_rounded, size: 11,
                              color: subjectColor.withValues(alpha: 0.7)),
                            const SizedBox(width: 3),
                            Text('필기 ${note.strokeCount}획',
                              style: const TextStyle(fontSize: 11,
                                color: AppColors.textSecondary)),
                            if (note.memoCount > 0) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.sticky_note_2_outlined,
                                size: 11, color: AppColors.textHint),
                              const SizedBox(width: 3),
                              Text('메모 ${note.memoCount}개',
                                style: const TextStyle(fontSize: 11,
                                  color: AppColors.textHint)),
                            ],
                          ]),
                          const SizedBox(height: 3),
                          Text(note.savedAt,
                            style: const TextStyle(fontSize: 10,
                              color: AppColors.textHint)),
                        ],
                      ),
                    ),
                    // ── 휴지통 삭제 버튼 ──
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: AppColors.textHint),
                      splashRadius: 20,
                      tooltip: '노트 삭제',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                            title: const Text('내 노트 삭제',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                            content: Text('"${note.lectureTitle}" 필기를 삭제할까요?\n삭제된 필기는 복구할 수 없습니다.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(T('cancel'))),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error),
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(T('delete_btn'))),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await NoteRepository().deleteNote(note.lectureId);
                          await _loadNotes();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('내 노트가 삭제되었습니다'),
                                duration: Duration(seconds: 2)));
                          }
                        }
                      },
                    ),
                  ]),
                ),
              ),
            );
          },
      ),
    );
  }

  Widget _noteThumbnailFallback(Color color) {
    return Center(
      child: Icon(Icons.edit_note_rounded, color: color, size: 32));
  }

  // ── 탭 3: 강의 Q&A ────────────────────────────────
  Widget _buildQATab(String lang) {
    final T = (String key) => AppTranslations.tLang(lang, key);
    final qaList = [
      {'subject': '수학', 'lectureTitle': '이차방정식 근의 공식', 'question': '판별식이 0일 때 중근이 되는 이유가 뭔가요?', 'answer': '판별식 D = b²-4ac = 0 이면 근의 공식에서 ±√0 = 0이 되어 두 근이 같아지기 때문입니다.', 'answered': true, 'time': '2일 전'},
      {'subject': '과학', 'lectureTitle': '뉴턴의 운동법칙', 'question': '무게와 질량의 차이가 헷갈려요', 'answer': '질량은 물체가 가진 물질의 양(kg), 무게는 지구가 당기는 중력의 크기(N)입니다. 달에서는 질량은 같지만 무게가 달라져요!', 'answered': true, 'time': '1주 전'},
    ];

    return qaList.isEmpty
        ? _buildEmptyState(Icons.question_answer_outlined, T('empty_qa'), T('empty_qa_sub'))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            itemCount: qaList.length,
            itemBuilder: (_, i) {
              final qa = qaList[i];
              final answered = qa['answered'] as bool;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4)),
                        child: Text(qa['subject'] as String,
                          style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600))),
                      const SizedBox(width: 6),
                      Expanded(child: Text(qa['lectureTitle'] as String,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: answered ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20)),
                        child: Text(answered ? T('answer_complete') : T('answer_pending'),
                          style: TextStyle(fontSize: 10,
                            color: answered ? AppColors.success : AppColors.warning,
                            fontWeight: FontWeight.w700))),
                    ]),
                    const SizedBox(height: 8),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.help_outline_rounded, size: 15, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(child: Text(qa['question'] as String,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                    ]),
                    if (answered && (qa['answer'] as String).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.2))),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.subdirectory_arrow_right_rounded, size: 14, color: AppColors.success),
                          const SizedBox(width: 6),
                          Expanded(child: Text(qa['answer'] as String,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4))),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(qa['time'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ]),
                ),
              );
            },
          );
  }

  // ── 탭 4: 내 상담 ─────────────────────────────
  Widget _buildConsultationTab(String lang) {
    final T = (String key) => AppTranslations.tLang(lang, key);
    final myConsultations = [
      {'subject': '수학', 'title': '이차방정식 근의 공식 언제 쓰는 건가요?', 'answered': true, 'time': '2일 전', 'views': 234},
      {'subject': '과학', 'title': '뉴턴 제2법칙 F=ma에서 a가 음수면 어떻게 되나요?', 'answered': false, 'time': '5시간 전', 'views': 45},
    ];

    return myConsultations.isEmpty
        ? _buildEmptyState(Icons.chat_bubble_outline_rounded, T('empty_consult'), T('empty_consult_sub'))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            itemCount: myConsultations.length,
            itemBuilder: (_, i) {
              final c = myConsultations[i];
              final answered = c['answered'] as bool;
              return Container(
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(c['subject'] as String, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: answered ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20)),
                      child: Text(answered ? T('answer_complete') : T('answer_pending'),
                        style: TextStyle(fontSize: 10, color: answered ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w700))),
                  ]),
                  const SizedBox(height: 8),
                  Text(c['title'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.visibility_outlined, size: 12, color: AppColors.textHint),
                    Text(' ${c['views']}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    const SizedBox(width: 8),
                    Text(c['time'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ]),
                ]),
              );
            },
          );
  }

  // ── 공통 빈 상태 ──────────────────────────────────
  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 64, color: AppColors.textHint.withValues(alpha: 0.4)),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
      ]),
    );
  }

  Color _subjectColor(String subject) {
    switch (subject) {
      case '수학': return AppColors.math;
      case '과학': return AppColors.science;
      case '화학': return const Color(0xFFE67E22);
      default: return AppColors.other;
    }
  }
}
