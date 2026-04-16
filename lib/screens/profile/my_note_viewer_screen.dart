import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/lecture.dart';
import '../../services/app_state.dart';
import '../../services/note_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eraser_widgets.dart';
import '../lecture/lecture_player_screen.dart';

const Color _kOrange = Color(0xFFF97316);

/// 내 노트 전용 뷰어: 교안 + 필기 + 하단 미니플레이어 + 이전/다음
class MyNoteViewerScreen extends StatefulWidget {
  final Lecture lecture;
  /// 이전/다음 이동을 위한 전체 강의 목록 (없으면 이전/다음 버튼 숨김)
  final List<Lecture>? lectureList;
  /// 강의 플레이어에서 인라인(BottomSheet)으로 열린 경우 true
  final bool fromPlayer;
  /// DraggableScrollableSheet 스크롤 컨트롤러
  final ScrollController? scrollController;
  const MyNoteViewerScreen({
    super.key,
    required this.lecture,
    this.lectureList,
    this.fromPlayer = false,
    this.scrollController,
  });

  @override
  State<MyNoteViewerScreen> createState() => _MyNoteViewerScreenState();
}

class _MyNoteViewerScreenState extends State<MyNoteViewerScreen> {
  // ── 필기 상태 ───────────────────────────────
  bool _isDrawingMode = false;
  bool _isEraser = false;
  bool _strokesSaved = true;
  Color _penColor = const Color(0xFF2563EB);
  double _strokeWidth = 3.0;

  // 지우개 커서 위치
  Offset? _eraserPosition;
  bool _showEraserCursor = false;

  final Map<int, List<_StrokeData>> _pageStrokes = {};
  List<Offset?> _currentStroke = [];
  int _activePageIdx = -1;   // ← 현재 필기 중인 페이지 인덱스 (-1이면 비활성)

  List<String> _notePages = [];
  bool _slidesLoading = true;

  // ── 이전·다음 강의 이동 ──────────────────────
  late Lecture _currentLecture;      // 현재 보는 강의

  String get _strokesKey => 'strokes_${_currentLecture.id}';

  final List<Color> _penColors = [
    const Color(0xFF2563EB),
    const Color(0xFFDC2626),
    const Color(0xFF16A34A),
    const Color(0xFFF97316),
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    _currentLecture = widget.lecture;
    _loadPages();
    _loadStrokes();
  }

  void _loadPages() {
    final urls = _currentLecture.handoutUrls;
    if (urls.isNotEmpty) {
      setState(() {
        _notePages = urls;
        _slidesLoading = false;
      });
    } else {
      setState(() => _slidesLoading = false);
    }
  }

