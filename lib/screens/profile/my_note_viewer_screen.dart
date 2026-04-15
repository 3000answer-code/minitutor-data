import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/lecture.dart';
import '../../services/note_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eraser_widgets.dart';

const Color _kOrange = Color(0xFFF97316);

/// 내 노트 전용 뷰어: 교안 + 필기 + 하단 미니플레이어 + 이전/다음
class MyNoteViewerScreen extends StatefulWidget {
  final Lecture lecture;
  /// 이전/다음 이동을 위한 전체 강의 목록 (없으면 이전/다음 버튼 숨김)
  final List<Lecture>? lectureList;
  const MyNoteViewerScreen({super.key, required this.lecture, this.lectureList});

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

  List<String> _notePages = [];
  bool _slidesLoading = true;

  // ── 미니플레이어 / 이전·다음 ──────────────────
  bool _miniPlayerVisible = true;    // 하단 미니플레이어 표시 여부
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('내 노트가 저장되었습니다'),
          ]),
          backgroundColor: Color(0xFF2563EB),
          duration: Duration(seconds: 2),
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
          // 영상으로 돌아가기 버튼
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.play_circle_outline_rounded, size: 15, color: Colors.white),
                SizedBox(width: 4),
                Text('영상', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
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
              : Column(children: [
                  _buildToolbar(),
                  Expanded(child: _buildPageList()),
                  // ── 하단 미니플레이어 + 이전/다음 바 ──
                  _buildBottomBar(hasPrev: hasPrev, hasNext: hasNext,
                    onPrev: hasPrev ? () => _navigateLecture(allLectures[currentIdx - 1]) : null,
                    onNext: hasNext ? () => _navigateLecture(allLectures[currentIdx + 1]) : null,
                  ),
                ]),
    );
  }

  /// 다른 강의 노트로 이동
  void _navigateLecture(Lecture lecture) {
    _saveStrokes();
    setState(() {
      _currentLecture = lecture;
      _notePages = [];
      _pageStrokes.clear();
      _currentStroke = [];
      _slidesLoading = true;
    });
    _loadPages();
    _loadStrokes();
  }

  /// 하단 미니플레이어 + 이전/다음 버튼 바
  Widget _buildBottomBar({
    required bool hasPrev,
    required bool hasNext,
    VoidCallback? onPrev,
    VoidCallback? onNext,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── 미니플레이어 (강의 영상으로 돌아가기) ──
        if (_miniPlayerVisible)
          GestureDetector(
            onTap: () => Navigator.of(context).pop(), // 영상 화면으로 복귀
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(bottom: BorderSide(color: Color(0xFF334155))),
              ),
              child: Row(children: [
                // 썸네일
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 48, height: 36,
                    color: const Color(0xFF334155),
                    child: _currentLecture.thumbnailUrl.isNotEmpty
                        ? Image.network(
                            _currentLecture.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.play_circle_rounded,
                                color: Colors.white54, size: 24),
                          )
                        : const Icon(Icons.play_circle_rounded,
                            color: Colors.white54, size: 24),
                  ),
                ),
                const SizedBox(width: 10),
                // 강의 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_currentLecture.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text(_currentLecture.instructor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white60)),
                    ],
                  ),
                ),
                // 컨트롤 버튼들
                Row(mainAxisSize: MainAxisSize.min, children: [
                  _miniPlayerBtn(Icons.play_arrow_rounded, '영상 보기', () => Navigator.of(context).pop()),
                  const SizedBox(width: 4),
                  _miniPlayerBtn(Icons.close_rounded, '닫기', () {
                    setState(() => _miniPlayerVisible = false);
                  }),
                ]),
              ]),
            ),
          ),
        // ── 이전 / 다음 강의 버튼 ──
        if (hasPrev || hasNext)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              // 이전 버튼
              Expanded(
                child: GestureDetector(
                  onTap: onPrev,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: hasPrev
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: hasPrev
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.skip_previous_rounded,
                            size: 18,
                            color: hasPrev
                                ? const Color(0xFF475569)
                                : const Color(0xFFCBD5E1)),
                        const SizedBox(width: 4),
                        Text('이전',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: hasPrev
                                    ? const Color(0xFF475569)
                                    : const Color(0xFFCBD5E1))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 다음 버튼
              Expanded(
                child: GestureDetector(
                  onTap: onNext,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: hasNext
                          ? const Color(0xFF0EA5E9)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: hasNext
                              ? const Color(0xFF0EA5E9)
                              : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('다음',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: hasNext
                                    ? Colors.white
                                    : const Color(0xFFCBD5E1))),
                        const SizedBox(width: 4),
                        Icon(Icons.skip_next_rounded,
                            size: 18,
                            color: hasNext
                                ? Colors.white
                                : const Color(0xFFCBD5E1)),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
      ]),
    );
  }

  Widget _miniPlayerBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
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

  // ── 툴바 ────────────────────────────────────
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(children: [
        // 행 1: 모드 전환
        Row(children: [
          _buildModeBtn(Icons.zoom_in_rounded, '확대/축소', !_isDrawingMode,
              () => setState(() => _isDrawingMode = false)),
          const SizedBox(width: 6),
          _buildModeBtn(Icons.edit_rounded, '필기', _isDrawingMode,
              () => setState(() => _isDrawingMode = true)),
          const Spacer(),
          if (_isDrawingMode) ...[
            // 지우개
            GestureDetector(
              onTap: () => setState(() => _isEraser = !_isEraser),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _isEraser ? Colors.orange.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isEraser ? _kOrange : Colors.grey.shade300),
                ),
                child: EraserIcon(isActive: _isEraser, size: 22),
              ),
            ),
            const SizedBox(width: 6),
            // 이 페이지 초기화
            GestureDetector(
              onTap: _clearCurrentPage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.delete_sweep_outlined, size: 14, color: Colors.red),
                  SizedBox(width: 3),
                  Text('초기화', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ]),
        // 행 2: 색상 선택 (항상 표시 - 색상 선택 시 자동 필기 모드 전환)
        if (!_isEraser)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              ..._penColors.map((c) => GestureDetector(
                onTap: () => setState(() {
                  _penColor = c;
                  _isEraser = false;
                  _isDrawingMode = true; // 색상 선택 시 자동 필기 모드 전환
                  _strokesSaved = false;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  width: _penColor == c ? 26 : 22,
                  height: _penColor == c ? 26 : 22,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _penColor == c ? Colors.black87 : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: _penColor == c
                        ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)]
                        : null,
                  ),
                ),
              )),
              const Spacer(),
              // 선 굵기
              ...([2.0, 3.0, 5.0].map((w) => GestureDetector(
                onTap: () => setState(() => _strokeWidth = w),
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _strokeWidth == w ? _penColor.withValues(alpha: 0.15) : Colors.transparent,
                    border: Border.all(
                      color: _strokeWidth == w ? _penColor : Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Container(
                      width: w * 2, height: w * 2,
                      decoration: BoxDecoration(
                        color: _penColor, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ))),
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
    // 현재 보이는 페이지 전체 삭제 (모든 페이지 초기화)
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('전체 필기 초기화'),
        content: const Text('모든 페이지의 필기를 삭제할까요?\n삭제된 필기는 복구할 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _pageStrokes.clear();
                _currentStroke.clear();
                _strokesSaved = false;
              });
            },
            child: const Text('삭제')),
        ],
      ),
    );
  }

  // ── 페이지 목록 ─────────────────────────────
  Widget _buildPageList() {
    return Stack(children: [
      SingleChildScrollView(
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
                            _currentStroke = [d.localPosition];
                            _strokesSaved = false;
                            if (_isEraser) {
                              _eraserPosition = d.localPosition;
                              _showEraserCursor = true;
                            }
                          });
                        },
                        onPanUpdate: (d) {
                          setState(() {
                            _currentStroke.add(d.localPosition);
                            if (_isEraser) {
                              _eraserPosition = d.localPosition;
                              _eraseAt(pageIdx, d.localPosition, w);
                            }
                          });
                        },
                        onPanEnd: (_) {
                          if (!_isEraser && _currentStroke.isNotEmpty) {
                            setState(() {
                              _pageStrokes.putIfAbsent(pageIdx, () => [])
                                  .add(_StrokeData(
                                    points: List.from(_currentStroke),
                                    color: _penColor,
                                    width: _strokeWidth,
                                  ));
                              _currentStroke = [];
                              _strokesSaved = false;
                            });
                          } else {
                            setState(() {
                              _currentStroke = [];
                              _showEraserCursor = false;
                              _eraserPosition = null;
                            });
                          }
                        },
                        child: Stack(children: [
                          _buildPageContent(pageIdx, pageUrl, strokes, w),
                          // 지우개 커서: 페이지 Stack 내부에 배치 → 스크롤 좌표 정확히 일치
                          if (_isEraser && _showEraserCursor &&
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
              currentStroke: _currentStroke,
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
