import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/design.dart';

void celebrate(BuildContext context) {
  if (MediaQuery.disableAnimationsOf(context)) return;
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) =>
        IgnorePointer(child: _Celebration(onDone: () => entry.remove())),
  );
  overlay.insert(entry);
}

class _Celebration extends StatefulWidget {
  final VoidCallback onDone;
  const _Celebration({required this.onDone});
  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration>
    with SingleTickerProviderStateMixin {
  late final controller =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 700),
        )
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        })
        ..forward();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => CustomPaint(
      painter: _Coins(controller.value, context.tokens),
      size: MediaQuery.sizeOf(context),
    ),
  );
}

class _Coins extends CustomPainter {
  final double t;
  final GardenTokens c;
  _Coins(this.t, this.c);
  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(7);
    for (var i = 0; i < 35; i++) {
      final angle = r.nextDouble() * math.pi * 2,
          speed = 80 + r.nextDouble() * 260;
      final p = Offset(
        size.width / 2 + math.cos(angle) * t * speed,
        size.height * .45 + math.sin(angle) * t * speed + 150 * t * t,
      );
      canvas.drawCircle(
        p,
        3 + r.nextDouble() * 4,
        Paint()..color = c.chart[i % c.chart.length].withValues(alpha: 1 - t),
      );
    }
  }

  @override
  bool shouldRepaint(_Coins old) => t != old.t;
}

class MoneyCounter extends StatelessWidget {
  final int value;
  final String currency;
  final TextStyle? style;
  const MoneyCounter({
    super.key,
    required this.value,
    required this.currency,
    this.style,
  });
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<int>(
    tween: IntTween(end: value),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 450),
    builder: (context, v, _) => Text(money(v, currency), style: style),
  );
}
