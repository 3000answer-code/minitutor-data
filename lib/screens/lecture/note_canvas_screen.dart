import 'package:flutter/material.dart';
import '../../models/lecture.dart';
import '../../models/note.dart';
import '../../theme/app_theme.dart';

class NoteCanvasScreen extends StatefulWidget {
  final Lecture lecture;
  const NoteCanvasScreen({super.key, required this.lecture});

  @override
  State<NoteCanvasScreen> createState() => _NoteCanvasScreenState();
}

class _NoteCanvasScreenState extends State<NoteCanvasScreen> {
  // ── 도구 상태 ──────────────────────────────────────
  final List<NoteStroke> _strokes = [];
  final List<List<NoteStroke>> _undoStack = [];
  NoteStroke? _currentStroke;

  bool _isToolOpen = false;
  bool _isEraser = false;
  int _selectedColorIndex = 0;
  double _strokeWidth = 3.0;

  final List<Color> _penColors = [
    const Color(0xFF1E40AF), // 파랑
    const Color(0xFFDC2626), // 빨강
    const Color(0xFF16A34A), // 초록
  ];

  final List<String> _penColorNames = ['파랑 펜', '빨강 펜', '초록 펜'];

  // ── 노트 텍스트 목록 (기존 텍스트 노트) ────────────
  final List<Map<String, String>> _textNotes;

  _NoteCanvasScreenState() : _textNotes = [];

  @override
  void initState() {
    super.initState();
    // 샘플 배경 격자선 (교안 느낌)
  }

  Color get _currentColor =>
      _isEraser ? Colors.white : _penColors[_selectedColorIndex];

