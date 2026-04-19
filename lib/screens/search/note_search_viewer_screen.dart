import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/lecture.dart';
import '../../services/note_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eraser_widgets.dart';
import '../lecture/lecture_player_screen.dart';

const Color _kOrange = Color(0xFFF97316);

/// 노트 검색 결과 교안 뷰어
/// - 상단: 뒤로가기 | "노트보기" + 강의제목 | 영상재생 버튼
/// - 본문: 교안 상하 스크롤 (플레이어와 동일) + 필기 기능
/// - 하단 오른쪽: 이전/다음 강의 이동 버튼
/// - 하단 왼쪽: 필기도구 토글 버튼
class NoteSearchViewerScreen extends StatefulWidget {
  final List<Lecture> lectures;  // 검색 결과 전체 목록
  final int initialIndex;        // 처음 열 강의 인덱스

  const NoteSearchViewerScreen({
    super.key,
    required this.lectures,
    required this.initialIndex,
  });

  @override
  State<NoteSearchViewerScreen> createState() => _NoteSearchViewerScreenState();
}

class _NoteSearchViewerScreenState extends State<NoteSearchViewerScreen> {
  late int _currentIndex;

  // ── 교안 페이지 ───────────────────────────────
  List<String> _notePages = [];
  bool _slidesLoading = true;

  // ── 필기 상태 (플레이어와 동일) ──────────────
  bool _isDrawingMode = false;
  Color _penColor = const Color(0xFF2563EB);
  double _strokeWidth = 3.0;
  List<Offset?> _currentStroke = [];
  int _currentNotePageIndex = 0;
  final Map<int, List<_DrawingStroke>> _pageStrokes = {};
  bool _isEraser = false;
  bool _strokesSaved = true;
  Offset? _eraserPosition;
  bool _showEraserCursor = false;

  Lecture get _lecture => widget.lectures[_currentIndex];
  String get _strokesKey => 'strokes_${_lecture.id}';
  String get _notesKey => 'notes_${_lecture.id}';