  Future<void> _loadStrokes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_strokesKey);
      if (json == null) return;
      final Map<String, dynamic> decoded = jsonDecode(json);
      final loaded = <int, List<_StrokeData>>{};
      decoded.forEach((key, val) {
        final idx = int.tryParse(key) ?? 0;
        final list = (val as List).map((s) {
          final pts = (s['points'] as List).map((p) {
            if (p == null) return null;
            return Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble());
          }).toList();
          return _StrokeData(
            points: pts,
            color: Color(s['color'] as int),
            width: (s['width'] as num).toDouble(),
          );
        }).toList();
        loaded[idx] = list;
      });
      if (mounted) setState(() => _pageStrokes.addAll(loaded));
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

      // NoteRepository 메타 업데이트
      final totalStrokes = _pageStrokes.values.fold<int>(0, (s, l) => s + l.length);
      final now = DateTime.now();
      final savedAt =
          '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')} '
          '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
      await NoteRepository().saveNoteMeta(NoteMetaData(
        lectureId: _currentLecture.id,
        lectureTitle: _currentLecture.title,
        subject: _currentLecture.subject,
        instructorName: _currentLecture.instructor,
        savedAt: savedAt,
        strokeCount: totalStrokes,
        memoCount: 0,
        handoutUrls: _currentLecture.handoutUrls,
        thumbnailUrl: _currentLecture.thumbnailUrl,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('내 노트가 저장되었습니다'),
          ]),
          backgroundColor: const Color(0xFF2563EB),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final allLectures = widget.lectureList;
    final currentIdx = allLectures?.indexWhere((l) => l.id == _currentLecture.id) ?? -1;
    final hasPrev = allLectures != null && currentIdx > 0;
    final hasNext = allLectures != null && currentIdx < allLectures.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        // fromPlayer면 '닫기(↓)' 아이콘, 아니면 기본 뒤로가기
        leading: widget.fromPlayer
            ? IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 26),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('내 노트',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          Text(_currentLecture.title,
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // 저장 버튼
          GestureDetector(
            onTap: _saveStrokes,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _strokesSaved
                    ? Colors.white24
                    : const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  _strokesSaved ? Icons.check_rounded : Icons.save_outlined,
                  size: 15, color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _strokesSaved ? '저장됨' : '저장',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ]),
            ),
          ),
        ],
      ),
      body: _slidesLoading
          ? const Center(child: CircularProgressIndicator(color: _kOrange))
          : _notePages.isEmpty
              ? _buildEmpty()
              : Stack(children: [
                  // 툴바 + 교안 영역
                  Column(children: [
                    _buildToolbar(),
                    Expanded(child: _buildPageList()),
                    // 하단 플로팅 바 높이만큼 여백 (겹침 방지)
                    const SizedBox(height: 72),
                  ]),
                  // ── 하단 플로팅 액션 바 (886과 동일한 형태) ──
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 12,
                    child: _buildFloatingActionBar(hasPrev, hasNext,
                      onPrev: hasPrev ? () => _navigateLecture(allLectures![currentIdx - 1]) : null,
                      onNext: hasNext ? () => _navigateLecture(allLectures![currentIdx + 1]) : null,
                    ),
                  ),
                ]),
    );
  }

  /// 강의 플레이어로 이동 (fromPlayer=true면 pop, false면 push)
  void _goToPlayer() {
    if (widget.fromPlayer) {
      // BottomSheet에서 열린 경우 → 닫으면 플레이어로 돌아감
      Navigator.of(context).pop();
    } else {
      // MyActivityScreen 탭에서 열린 경우 → 강의 플레이어로 push
      final appState = context.read<AppState>();
      if (appState.pipActive && appState.pipLecture?.id != _currentLecture.id) {
        appState.deactivatePip();
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LecturePlayerScreen(lecture: _currentLecture),
        ),
      );
    }
  }

  /// 다른 강의 노트로 이동
  void _navigateLecture(Lecture lecture) {
    _saveStrokes();
    setState(() {
      _currentLecture = lecture;
      _notePages = [];
      _pageStrokes.clear();
      _currentStroke = [];
      _activePageIdx = -1;
      _slidesLoading = true;
    });
    _loadPages();
    _loadStrokes();
  }

  // ── 하단 플로팅 액션 바 (886 노트검색과 동일한 형태) ────
  Widget _buildFloatingActionBar(bool hasPrev, bool hasNext,
      {VoidCallback? onPrev, VoidCallback? onNext}) {
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
            onTap: _goToPlayer,
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
            onTap: onPrev ?? () {},
          ),
          // ⑤ 다음 강의
          _buildNavItem(
            icon: Icons.skip_next_rounded,
            label: '다음',
            enabled: hasNext,
            onTap: onNext ?? () {},
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
            Icon(icon, size: 22,
                color: enabled ? Colors.white : Colors.white24),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: enabled ? Colors.white70 : Colors.white24,
                  letterSpacing: 0.2,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1, height: 28,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  // ── 빈 상태 ─────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.note_alt_outlined, size: 64, color: AppColors.textHint),
        const SizedBox(height: 16),
        const Text('교안이 없는 강의입니다',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Text(_currentLecture.title,
            style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
      ]),
    );
  }

  // ── 툴바 (886 형식과 동일한 2행 구조) ──────────
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(children: [
        // 행 1: 모드 전환 + 저장 버튼
        Row(children: [
          _buildModeBtn(Icons.zoom_in_rounded, '확대/축소', !_isDrawingMode,
              () => setState(() => _isDrawingMode = false)),
          const SizedBox(width: 6),
          _buildModeBtn(Icons.edit_rounded, '필기', _isDrawingMode,
              () => setState(() => _isDrawingMode = true)),
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
        ]),
        // 행 2: 색상 + 지우개 + 삭제 (필기 모드 시, 886과 동일한 구조)
        if (_isDrawingMode)
          Container(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 2),
            child: Row(children: [
              const Text('색상:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(width: 6),
              for (final c in _penColors)
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
                onTap: _clearCurrentPage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.delete_outline_rounded, size: 14, color: Colors.red.shade400),
                    const SizedBox(width: 3),
                    Text('초기화', style: TextStyle(
                      fontSize: 10, color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
          ),
      ]),
    );
  }

  Widget _buildModeBtn(IconData icon, String label, bool active, VoidCallback onTap) {
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

  void _clearCurrentPage() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // 아이콘 + 제목
            Row(children: const [
              Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red),
              SizedBox(width: 6),
              Text('필기 전체 초기화',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            const Text('모든 페이지 필기를 삭제합니다.\n복구할 수 없습니다.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
            const SizedBox(height: 14),
            // 버튼 행
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Text('취소',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: Color(0xFF475569))),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _pageStrokes.clear();
                    _currentStroke.clear();
                    _activePageIdx = -1;
                    _strokesSaved = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Text('삭제',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── 페이지 목록 ─────────────────────────────
  Widget _buildPageList() {
    // DraggableScrollableSheet에서 전달된 scrollController 사용 (없으면 자체 생성)
    return Stack(children: [
      SingleChildScrollView(
        controller: _isDrawingMode ? null : widget.scrollController,
        physics: _isDrawingMode ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
        child: Column(children: List.generate(_notePages.length, (pageIdx) {
          final pageUrl = _notePages[pageIdx];
          final strokes = _pageStrokes[pageIdx] ?? [];
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            child: Column(children: [
              // 페이지 헤더
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                color: const Color(0xFFEEEEEE),
                child: Row(children: [
                  Text('${pageIdx + 1} / ${_notePages.length} 페이지',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ]),
              ),
              // 교안 + 필기 영역
              LayoutBuilder(builder: (ctx, constraints) {
                final w = constraints.maxWidth;
                return _isDrawingMode
                    ? GestureDetector(
                        onPanStart: (d) {
                          setState(() {
                            _activePageIdx = pageIdx;   // ← 이 페이지만 활성화
                            _currentStroke = [d.localPosition];
                            _strokesSaved = false;
                            if (_isEraser) {
                              _eraserPosition = d.localPosition;
                              _showEraserCursor = true;
                            }
                          });
                        },
                        onPanUpdate: (d) {
                          if (_activePageIdx != pageIdx) return; // ← 다른 페이지 무시
                          setState(() {
                            _currentStroke.add(d.localPosition);
                            if (_isEraser) {
                              _eraserPosition = d.localPosition;
                              _eraseAt(pageIdx, d.localPosition, w);
                            }
                          });
                        },
                        onPanEnd: (_) {
                          if (_activePageIdx != pageIdx) return; // ← 다른 페이지 무시
                          if (!_isEraser && _currentStroke.isNotEmpty) {
                            setState(() {
                              _pageStrokes.putIfAbsent(pageIdx, () => [])
                                  .add(_StrokeData(
                                    points: List.from(_currentStroke),
                                    color: _penColor,
                                    width: _strokeWidth,
                                  ));
                              _currentStroke = [];
                              _activePageIdx = -1;    // ← 활성 페이지 해제
                              _strokesSaved = false;
                            });
                          } else {
                            setState(() {
                              _currentStroke = [];
                              _activePageIdx = -1;    // ← 활성 페이지 해제
                              _showEraserCursor = false;
                              _eraserPosition = null;
                            });
                          }
                        },
                        child: Stack(children: [
                          _buildPageContent(pageIdx, pageUrl, strokes, w),
                          // 지우개 커서: 페이지 Stack 내부에 배치 → 스크롤 좌표 정확히 일치
                          if (_isEraser && _showEraserCursor &&
                              _activePageIdx == pageIdx &&  // ← 이 페이지에만 표시
                              _eraserPosition != null)
                            Positioned(
                              left: _eraserPosition!.dx - 16,
                              top: _eraserPosition!.dy - 16,
                              child: IgnorePointer(
                                child: EraserCursor(position: _eraserPosition!),
                              ),
                            ),
                        ]),
                      )
                    : InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 5.0,
                        child: _buildPageContent(pageIdx, pageUrl, strokes, w),
                      );
              }),
            ]),
          );
        })),
      ),
    ]);
  }

  void _eraseAt(int pageIdx, Offset pos, double width) {
    final strokes = _pageStrokes[pageIdx];
    if (strokes == null) return;
    const eraseRadius = 20.0;
    // 한 획씩 지우기: 반경에 닿은 첫 번째 획 하나만 제거
    final idx = strokes.indexWhere((stroke) =>
        stroke.points.whereType<Offset>().any(
            (p) => (p - pos).distance < eraseRadius));
    if (idx != -1) {
      strokes.removeAt(idx);
      _strokesSaved = false;
    }
  }

  Widget _buildPageContent(int pageIdx, String pageUrl, List<_StrokeData> strokes, double w) {
    // ← 현재 필기 중인 페이지에만 currentStroke 전달, 나머지 페이지는 빈 리스트
    final activeStroke = (_activePageIdx == pageIdx) ? _currentStroke : <Offset?>[];
    return SizedBox(
      width: w,
      child: Stack(children: [
        // 교안 이미지
        pageUrl.startsWith('assets/')
            ? Image.asset(pageUrl, width: w, fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => _buildImageError(w))
            : Image.network(pageUrl, width: w, fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => _buildImageError(w)),
        // 필기 레이어
        Positioned.fill(
          child: CustomPaint(
            painter: _StrokePainter(
              strokes: strokes,
              currentStroke: activeStroke,   // ← 해당 페이지에만 진행 중인 획 표시
              penColor: _penColor,
              strokeWidth: _strokeWidth,
              isEraser: _isEraser,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildImageError(double w) {
    return Container(
      width: w, height: 200,
      color: Colors.grey.shade100,
      child: const Center(child: Icon(Icons.image_not_supported_outlined,
          size: 48, color: AppColors.textHint)),
    );
  }
}

// ── 필기 데이터 모델 ─────────────────────────
class _StrokeData {
  final List<Offset?> points;
  final Color color;
  final double width;
  _StrokeData({required this.points, required this.color, required this.width});
}

// ── 필기 페인터 ──────────────────────────────
class _StrokePainter extends CustomPainter {
  final List<_StrokeData> strokes;
  final List<Offset?> currentStroke;
  final Color penColor;
  final double strokeWidth;
  final bool isEraser;

  _StrokePainter({
    required this.strokes,
    required this.currentStroke,
    required this.penColor,
    required this.strokeWidth,
    required this.isEraser,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.color, stroke.width);
    }
    if (currentStroke.isNotEmpty && !isEraser) {
      _drawStroke(canvas, currentStroke, penColor, strokeWidth);
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
  bool shouldRepaint(_StrokePainter old) => true;
}