  double get _currentWidth => _isEraser ? 20.0 : _strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => _confirmExit(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.lecture.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${widget.lecture.subject} · ${widget.lecture.gradeText}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          // 실행 취소
          IconButton(
            icon: Icon(Icons.undo_rounded,
              color: _strokes.isNotEmpty ? AppColors.primary : AppColors.textHint),
            onPressed: _strokes.isNotEmpty ? _undo : null,
            tooltip: '실행취소',
          ),
          // 전체 지우기
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textHint),
            onPressed: _strokes.isNotEmpty ? _showClearDialog : null,
            tooltip: '전체 지우기',
          ),
          // 저장
          TextButton.icon(
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('저장', style: TextStyle(fontWeight: FontWeight.w700)),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            onPressed: _saveNote,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Stack(
        children: [
          // ── 캔버스 영역 ──────────────────────────────
          _buildCanvas(),
          // ── 필기 도구 팔레트 ─────────────────────────
          Positioned(
            right: 16,
            bottom: 100,
            child: _buildToolPalette(),
          ),
          // ── 도구 열기 버튼 ───────────────────────────
          Positioned(
            right: 16,
            bottom: 40,
            child: _buildToolToggleButton(),
          ),
        ],
      ),
    );
  }

  // ── 캔버스 ────────────────────────────────────────
  Widget _buildCanvas() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFFFFDE7), // 약간 노란빛 교안 느낌
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _currentStroke = NoteStroke(
              points: [details.localPosition],
              color: _currentColor,
              strokeWidth: _currentWidth,
              isEraser: _isEraser,
            );
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _currentStroke = NoteStroke(
              points: [...(_currentStroke?.points ?? []), details.localPosition],
              color: _currentColor,
              strokeWidth: _currentWidth,
              isEraser: _isEraser,
            );
          });
        },
        onPanEnd: (_) {
          if (_currentStroke != null) {
            setState(() {
              _strokes.add(_currentStroke!);
              _currentStroke = null;
              _undoStack.clear();
            });
          }
        },
        child: CustomPaint(
          painter: _NotePainter(
            strokes: _strokes,
            currentStroke: _currentStroke,
          ),
          child: Container(),
        ),
      ),
    );
  }

  // ── 도구 팔레트 ──────────────────────────────────
  Widget _buildToolPalette() {
    if (!_isToolOpen) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: _isToolOpen ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 굵기 조절
            const Text('굵기', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
            const SizedBox(height: 4),
            SizedBox(
              width: 44,
              child: Column(children: [
                _buildWidthButton(2.0, '가는'),
                const SizedBox(height: 4),
                _buildWidthButton(4.0, '중간'),
                const SizedBox(height: 4),
                _buildWidthButton(7.0, '굵은'),
              ]),
            ),
            const SizedBox(height: 12),
            const Divider(height: 0),
            const SizedBox(height: 12),
            // 색상 선택
            const Text('색상', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
            const SizedBox(height: 6),
            ..._penColors.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedColorIndex = e.key;
                  _isEraser = false;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: e.value,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: !_isEraser && _selectedColorIndex == e.key
                          ? AppColors.textPrimary : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: !_isEraser && _selectedColorIndex == e.key
                        ? [BoxShadow(color: e.value.withValues(alpha: 0.5), blurRadius: 8)]
                        : null,
                  ),
                  child: !_isEraser && _selectedColorIndex == e.key
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : null,
                ),
              ),
            )),
            const SizedBox(height: 4),
            const Divider(height: 0),
            const SizedBox(height: 8),
            // 지우개
            GestureDetector(
              onTap: () => setState(() => _isEraser = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _isEraser ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isEraser ? AppColors.primary : AppColors.divider,
                    width: _isEraser ? 2 : 1,
                  ),
                ),
                child: Icon(Icons.auto_fix_normal_rounded,
                  size: 20,
                  color: _isEraser ? AppColors.primary : AppColors.textHint),
              ),
            ),
            const SizedBox(height: 4),
            Text('지우개', style: TextStyle(fontSize: 9,
              color: _isEraser ? AppColors.primary : AppColors.textHint)),
          ],
        ),
      ),
    );
  }

  Widget _buildWidthButton(double width, String label) {
    final isSelected = (_strokeWidth == width) && !_isEraser;
    return GestureDetector(
      onTap: () => setState(() {
        _strokeWidth = width;
        _isEraser = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44, height: 28,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider),
        ),
        child: Center(
          child: Container(
            height: width.clamp(1.5, 5),
            width: 24,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.textHint,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolToggleButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 현재 선택된 도구 표시
        if (_isToolOpen)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isEraser ? '지우개' : _penColorNames[_selectedColorIndex],
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        GestureDetector(
          onTap: () => setState(() => _isToolOpen = !_isToolOpen),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: _isToolOpen ? AppColors.primary : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: _isEraser
                ? Icon(Icons.auto_fix_normal_rounded,
                    color: _isToolOpen ? Colors.white : AppColors.primary, size: 26)
                : Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isToolOpen ? Colors.white : _penColors[_selectedColorIndex],
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ── 액션 ──────────────────────────────────────────
  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _undoStack.add([..._strokes]);
      _strokes.removeLast();
    });
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('전체 지우기'),
        content: const Text('모든 필기 내용을 지우시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              setState(() => _strokes.clear());
              Navigator.pop(context);
            },
            child: const Text('지우기'),
          ),
        ],
      ),
    );
  }

  void _saveNote() {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('필기 내용이 없습니다. 먼저 노트를 작성해주세요.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.save_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          Text('노트 저장'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('노트가 저장되었습니다!'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.note_alt_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.lecture.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('필기 ${_strokes.length}획 · 나의 활동 > 내 노트에 저장됨',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ])),
            ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    if (_strokes.isEmpty) { Navigator.pop(context); return; }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('나가기'),
        content: const Text('저장하지 않은 필기 내용이 있습니다.\n저장하지 않고 나가시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('계속 작성')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }
}

// ── 커스텀 페인터 ─────────────────────────────────────
class _NotePainter extends CustomPainter {
  final List<NoteStroke> strokes;
  final NoteStroke? currentStroke;

  _NotePainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    // 배경 격자선 (교안 느낌)
    _drawGrid(canvas, size);

    // 완성된 선들
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    // 현재 그리는 중인 선
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0).withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    const spacing = 28.0;

    // 수평선
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // 수직선
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  void _drawStroke(Canvas canvas, NoteStroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = stroke.isEraser ? Colors.white : stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = stroke.isEraser ? BlendMode.src : BlendMode.srcOver;

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

    for (int i = 1; i < stroke.points.length - 1; i++) {
      final mid = Offset(
        (stroke.points[i].dx + stroke.points[i + 1].dx) / 2,
        (stroke.points[i].dy + stroke.points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(
        stroke.points[i].dx, stroke.points[i].dy,
        mid.dx, mid.dy,
      );
    }
    path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_NotePainter oldDelegate) => true;
}
