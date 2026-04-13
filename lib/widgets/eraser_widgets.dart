import 'package:flutter/material.dart';

const Color _kOrange = Color(0xFFF97316);

/// 지우개 아이콘 (커스텀 그림)
class EraserIcon extends StatelessWidget {
  final bool isActive;
  final double size;
  const EraserIcon({super.key, required this.isActive, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(painter: _EraserIconPainter(isActive: isActive)),
    );
  }
}

class _EraserIconPainter extends CustomPainter {
  final bool isActive;
  _EraserIconPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyColor = isActive ? const Color(0xFFFFF3E0) : const Color(0xFFE0E0E0);
    final bandColor = isActive ? _kOrange : const Color(0xFF9E9E9E);
    final borderColor = isActive ? _kOrange : const Color(0xFF757575);

    // 지우개 몸통
    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, size.height * 0.35, size.width - 2, size.height * 0.55),
      const Radius.circular(3),
    );
    canvas.drawRRect(body, bodyPaint);

    // 위 핑크 밴드
    final bandPaint = Paint()
      ..color = bandColor
      ..style = PaintingStyle.fill;
    final band = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, size.height * 0.35, size.width - 2, size.height * 0.22),
      const Radius.circular(3),
    );
    canvas.drawRRect(band, bandPaint);

    // 테두리
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(body, borderPaint);

    // 지우개 줄 (하이라이트)
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(4, size.height * 0.78),
      Offset(size.width - 4, size.height * 0.78),
      linePaint,
    );

    // 연필 자루 (위)
    final stickPaint = Paint()
      ..color = isActive ? Colors.deepOrange.shade200 : Colors.grey.shade400
      ..style = PaintingStyle.fill;
    final stick = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.3, 1, size.width * 0.4, size.height * 0.38),
      const Radius.circular(2),
    );
    canvas.drawRRect(stick, stickPaint);

    // 자루 테두리
    final stickBorder = Paint()
      ..color = borderColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(stick, stickBorder);
  }

  @override
  bool shouldRepaint(_EraserIconPainter old) => old.isActive != isActive;
}

/// 움직이는 지우개 커서 (필기 화면에서 지우기 중 표시)
class EraserCursor extends StatefulWidget {
  final Offset position;
  const EraserCursor({super.key, required this.position});

  @override
  State<EraserCursor> createState() => _EraserCursorState();
}

class _EraserCursorState extends State<EraserCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _wobble;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180))
      ..repeat(reverse: true);
    _wobble = Tween<double>(begin: -0.12, end: 0.12).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _scale = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.rotate(
        angle: _wobble.value,
        child: Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: _kOrange, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _kOrange.withValues(alpha: 0.3),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Center(
              child: EraserIcon(isActive: true, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}
