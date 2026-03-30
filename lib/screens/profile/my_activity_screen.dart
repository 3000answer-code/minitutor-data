import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../services/content_service.dart';
import '../../services/translations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lecture_card.dart';
import '../lecture/lecture_player_screen.dart';
import '../lecture/note_canvas_screen.dart';

class MyActivityScreen extends StatefulWidget {
  final int initialTab;
  const MyActivityScreen({super.key, this.initialTab = 0});

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _contentService = ContentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialTab);
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
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: T('tab_recent')),
            Tab(text: T('tab_notes')),
            Tab(text: T('tab_my_qa')),
            Tab(text: T('tab_expert')),
            Tab(text: T('tab_favorites')),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          dividerColor: AppColors.divider,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecentTab(lang),
          _buildNoteTab(lang),
          _buildQATab(lang),
          _buildConsultationTab(lang),
          _buildFavoriteTab(lang),
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

  // ── 탭 2: 노트 목록 ──────────────────────────────
  Widget _buildNoteTab(String lang) {
    final T = (String key) => AppTranslations.tLang(lang, key);
    final notes = _contentService.getSavedNotes();
    final appState = context.read<AppState>();

    return notes.isEmpty
        ? _buildEmptyState(Icons.note_alt_outlined, T('empty_notes'), T('empty_notes_sub'))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            itemCount: notes.length,
            itemBuilder: (_, i) {
              final note = notes[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _subjectColor(note.subject).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.edit_note_rounded, color: _subjectColor(note.subject), size: 24),
                  ),
                  title: Text(note.lectureTitle,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 3),
                    Text(note.previewText,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _subjectColor(note.subject).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4)),
                        child: Text(note.subject,
                          style: TextStyle(fontSize: 10, color: _subjectColor(note.subject), fontWeight: FontWeight.w600))),
                      const SizedBox(width: 6),
                      Text('${T('stroke_count').replaceAll('{n}', '${note.strokeCount}')} · ${note.savedAt}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                    ]),
                  ]),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textHint),
                    onSelected: (v) {
                      if (v == 'open') {
                        final lecture = appState.allLectures.where((l) => l.id == note.lectureId).firstOrNull;
                        if (lecture != null) {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => NoteCanvasScreen(lecture: lecture)));
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'open', child: Text(T('note_open'))),
                      PopupMenuItem(value: 'delete', child: Text(T('delete_btn'), style: const TextStyle(color: AppColors.error))),
                    ],
                  ),
                  onTap: () {
                    final lecture = appState.allLectures.where((l) => l.id == note.lectureId).firstOrNull;
                    if (lecture != null) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => NoteCanvasScreen(lecture: lecture)));
                    }
                  },
                ),
              );
            },
          );
  }

  // ── 탭 3: 강의 Q&A ────────────────────────────────
  Widget _buildQATab(String lang) {
    final T = (String key) => AppTranslations.tLang(lang, key);
    final qaList = [
      {'subject': '수학', 'lectureTitle': '이차방정식 근의 공식', 'question': '판별식이 0일 때 중근이 되는 이유가 뭔가요?', 'answer': '판별식 D = b²-4ac = 0 이면 근의 공식에서 ±√0 = 0이 되어 두 근이 같아지기 때문입니다.', 'answered': true, 'time': '2일 전'},
      {'subject': '영어', 'lectureTitle': '현재완료 vs 과거시제', 'question': 'just, already, yet은 어떤 시제와 쓰나요?', 'answer': '', 'answered': false, 'time': '5시간 전'},
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

  // ── 탭 4: 전문가 상담 ─────────────────────────────
  Widget _buildConsultationTab(String lang) {
    final T = (String key) => AppTranslations.tLang(lang, key);
    final myConsultations = [
      {'subject': '수학', 'title': '이차방정식 근의 공식 언제 쓰는 건가요?', 'answered': true, 'time': '2일 전', 'views': 234},
      {'subject': '영어', 'title': '현재완료 have+p.p. 써야 하는 경우가 헷갈려요', 'answered': false, 'time': '5시간 전', 'views': 45},
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

  // ── 탭 5: 즐겨찾기 ───────────────────────────────
  Widget _buildFavoriteTab(String lang) {
    final T = (String key) => AppTranslations.tLang(lang, key);
    final appState = context.watch<AppState>();
    final favs = appState.favoriteLectures;

    return Column(children: [
      if (favs.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            Text(T('fav_count').replaceAll('{n}', '${favs.length}'),
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ]),
        ),
      Expanded(
        child: favs.isEmpty
            ? _buildEmptyState(Icons.bookmark_border_rounded, T('empty_favorites'), T('empty_favorites_sub'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                itemCount: favs.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LectureCard(
                    lecture: favs[i], isHorizontal: true,
                    onTap: () {
                      appState.addRecentView(favs[i].id);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => LecturePlayerScreen(lecture: favs[i])));
                    },
                  ),
                ),
              ),
      ),
    ]);
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
      case '국어': return AppColors.korean;
      case '영어': return AppColors.english;
      case '수학': return AppColors.math;
      case '과학': return AppColors.science;
      case '사회': return AppColors.social;
      default: return AppColors.other;
    }
  }
}
