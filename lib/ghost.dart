import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Gaspi's vector mark. Motion follows the system's reduced-motion setting.
class GhostMark extends StatefulWidget {
  const GhostMark({super.key, this.size = 36, this.animated = true});
  final double size;
  final bool animated;
  @override
  State<GhostMark> createState() => _GhostMarkState();
}

class _GhostMarkState extends State<GhostMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();
  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = !widget.animated || MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Gaspi, un pequeño fantasma',
      image: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: motion,
          builder: (_, _) {
            final phase = still ? 0.0 : motion.value;
            return CustomPaint(
              painter: _GhostPainter(
                Theme.of(context).colorScheme.onSurface,
                phase,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GhostPainter extends CustomPainter {
  const _GhostPainter(this.color, this.phase);
  final Color color;
  final double phase;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final float = math.sin(phase * math.pi * 2) * 3;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(50, 92),
        width: 40 - float,
        height: 4,
      ),
      Paint()..color = color.withValues(alpha: .10),
    );
    canvas.translate(0, float);
    final body = Path()
      ..moveTo(22, 78)
      ..lineTo(22, 42)
      ..cubicTo(22, 5, 78, 5, 78, 42)
      ..lineTo(78, 78)
      ..quadraticBezierTo(77, 84, 71, 79)
      ..quadraticBezierTo(65, 70, 59, 80)
      ..quadraticBezierTo(54, 87, 48, 79)
      ..quadraticBezierTo(42, 71, 36, 80)
      ..quadraticBezierTo(29, 88, 22, 78)
      ..close();
    canvas.drawPath(body, Paint()..color = color);
    final eye = Color.lerp(
      color,
      color.computeLuminance() > .5 ? Colors.black : Colors.white,
      1,
    )!;
    final blink = phase > .84 && phase < .90 ? .18 : 1.0;
    final paint = Paint()..color = eye;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(40, 45),
        width: 6.5,
        height: 10 * blink,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(60, 45),
        width: 6.5,
        height: 10 * blink,
      ),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(46, 59)
        ..quadraticBezierTo(50, 63, 54, 59),
      Paint()
        ..color = eye
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GhostPainter old) =>
      phase != old.phase || color != old.color;
}
