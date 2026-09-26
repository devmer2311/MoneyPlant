import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/design.dart';

class LaunchExperience extends StatefulWidget {
  final Widget child;
  final int? seed;
  const LaunchExperience({super.key, required this.child, this.seed});
  @override
  State<LaunchExperience> createState() => _LaunchExperienceState();
}

class _LaunchExperienceState extends State<LaunchExperience>
    with SingleTickerProviderStateMixin {
  late final seed = widget.seed ?? DateTime.now().millisecondsSinceEpoch;
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..addListener(tick);
  bool finished = false, started = false, impact = false, blast = false;
  void tick() {
    if (controller.value >= .086 && !impact) {
      impact = true;
      HapticFeedback.heavyImpact();
    }
    if (controller.value >= .393 && !blast) {
      blast = true;
      HapticFeedback.mediumImpact();
    }
    if (controller.isCompleted) finish();
  }

  void finish() {
    controller.stop();
    if (mounted) setState(() => finished = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      finished = true;
      controller.stop();
    } else if (!started) {
      started = true;
      controller.forward();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (!finished)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: finish,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) => ClipPath(
                clipper: GardenRevealClipper(controller.value),
                child: CustomPaint(
                  painter: _PunchPainter(
                    controller.value,
                    context.tokens,
                    seed,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class GardenRevealClipper extends CustomClipper<Path> {
  final double t;
  GardenRevealClipper(this.t);
  @override
  Path getClip(Size s) {
    final p = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & s);
    if (t > .89) {
      p.addOval(
        Rect.fromCircle(
          center: Offset(s.width / 2, s.height * .48),
          radius: s.longestSide * ((t - .89) / .11),
        ),
      );
    }
    return p;
  }

  @override
  bool shouldReclip(GardenRevealClipper old) => old.t != t;
}

class _PunchPainter extends CustomPainter {
  final double t;
  final GardenTokens c;
  final int seed;
  _PunchPainter(this.t, this.c, this.seed);
  void label(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color, {
    double scale = 1,
  }) {
    final p = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: c.displayFont,
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    p.paint(canvas, Offset(-p.width / 2, -p.height / 2));
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          colors: c.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );
    final center = Offset(size.width / 2, size.height * .45);
    final r = math.Random(seed);
    final impact = ((t - .086) / .13).clamp(0.0, 1.0);
    canvas.save();
    canvas.translate(math.sin(impact * math.pi * 6) * 6 * (1 - impact), 0);
    if (t < .22) {
      final y = -80 + (center.dy + 80) * (t / .086).clamp(0.0, 1.0);
      for (var i = 5; i >= 0; i--) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx, y - i * 9),
            width: 14,
            height: 20,
          ),
          Paint()..color = c.receive.withValues(alpha: (1 - i / 6) * .9),
        );
      }
    }
    if (t > .086 && t < .35) {
      canvas.drawCircle(
        center,
        impact * 190,
        Paint()
          ..color = c.receive.withValues(alpha: 1 - impact)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
    final growth = Curves.elasticOut.transform(
      ((t - .21) / .23).clamp(0.0, 1.0),
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(growth);
    final stem = Paint()
      ..color = c.receive
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, 15), const Offset(0, -105), stem);
    for (var i = 0; i < 4; i++) {
      final sign = i.isEven ? 1.0 : -1.0;
      final y = -20.0 - i * 25;
      final leaf = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(sign * 65, y - 60, sign * 65, y - 18)
        ..quadraticBezierTo(sign * 40, y + 10, 0, y);
      canvas.drawPath(leaf, Paint()..color = i.isEven ? c.receive : c.owe);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-42, 12, 84, 62),
        const Radius.circular(15),
      ),
      Paint()..color = c.receive,
    );
    canvas.restore();
    final burst = ((t - .39) / .43).clamp(0.0, 1.0);
    if (t > .39 && burst < 1) {
      for (var i = 0; i < 22; i++) {
        final angle = r.nextDouble() * math.pi * 2;
        final speed = 100 + r.nextDouble() * 200;
        final p =
            center +
            Offset(
              math.cos(angle) * speed * burst,
              math.sin(angle) * speed * burst + 100 * burst * burst,
            );
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(burst * (i.isEven ? 5 : -5));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: i.isEven ? 18 : 26,
              height: 18,
            ),
            Radius.circular(i.isEven ? 9 : 2),
          ),
          Paint()
            ..color = (i.isEven ? c.receive : c.owe).withValues(
              alpha: 1 - burst,
            ),
        );
        canvas.restore();
      }
    }
    if (t > .39 && t < .42) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = c.receive.withValues(alpha: .6 * (1 - (t - .39) / .03)),
      );
    }
    const word = 'MONEY PLANT.';
    final fontSize = math.min(36.0, size.width / 9);
    for (var i = 0; i < word.length; i++) {
      final progress = ((t * 1400 - 700 - i * 25) / 150).clamp(0.0, 1.0);
      if (progress > 0) {
        final char = progress < .55
            ? '₹\$#@!%'[(t * 100 + i).toInt() % 6]
            : word[i];
        label(
          canvas,
          char,
          Offset(
            center.dx + (i - (word.length - 1) / 2) * fontSize * .65,
            center.dy + 130,
          ),
          fontSize,
          c.heroInk,
          scale: 1 + .8 * (1 - progress),
        );
      }
    }
    const lines = [
      'Grow it. Own it. Flex it.',
      'Chhoti savings. BADE dreams.',
      'Budget? Boss mode on.',
      'Your money. Your jungle.',
    ];
    final line = lines[seed % lines.length];
    final count = (line.length * ((t * 1400 - 900) / 350).clamp(0.0, 1.0))
        .toInt();
    label(
      canvas,
      line.substring(0, count),
      Offset(center.dx, center.dy + 180),
      math.min(17, size.width / 22),
      c.heroMuted,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PunchPainter old) => old.t != t || old.c != c;
}
