import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/personal_qa.dart';
import '../../services/app_state.dart';
import '../../services/note_repository.dart';
import '../../services/translations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lecture_card.dart';
import '../lecture/lecture_player_screen.dart';
import 'my_note_viewer_screen.dart';
import '../schedule/schedule_screen.dart';

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
  bool _showTrash = false;  // 휴지통 보기 토글

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab.clamp(0, 3));
    _tabController.addListener(() {
      if (_tabController.index == 1) _loadNotes();
      if (_tabController.index == 2) _loadPersonalQAs();
    });
    _loadNotes();
    _loadPersonalQAs();
  }

  Future<void> _loadPersonalQAs() async {
    await context.read<AppState>().loadPersonalQAs();
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
            Tab(child: Text(T('tab_recent'), style: const TextStyle(fontSize: 12))),
            Tab(child: Text(T('tab_notes'), style: const TextStyle(fontSize: 12))),
            Tab(child: Text(T('tab_my_qa'), style: const TextStyle(fontSize: 12))),
            Tab(child: Text(T('my_schedule'), style: const TextStyle(fontSize: 12))),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          dividerColor: AppColors.divider,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          labelPadding: EdgeInsets.zero,
          tabAlignment: TabAlignment.fill,
        ),
      ),
      body: SafeArea(
        top: false,  // AppBar가 이미 처리
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildRecentTab(lang),
            _buildNoteTab(lang),
            _buildQATab(lang),
            const ScheduleScreen(embedded: true),
          ],
        ),
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: recent.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LectureCard(
                    lecture: recent[i], isHorizontal: true,
                    onTap: () {
                      appState.addRecentView(recent[i].id);
                      if (appState.pipActive && appState.pipLecture?.id != recent[i].id) {
                        appState.deactivatePip();
                      }
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
              margin: const EdgeInsets.only(bottom: 14),
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
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    // ── 교안 미리보기 썸네일 (고정 크기) ──
                    SizedBox(
                      width: 100, height: 78,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 100, height: 78,
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: previewUrl != null
                              ? (previewUrl.startsWith('assets/')
                                  ? Image.asset(previewUrl,
                                      width: 100, height: 78,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          _noteThumbnailFallback(subjectColor))
                                  : Image.network(previewUrl,
                                      width: 100, height: 78,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          _noteThumbnailFallback(subjectColor)))
                              : _noteThumbnailFallback(subjectColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ── 텍스트 정보 (520 스타일 3줄 · 세로 중앙) ──
                    Expanded(
                      child: () {
                        // Lecture 객체 조회하여 시리즈·학제·학년 정보 사용
                        final lecture = appState.allLectures
                            .where((l) => l.id == note.lectureId)
                            .firstOrNull;
                        final seriesName = lecture != null && lecture.series.isNotEmpty
                            ? lecture.series : '시리즈';
                        final gradeText = lecture?.gradeText ?? '중등';
                        final gradeStr = lecture?.grade ?? 'middle';
                        final gradeYear = lecture?.gradeYear ?? 'All';
                        final yearLabel = gradeYear.isEmpty || gradeYear == 'All'
                            ? 'All' : '${gradeYear}학년';
                        final gc = _gradeColor(gradeStr);
                        const Color allBadgeColor = Color(0xFFF97316);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1줄: 강의 제목
                            Text(note.lectureTitle,
                              style: const TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.3),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            // 2줄: 시리즈명 (520 스타일 아이콘+회색)
                            Row(children: [
                              const Icon(Icons.playlist_play_rounded,
                                  size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(seriesName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500)),
                              ),
                            ]),
                            const SizedBox(height: 4),
                            // 3줄: 학제 + 학년 + 과목 + 강사 (520 스타일 배지)
                            Row(children: [
                              _noteBadge520(gradeText, gc),
                              const SizedBox(width: 3),
                              _noteBadge520(yearLabel, yearLabel == 'All' ? allBadgeColor : gc.withValues(alpha: 0.65)),
                              const SizedBox(width: 3),
                              _noteBadge520(note.subject, subjectColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(note.instructorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10.5,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500)),
                              ),
                            ]),
                          ],
                        );
                      }(),
                    ),
                    // ── 휴지통 삭제 버튼 ──
                    const SizedBox(width: 4),
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

  // ── 탭 3: 나의 Q&A (개인용 · 질문하기/작성/수정/휴지통) ──────────
  Widget _buildQATab(String lang) {
    final appState = context.watch<AppState>();
    final activeList = appState.personalQAs;
    final trashList = appState.trashQAs;
    final displayList = _showTrash ? trashList : activeList;

    return Column(children: [
      // ── 상단 헤더: 개수 + 휴지통 토글 + 질문하기 ──
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 6),
        child: Row(children: [
          Text(
            _showTrash
                ? '휴지통 ${trashList.length}개'
                : '나의 Q&A ${activeList.length}개',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          // 휴지통 토글 버튼
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _showTrash = !_showTrash),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _showTrash
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _showTrash ? AppColors.error.withValues(alpha: 0.3) : AppColors.divider,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    _showTrash ? Icons.arrow_back_rounded : Icons.delete_outline_rounded,
                    size: 14,
                    color: _showTrash ? AppColors.error : AppColors.textHint,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _showTrash ? '목록으로' : '휴지통${trashList.isNotEmpty ? "(${trashList.length})" : ""}',
                    style: TextStyle(
                      fontSize: 11,
                      color: _showTrash ? AppColors.error : AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ),
            ),
          ),
          if (!_showTrash) ...[
            const SizedBox(width: 6),
            // 질문하기 버튼
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showWriteQADialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 3),
                    Text('질문하기', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ],
          if (_showTrash && trashList.isNotEmpty) ...[
            const SizedBox(width: 6),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _confirmEmptyTrash(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.delete_forever_rounded, size: 13, color: AppColors.error),
                    SizedBox(width: 3),
                    Text('비우기', style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ],
        ]),
      ),
      // ── Q&A 목록 ──
      Expanded(
        child: displayList.isEmpty
            ? _buildEmptyState(
                _showTrash ? Icons.delete_outline_rounded : Icons.question_answer_outlined,
                _showTrash ? '휴지통이 비어 있어요' : '나의 Q&A가 없어요',
                _showTrash ? '삭제된 Q&A가 여기에 보관됩니다' : '질문하기 버튼으로 첫 질문을 남겨보세요',
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: displayList.length,
                itemBuilder: (_, i) => _showTrash
                    ? _buildTrashQACard(context, displayList[i])
                    : _buildPersonalQACard(context, displayList[i]),
              ),
      ),
    ]);
  }

  // ── 개인 Q&A 카드 (Active) ──
  Widget _buildPersonalQACard(BuildContext context, PersonalQA qa) {
    final subjectColor = _subjectColor(qa.subject);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showQADetailSheet(context, qa),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            // 1행: 과목 + 학제 + 수정/삭제
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: subjectColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4)),
                child: Text(qa.subject,
                  style: TextStyle(fontSize: 10, color: subjectColor, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textHint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4)),
                child: Text(qa.gradeLabel,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
              if (qa.lectureTitle != null && qa.lectureTitle!.isNotEmpty) ...[
                const SizedBox(width: 5),
                Expanded(
                  child: Text(qa.lectureTitle!,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                ),
              ] else
                const Spacer(),
              // 수정 버튼
              GestureDetector(
                onTap: () => _showEditQADialog(context, qa),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                ),
              ),
              // 휴지통 버튼
              GestureDetector(
                onTap: () => _confirmTrashQA(context, qa),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            // 2행: 제목
            Text(qa.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            // 3행: 내용 미리보기
            Text(qa.content,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            // 4행: 시간
            Text(qa.timeAgo,
              style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
          ]),
        ),
      ),
    );
  }

  // ── 휴지통 Q&A 카드 ──
  Widget _buildTrashQACard(BuildContext context, PersonalQA qa) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4)),
              child: Text(qa.subject,
                style: const TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.delete_outline_rounded, size: 12, color: AppColors.textHint),
            const SizedBox(width: 2),
            const Text('휴지통', style: TextStyle(fontSize: 10, color: AppColors.textHint, fontWeight: FontWeight.w500)),
            const Spacer(),
            // 복원 버튼
            GestureDetector(
              onTap: () async {
                await context.read<AppState>().restorePersonalQA(qa.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Q&A가 복원되었습니다'), duration: Duration(seconds: 2)));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.restore_rounded, size: 13, color: AppColors.success),
                  SizedBox(width: 2),
                  Text('복원', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
            const SizedBox(width: 6),
            // 영구 삭제
            GestureDetector(
              onTap: () => _confirmPermanentDelete(context, qa),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.delete_forever_rounded, size: 13, color: AppColors.error),
                  SizedBox(width: 2),
                  Text('삭제', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(qa.title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary,
              decoration: TextDecoration.lineThrough, decorationColor: AppColors.textHint),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(qa.content,
            style: const TextStyle(fontSize: 11, color: AppColors.textHint, height: 1.3),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  // ── Q&A 상세 보기 바텀시트 ──
  void _showQADetailSheet(BuildContext context, PersonalQA qa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final bottomPad = MediaQuery.of(ctx).padding.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomPad),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 14),
                // 과목 + 학제 배지
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _subjectColor(qa.subject).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text(qa.subject,
                      style: TextStyle(fontSize: 11, color: _subjectColor(qa.subject), fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text(qa.gradeLabel,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  Text(qa.timeAgo, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ]),
                if (qa.lectureTitle != null && qa.lectureTitle!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.ondemand_video_rounded, size: 13, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Expanded(child: Text(qa.lectureTitle!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                  ]),
                ],
                const SizedBox(height: 14),
                // 제목
                Text(qa.title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                // 내용
                Text(qa.content,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.7)),
                const SizedBox(height: 20),
                // 하단 액션 버튼
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditQADialog(context, qa);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('수정', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmTrashQA(context, qa);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('삭제', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Q&A 작성 다이얼로그 ──
  void _showWriteQADialog(BuildContext context) {
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
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 14,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 10),
              const Text('나의 Q&A 작성', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              // 과목 / 학제 드롭다운
              Row(children: [
                _compactDropdown<String>(
                  value: selectedSubject,
                  items: ['수학', '과학', '공통과학', '물리', '화학', '생명과학', '지구과학', '국어', '영어'],
                  onChanged: (v) => setModalState(() => selectedSubject = v!),
                ),
                const SizedBox(width: 8),
                _compactDropdown<String>(
                  value: selectedGrade,
                  items: ['elementary', 'middle', 'high'],
                  labels: {'elementary': '예비중', 'middle': '중등', 'high': '고등'},
                  onChanged: (v) => setModalState(() => selectedGrade = v!),
                ),
              ]),
              const SizedBox(height: 8),
              // 제목
              SizedBox(
                height: 44,
                child: TextField(
                  controller: titleCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '질문 제목',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.divider)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // 내용
              SizedBox(
                height: 100,
                child: TextField(
                  controller: contentCtrl,
                  maxLines: null, expands: true,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '질문 내용을 자세히 작성해주세요',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.divider)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 등록 버튼
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('제목을 입력해주세요')));
                      return;
                    }
                    final now = DateTime.now();
                    final newQA = PersonalQA(
                      id: 'pqa_${now.millisecondsSinceEpoch}',
                      title: title,
                      content: contentCtrl.text.trim().isEmpty ? '(내용 없음)' : contentCtrl.text.trim(),
                      subject: selectedSubject,
                      grade: selectedGrade,
                      createdAt: now,
                      updatedAt: now,
                    );
                    await context.read<AppState>().addPersonalQA(newQA);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('나의 Q&A가 등록되었습니다!'), duration: Duration(seconds: 2)));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('질문 등록하기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Q&A 수정 다이얼로그 ──
  void _showEditQADialog(BuildContext context, PersonalQA qa) {
    final titleCtrl = TextEditingController(text: qa.title);
    final contentCtrl = TextEditingController(text: qa.content);
    String selectedSubject = qa.subject;
    String selectedGrade = qa.grade;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 14,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 10),
              const Text('나의 Q&A 수정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Row(children: [
                _compactDropdown<String>(
                  value: selectedSubject,
                  items: ['수학', '과학', '공통과학', '물리', '화학', '생명과학', '지구과학', '국어', '영어'],
                  onChanged: (v) => setModalState(() => selectedSubject = v!),
                ),
                const SizedBox(width: 8),
                _compactDropdown<String>(
                  value: selectedGrade,
                  items: ['elementary', 'middle', 'high'],
                  labels: {'elementary': '예비중', 'middle': '중등', 'high': '고등'},
                  onChanged: (v) => setModalState(() => selectedGrade = v!),
                ),
              ]),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: TextField(
                  controller: titleCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '질문 제목',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.divider)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 100,
                child: TextField(
                  controller: contentCtrl,
                  maxLines: null, expands: true,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '질문 내용',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.divider)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('취소', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('제목을 입력해주세요')));
                        return;
                      }
                      await context.read<AppState>().updatePersonalQA(
                        qa.id,
                        title: title,
                        content: contentCtrl.text.trim().isEmpty ? '(내용 없음)' : contentCtrl.text.trim(),
                        subject: selectedSubject,
                        grade: selectedGrade,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Q&A가 수정되었습니다'), duration: Duration(seconds: 2)));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('저장', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ── 휴지통 이동 확인 ──
  void _confirmTrashQA(BuildContext context, PersonalQA qa) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('휴지통으로 이동', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text('"${qa.title}"을(를) 휴지통으로 이동할까요?\n휴지통에서 복원할 수 있습니다.',
          style: const TextStyle(fontSize: 13, height: 1.5)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              await context.read<AppState>().trashPersonalQA(qa.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Q&A가 휴지통으로 이동되었습니다'), duration: Duration(seconds: 2)));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            child: const Text('이동', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── 영구 삭제 확인 ──
  void _confirmPermanentDelete(BuildContext context, PersonalQA qa) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('영구 삭제', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text('"${qa.title}"을(를) 완전히 삭제할까요?\n삭제 후 복구할 수 없습니다.',
          style: const TextStyle(fontSize: 13, height: 1.5)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              await context.read<AppState>().deletePersonalQAPermanently(qa.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Q&A가 영구 삭제되었습니다'), duration: Duration(seconds: 2)));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            child: const Text('영구 삭제', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── 휴지통 비우기 확인 ──
  void _confirmEmptyTrash(BuildContext context) {
    final trashCount = context.read<AppState>().trashQAs.length;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('휴지통 비우기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text('휴지통의 $trashCount개 Q&A를 모두 삭제할까요?\n삭제 후 복구할 수 없습니다.',
          style: const TextStyle(fontSize: 13, height: 1.5)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              await context.read<AppState>().emptyPersonalQATrash();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('휴지통을 비웠습니다'), duration: Duration(seconds: 2)));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            child: const Text('모두 삭제', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── 컴팩트 드롭다운 위젯 ──
  Widget _compactDropdown<T>({
    required T value,
    required List<T> items,
    Map<T, String>? labels,
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
          menuMaxHeight: items.length * 36.0,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: SizedBox(
                height: 34,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(labels?[item] ?? item.toString(), style: const TextStyle(fontSize: 13)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
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
      case '수학':     return AppColors.math;
      case '과학':     return AppColors.science;
      case '공통과학': return AppColors.commonScience;
      case '물리':     return AppColors.physics;
      case '화학':     return AppColors.chemistry;
      case '생명과학': return AppColors.biology;
      case '지구과학': return AppColors.earth;
      default:         return AppColors.other;
    }
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'elementary': return AppColors.elementary;
      case 'middle':     return AppColors.middle;
      default:           return AppColors.high;
    }
  }

  Widget _noteBadge520(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
    ),
    child: Text(label,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w700)),
  );
}