  // ── 저장된 메모 ──────────────────────────────
  final List<Map<String, String>> _savedNotes = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadLecture();
  }

  // 강의 전환 시 상태 초기화 후 재로드
  void _loadLecture() {
    setState(() {
      _notePages = [];
      _slidesLoading = true;
      _isDrawingMode = false;
      _isEraser = false;
      _currentStroke = [];
      _currentNotePageIndex = 0;
      _pageStrokes.clear();
      _strokesSaved = true;
      _savedNotes.clear();
    });
    _loadPages();
    _loadSavedStrokes();
  }

  void _loadPages() {
    // 실제 교안 이미지만 포함 — 완전히 빈 파일(URL이 비어있거나 mp4 등)만 제외
    // NOTE: 'bio_blank.png', 'chem_blank_p2.png' 등 파일명에 'blank'가 포함되더라도
    //       실제 내용이 있는 교안 페이지이므로 반드시 표시해야 함
    final urls = _lecture.handoutUrls
        .where((u) => u.isNotEmpty && !u.endsWith('.mp4'))
        .toList();
    setState(() {
      _notePages = urls;
      _slidesLoading = false;
    });
  }

  Future<void> _loadSavedStrokes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final strokesJson = prefs.getString(_strokesKey);
      if (strokesJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(strokesJson);
        final Map<int, List<_DrawingStroke>> loaded = {};
        decoded.forEach((pageKey, strokeList) {
          final pageIdx = int.tryParse(pageKey) ?? 0;
          final strokes = (strokeList as List).map((s) {
            final points = (s['points'] as List).map<Offset?>((p) =>
              Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble())
            ).toList();
            return _DrawingStroke(
              points: points,
              color: Color(s['color'] as int),
              width: (s['width'] as num).toDouble(),
            );
          }).toList();
          loaded[pageIdx] = strokes;
        });
        if (mounted) setState(() => _pageStrokes.addAll(loaded));
      }
      final notesJson = prefs.getString(_notesKey);
      if (notesJson != null) {
        final List decoded = jsonDecode(notesJson);
        if (mounted) {
          setState(() {
            _savedNotes.addAll(decoded.map((n) =>
              Map<String, String>.from(n as Map)));
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveStrokes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> toSave = {};
      _pageStrokes.forEach((pageIdx, strokes) {
        toSave[pageIdx.toString()] = strokes.map((s) => {
          'points': s.points
              .whereType<Offset>()
              .map((p) => {'x': p.dx, 'y': p.dy})
              .toList(),
          'color': s.color.toARGB32(),
          'width': s.width,
        }).toList();
      });
      await prefs.setString(_strokesKey, jsonEncode(toSave));
      setState(() => _strokesSaved = true);

      final totalStrokes = _pageStrokes.values
          .fold<int>(0, (sum, list) => sum + list.length);
      final now = DateTime.now();
      final savedAt =
          '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')} '
          '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
      await NoteRepository().saveNoteMeta(NoteMetaData(
        lectureId:      _lecture.id,
        lectureTitle:   _lecture.title,
        subject:        _lecture.subject,
        instructorName: _lecture.instructor,
        savedAt:        savedAt,
        strokeCount:    totalStrokes,
        memoCount:      _savedNotes.length,
        handoutUrls:    _lecture.handoutUrls,
        thumbnailUrl:   _lecture.thumbnailUrl,
      ));

      // 저장 완료 (저장됨 아이콘으로 확인 가능하므로 SnackBar 생략)
    } catch (_) {}
  }

  Future<void> _clearCurrentPageStrokes() async {
    setState(() {
      _pageStrokes[_currentNotePageIndex]?.clear();
      _pageStrokes.remove(_currentNotePageIndex);
      _strokesSaved = false;
    });
    await _saveStrokes();
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _loadLecture();
    }
  }

  void _goNext() {
    if (_currentIndex < widget.lectures.length - 1) {
      setState(() => _currentIndex++);
      _loadLecture();
    }
  }

  void _openVideo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LecturePlayerScreen(lecture: _lecture),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPrev = _currentIndex > 0;
    final hasNext = _currentIndex < widget.lectures.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      // ── 상단 AppBar ──────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
          tooltip: '뒤로',
        ),
        titleSpacing: 0,
        title: Row(children: [
          // 과목 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _subjectColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _subjectColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              _lecture.subject,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _subjectColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 강의 제목
          Expanded(
            child: Text(
              _lecture.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        actions: [
          // 강의 번호 뱃지
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_currentIndex + 1} / ${widget.lectures.length}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      // ── Body ─────────────────────────────────────────
      body: _slidesLoading
          ? const Center(child: CircularProgressIndicator(color: _kOrange))
          : _notePages.isEmpty
              ? _buildEmpty()
              : Stack(children: [
                  // 교안 + 필기 영역
                  _buildSlideNote(),

                  // ── 하단 플로팅 액션 바 ──────────────
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    child: _buildBottomActionBar(hasPrev, hasNext),
                  ),
                ]),
    );
  }

  // 과목 색상
  Color get _subjectColor {
    switch (_lecture.subject) {
      case '수학': return const Color(0xFF2563EB);
      case '과학': return const Color(0xFF16A34A);
      case '물리': return const Color(0xFF0EA5E9);
      case '화학': return const Color(0xFF7C3AED);
      case '생명과학': return const Color(0xFF22C55E);
      case '지구과학': return const Color(0xFF6366F1);
      default: return _kOrange;
    }
  }

  // ── 하단 플로팅 액션 바 ─────────────────────────
  Widget _buildBottomActionBar(bool hasPrev, bool hasNext) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(children: [
          // ① 영상 재생
          _buildActionItem(
            icon: Icons.play_circle_rounded,
            label: '영상',
            color: const Color(0xFF34D399),
            onTap: _openVideo,
          ),
          _buildDivider(),
          // ② 필기 토글
          _buildActionItem(
            icon: _isDrawingMode ? Icons.edit_rounded : Icons.edit_outlined,
            label: _isDrawingMode ? '필기 중' : '필기',
            color: _isDrawingMode ? const Color(0xFF60A5FA) : Colors.white60,
            onTap: () => setState(() => _isDrawingMode = !_isDrawingMode),
            isActive: _isDrawingMode,
            activeColor: const Color(0xFF60A5FA),
          ),
          // ③ 저장 (필기 중일 때만)
          if (_isDrawingMode) ...[  
            _buildDivider(),
            _buildActionItem(
              icon: _strokesSaved ? Icons.check_circle_rounded : Icons.save_rounded,
              label: _strokesSaved ? '저장됨' : '저장',
              color: _strokesSaved ? Colors.white38 : const Color(0xFFFBBF24),
              onTap: _strokesSaved ? null : _saveStrokes,
            ),
          ],
          const Spacer(),
          _buildDivider(),
          // ④ 이전 강의
          _buildNavItem(
            icon: Icons.skip_previous_rounded,
            label: '이전',
            enabled: hasPrev,
            onTap: _goPrev,
          ),
          // ⑤ 다음 강의
          _buildNavItem(
            icon: Icons.skip_next_rounded,
            label: '다음',
            enabled: hasNext,
            onTap: _goNext,
          ),
          const SizedBox(width: 4),
        ]),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool isActive = false,
    Color? activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (activeColor ?? color).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: onTap == null ? Colors.white24 : color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: onTap == null ? Colors.white24 : color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: enabled ? Colors.white : Colors.white24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.white70 : Colors.white24,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  // ── 플레이어와 동일한 교안+필기 뷰 ─────────────
  Widget _buildSlideNote() {
    return Column(children: [
      // ── 툴바 행 1: 모드 전환 + 저장 ──
      Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(children: [
          _buildModeBtn(
            icon: Icons.zoom_in_rounded,
            label: '확대/축소',
            active: !_isDrawingMode,
            onTap: () => setState(() => _isDrawingMode = false),
          ),
          const SizedBox(width: 6),
          _buildModeBtn(
            icon: Icons.edit_rounded,
            label: '필기',
            active: _isDrawingMode,
            onTap: () => setState(() => _isDrawingMode = true),
          ),
          const Spacer(),
          if (_isDrawingMode)
            GestureDetector(
              onTap: _saveStrokes,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _strokesSaved
                      ? Colors.grey.shade100
                      : const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _strokesSaved
                        ? Colors.grey.shade300
                        : const Color(0xFF2563EB)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    _strokesSaved ? Icons.check_rounded : Icons.save_outlined,
                    size: 14,
                    color: _strokesSaved ? AppColors.textSecondary : Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _strokesSaved ? '저장됨' : '저장',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: _strokesSaved ? AppColors.textSecondary : Colors.white,
                    ),
                  ),
                ]),
              ),
            ),
          // 강의 제목 간략 표시
          if (!_isDrawingMode) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _lecture.title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ]),
      ),
      // ── 툴바 행 2: 필기 도구 (필기 모드일 때만) ──
      if (_isDrawingMode)
        Container(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
          color: const Color(0xFFFAFAFA),
          child: Row(children: [
            const Text('색상:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(width: 6),
            for (final c in [
              const Color(0xFF2563EB), Colors.red, const Color(0xFF16A34A), _kOrange, Colors.black,
            ])
              GestureDetector(
                onTap: () => setState(() {
                  _penColor = c;
                  _isEraser = false;
                  _isDrawingMode = true;
                }),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: c, shape: BoxShape.circle,
                    border: _penColor == c && !_isEraser
                        ? Border.all(
                            color: (c.red > 180 && c.green < 100 && c.blue < 100)
                                ? Colors.white
                                : _kOrange,
                            width: 2.5)
                        : null,
                    boxShadow: _penColor == c && !_isEraser
                        ? [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4, spreadRadius: 1)]
                        : null,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            // 지우개
            GestureDetector(
              onTap: () => setState(() => _isEraser = !_isEraser),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isEraser ? _kOrange.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isEraser ? _kOrange : Colors.grey.shade300),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  EraserIcon(isActive: _isEraser, size: 18),
                  const SizedBox(width: 3),
                  Text('지우개', style: TextStyle(
                    fontSize: 10,
                    color: _isEraser ? _kOrange : AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const Spacer(),
            // 현재 페이지 필기 삭제
            GestureDetector(
              onTap: _clearCurrentPageStrokes,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.delete_outline_rounded, size: 14, color: Colors.red.shade400),
                  const SizedBox(width: 3),
                  Text('이 페이지 삭제', style: TextStyle(
                    fontSize: 10, color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),
      // ── 교안 스크롤 영역 (플레이어와 동일 구조) ──
      Expanded(
        child: SingleChildScrollView(
          physics: _isDrawingMode
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          // 하단 액션바(56px) + 여유 공간이 가리지 않도록 패딩 추가
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 88),
          child: Column(
            children: List.generate(_notePages.length, (pageIdx) {
              final pageUrl = _notePages[pageIdx];

              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                color: Colors.white,
                child: Column(children: [
                  // 페이지 번호 헤더
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    color: const Color(0xFFF5F7FA),
                    child: Row(children: [
                      Text('${pageIdx + 1} / ${_notePages.length}페이지',
                        style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  // 이미지 + 필기 레이어 + 터치 이벤트 (통합)
                  LayoutBuilder(builder: (lbCtx, lbConstraints) {
                    final imgW = lbConstraints.maxWidth > 0
                        ? lbConstraints.maxWidth
                        : MediaQuery.of(lbCtx).size.width;
                    final imgH = imgW * 577 / 1024;
                    return SizedBox(
                      width: imgW,
                      height: imgH,
                      child: GestureDetector(
                        onTapDown: _isDrawingMode
                            ? (d) => setState(() {
                                _currentNotePageIndex = pageIdx;
                                _currentStroke = [d.localPosition];
                              })
                            : null,
                        onPanStart: _isDrawingMode
                            ? (d) => setState(() {
                                _currentNotePageIndex = pageIdx;
                                _currentStroke = [d.localPosition];
                              })
                            : null,
                        onPanUpdate: _isDrawingMode
                            ? (d) {
                                setState(() {
                                  _currentStroke.add(d.localPosition);
                                  if (_isEraser) {
                                    _eraserPosition = d.localPosition;
                                    _showEraserCursor = true;
                                    final strokes = List<_DrawingStroke>.from(
                                        _pageStrokes[pageIdx] ?? []);
                                    const eraseRadius = 20.0;
                                    final idx = strokes.indexWhere((s) =>
                                        s.points.whereType<Offset>().any(
                                            (p) => (p - d.localPosition).distance < eraseRadius));
                                    if (idx != -1) {
                                      strokes.removeAt(idx);
                                      _pageStrokes[pageIdx] = strokes;
                                      _strokesSaved = false;
                                    }
                                  }
                                });
                              }
                            : null,
                        onPanEnd: _isDrawingMode
                            ? (_) {
                                if (!_isEraser && _currentStroke.isNotEmpty) {
                                  final strokes = List<_DrawingStroke>.from(
                                      _pageStrokes[pageIdx] ?? []);
                                  strokes.add(_DrawingStroke(
                                    points: List.from(_currentStroke),
                                    color: _penColor, width: _strokeWidth));
                                  setState(() {
                                    _pageStrokes[pageIdx] = strokes;
                                    _strokesSaved = false;
                                  });
                                }
                                setState(() {
                                  _currentStroke = [];
                                  _showEraserCursor = false;
                                  _eraserPosition = null;
                                });
                              }
                            : null,
                        child: Stack(
                          children: [
                            // 교안 이미지 (1024×577 비율로 정확히 표시)
                            Positioned.fill(
                              child: Image(
                                image: pageUrl.startsWith('assets/')
                                    ? AssetImage(pageUrl) as ImageProvider
                                    : NetworkImage(pageUrl),
                                width: imgW,
                                height: imgH,
                                fit: BoxFit.fill,
                                errorBuilder: (_, __, ___) => _buildHandoutError(pageIdx),
                              ),
                            ),
                            // 필기 레이어
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _DrawingPainter(
                                  strokes: _pageStrokes[pageIdx] ?? [],
                                  currentStroke: _currentNotePageIndex == pageIdx
                                      ? _currentStroke
                                      : [],
                                  currentColor: _penColor,
                                  currentWidth: _strokeWidth,
                                  isEraser: _isEraser,
                                ),
                              ),
                            ),
                            // 지우개 커서
                            if (_isDrawingMode &&
                                _isEraser &&
                                _showEraserCursor &&
                                _eraserPosition != null &&
                                _currentNotePageIndex == pageIdx)
                              Positioned(
                                left: _eraserPosition!.dx - 10,
                                top: _eraserPosition!.dy - 10,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _kOrange, width: 1.5),
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ]),
              );
            }),
          ),
        ),
      ),
    ]);
  }

  Widget _buildHandoutError(int pageIdx) {
    return Container(
      height: 200,
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.description_outlined, size: 40, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text('교안 ${pageIdx + 1}페이지',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        ]),
      ),
    );
  }

  Widget _buildModeBtn({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14,
              color: active ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: active ? AppColors.primary : AppColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.menu_book_outlined, size: 64, color: AppColors.textHint),
        const SizedBox(height: 16),
        const Text('교안이 없는 강의입니다',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Text(_lecture.title,
            style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: _kOrange),
          onPressed: _openVideo,
          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          label: const Text('영상 보기', style: TextStyle(color: Colors.white)),
        ),
      ]),
    );
  }
}

// ── 필기 스트로크 모델 ─────────────────────────
class _DrawingStroke {
  final List<Offset?> points;
  final Color color;
  final double width;
  _DrawingStroke({required this.points, required this.color, required this.width});
}

// ── 필기 CustomPainter ────────────────────────
class _DrawingPainter extends CustomPainter {
  final List<_DrawingStroke> strokes;
  final List<Offset?> currentStroke;
  final Color currentColor;
  final double currentWidth;
  final bool isEraser;

  const _DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentWidth,
    required this.isEraser,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.color, stroke.width);
    }
    if (currentStroke.isNotEmpty && !isEraser) {
      _drawStroke(canvas, currentStroke, currentColor, currentWidth);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset?> points, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    bool started = false;
    for (final pt in points) {
      if (pt == null) { started = false; continue; }
      if (!started) { path.moveTo(pt.dx, pt.dy); started = true; }
      else { path.lineTo(pt.dx, pt.dy); }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DrawingPainter old) => true;
}
