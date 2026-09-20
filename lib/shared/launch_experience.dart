import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/design.dart';

/// One finite introduction per process launch; never replays on resume or theme changes.
class LaunchExperience extends StatefulWidget {
  final Widget child;
  const LaunchExperience({super.key, required this.child});
  @override
  State<LaunchExperience> createState() => _LaunchExperienceState();
}

class _LaunchExperienceState extends State<LaunchExperience>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2600),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => finished = true);
        }
      });
  bool finished = false, started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      finished = true;
      animation.stop();
    } else if (!started && !finished) {
      started = true;
      animation.forward();
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (finished) return widget.child;
    return Scaffold(
      backgroundColor: context.dark
          ? const Color(0xFF102B24)
          : const Color(0xFFF6F7EA),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final t = animation.value;
                  final reveal = Curves.easeOutCubic.transform(
                    (t / .5).clamp(0, 1),
                  );
                  return Opacity(
                    opacity: 1 - ((t - .9) / .1).clamp(0, 1),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 36,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'A LITTLE CARE. A LOT OF GROWTH.',
                                textAlign: TextAlign.center,
                                style: context.type.labelSmall?.copyWith(
                                  letterSpacing: 2,
                                  color: context.dark
                                      ? Palette.lime
                                      : Palette.forest,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 380,
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1.12,
                                  child: Semantics(
                                    label: 'A smiling plant growing beside a rising three dimensional graph and floating coins',
                                    child: CustomPaint(
                                      painter: _GardenLaunchPainter(
                                        t,
                                        context.dark,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Transform.translate(
                                offset: Offset(0, 20 * (1 - reveal)),
                                child: Opacity(
                                  opacity: reveal,
                                  child: Column(
                                    children: [
                                      FittedBox(
                                        child: Text(
                                          'money plant.',
                                          style: context.type.displayLarge
                                              ?.copyWith(
                                                fontFamily: 'Outfit',
                                                fontSize: 53,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -2.4,
                                                color: context.dark
                                                    ? Palette.lime
                                                    : Palette.forest,
                                                shadows: [
                                                  Shadow(
                                                    color: context.dark
                                                        ? const Color(
                                                            0xFF3F6540,
                                                          )
                                                        : const Color(
                                                            0xFFCAD7B0,
                                                          ),
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        t < .5
                                            ? 'Tiny habits. Happy future.'
                                            : 'Chhoti savings, bade dreams. ✨',
                                        textAlign: TextAlign.center,
                                        style: context.type.titleMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: 64,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: t,
                                    minHeight: 4,
                                    color: context.dark
                                        ? Palette.lime
                                        : Palette.forest,
                                    backgroundColor: context.dark
                                        ? Colors.white12
                                        : const Color(0xFFDDE5CD),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 4,
              right: 12,
              child: TextButton(
                onPressed: () {
                  animation.stop();
                  setState(() => finished = true);
                },
                child: const Text('Skip intro'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GardenLaunchPainter extends CustomPainter {
  final double t;
  final bool dark;
  const _GardenLaunchPainter(this.t, this.dark);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 380, size.height / 340);
    final progress = Curves.easeOutCubic.transform((t / .72).clamp(0, 1));
    final float = math.sin(t * math.pi * 3) * 5;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          (dark ? Palette.lime : const Color(0xFFC4DE97)).withValues(
            alpha: .22,
          ),
          Colors.transparent,
        ],
      ).createShader(const Rect.fromLTWH(15, 5, 350, 320));
    canvas.drawOval(const Rect.fromLTWH(15, 5, 350, 320), glow);
    final orbit = Paint()
      ..color = (dark ? Palette.lime : Palette.forest).withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.save();
    canvas.translate(190, 195);
    canvas.rotate(-.22);
    canvas.drawOval(const Rect.fromLTRB(-167, -93, 167, 93), orbit);
    canvas.drawOval(const Rect.fromLTRB(-146, -80, 146, 80), orbit);
    canvas.restore();
    canvas.drawOval(
      const Rect.fromLTWH(56, 260, 276, 38),
      Paint()
        ..color = Colors.black.withValues(alpha: dark ? .2 : .06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    for (var i = 0; i < 3; i++) {
      final rise = Curves.easeOutBack.transform(
        ((t - i * .085) / .54).clamp(0, 1),
      );
      final x = 164.0 + i * 49;
      final h = (65.0 + i * 43) * rise;
      final color = [
        const Color(0xFFDBD0F4),
        const Color(0xFFB4D283),
        const Color(0xFF659B59),
      ][i];
      final front = Rect.fromLTWH(x, 264 - h, 36, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(front, const Radius.circular(7)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(color, Colors.white, .3)!, color],
          ).createShader(front),
      );
      canvas.drawPath(
        Path()
          ..moveTo(x + 36, 264 - h + 2)
          ..lineTo(x + 48, 254 - h)
          ..lineTo(x + 48, 252)
          ..lineTo(x + 36, 264)
          ..close(),
        Paint()..color = Color.lerp(color, Palette.forest, .25)!,
      );
      canvas.drawPath(
        Path()
          ..moveTo(x, 264 - h + 3)
          ..lineTo(x + 12, 254 - h)
          ..lineTo(x + 48, 254 - h)
          ..lineTo(x + 36, 264 - h + 3)
          ..close(),
        Paint()..color = Color.lerp(color, Colors.white, .45)!,
      );
    }
    final graph = Path()
      ..moveTo(168, 168)
      ..cubicTo(201, 167, 208, 134, 236, 127)
      ..cubicTo(264, 117, 279, 77, 310, 66);
    final metric = graph.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = dark ? Palette.lime : Palette.forest
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    if (progress > .95) {
      canvas.drawPath(
        Path()
          ..moveTo(299, 66)
          ..lineTo(310, 66)
          ..lineTo(309, 78),
        Paint()
          ..color = dark ? Palette.lime : Palette.forest
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }

    // The mascot grows out of the graph's foundation, with a soft clay-pot finish.
    canvas.save();
    canvas.translate(119, 244 + float);
    canvas.scale(.7 + progress * .3);
    canvas.drawPath(
      Path()
        ..moveTo(0, -12)
        ..quadraticBezierTo(2, -53, 8, -83),
      Paint()
        ..color = const Color(0xFF3C7044)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(6, -62)
        ..cubicTo(-43, -49, -63, -88, -37, -103)
        ..cubicTo(-6, -116, 13, -85, 6, -62),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFCAE894), Color(0xFF659A51)],
        ).createShader(const Rect.fromLTWH(-53, -104, 64, 48)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(6, -78)
        ..cubicTo(-1, -111, 23, -130, 44, -118)
        ..cubicTo(63, -99, 39, -73, 6, -78),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFDCF5A5), Color(0xFF78B560)],
        ).createShader(const Rect.fromLTWH(3, -120, 46, 47)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-30, -92)
        ..quadraticBezierTo(-18, -89, -6, -75),
      Paint()
        ..color = Colors.white.withValues(alpha: .4)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    const pot = Rect.fromLTWH(-41, -37, 82, 70);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pot, const Radius.circular(24)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFCEE), Color(0xFFE1D4B9)],
        ).createShader(pot),
    );
    canvas.drawOval(
      const Rect.fromLTWH(-37, -42, 74, 18),
      Paint()..color = const Color(0xFFFFF8E8),
    );
    canvas.drawOval(
      const Rect.fromLTWH(-27, -38, 54, 9),
      Paint()..color = const Color(0xFFAA9071),
    );
    canvas.drawCircle(
      const Offset(-13, -5),
      3,
      Paint()..color = Palette.forest,
    );
    canvas.drawCircle(const Offset(13, -5), 3, Paint()..color = Palette.forest);
    canvas.drawArc(
      const Rect.fromLTWH(-7, -3, 14, 13),
      0,
      math.pi,
      false,
      Paint()
        ..color = Palette.forest
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    for (final x in [-23.0, 23.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 3), width: 11, height: 6),
        Paint()..color = const Color(0xFFE9BBAF),
      );
    }
    canvas.restore();
    for (var i = 0; i < 3; i++) {
      final angle = t * 1.7 + i * 2.1;
      final point = Offset(
        190 + math.cos(angle) * 143,
        165 + math.sin(angle) * 92,
      );
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(math.sin(angle) * .3);
      canvas.drawOval(
        const Rect.fromLTWH(-12, -15, 26, 31),
        Paint()..color = const Color(0xFFB69C55),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-15, -16, 26, 30),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFEDAB), Color(0xFFD7BD72)],
          ).createShader(const Rect.fromLTWH(-15, -16, 26, 30)),
      );
      final text = TextPainter(
        text: const TextSpan(
          text: '₹',
          style: TextStyle(
            fontSize: 19,
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.w700,
            color: Color(0xFF897438),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(-text.width / 2 - 2, -text.height / 2 - 1));
      canvas.restore();
    }
    for (var i = 0; i < 6; i++) {
      final x = [61.0, 145.0, 323.0, 52.0, 296.0, 210.0][i];
      final y = [75.0, 44.0, 147.0, 199.0, 293.0, 310.0][i];
      final r = (2.5 + 2 * math.sin(t * math.pi * 2 + i).abs()) * progress;
      canvas.drawPath(
        Path()
          ..moveTo(x, y - r * 1.8)
          ..quadraticBezierTo(x, y, x + r, y)
          ..quadraticBezierTo(x, y, x, y + r * 1.8)
          ..quadraticBezierTo(x, y, x - r, y)
          ..quadraticBezierTo(x, y, x, y - r * 1.8),
        Paint()
          ..color = i.isEven
              ? const Color(0xFFC4ACE5)
              : const Color(0xFF9CBF64),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GardenLaunchPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.dark != dark;
}
