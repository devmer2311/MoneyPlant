import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/design.dart';

/// Painted by Flutter, so the same sculpted controls work offline on Android.
class DepthIcon extends StatelessWidget {
  final IconData icon;
  final Color? tint;
  final double size;
  final bool raised;
  const DepthIcon(
    this.icon, {
    super.key,
    this.tint,
    this.size = 52,
    this.raised = true,
  });
  @override
  Widget build(BuildContext context) {
    final tint = this.tint ?? context.tokens.receive;
    final ink = Color.lerp(tint, context.tokens.hero, .78)!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(tint, context.tokens.highlight, .56)!,
            tint,
            Color.lerp(tint, ink, .12)!,
          ],
          stops: const [0, .55, 1],
        ),
        border: Border.all(
          color: context.tokens.highlight.withValues(alpha: .45),
          width: .8,
        ),
        boxShadow: raised
            ? [
                BoxShadow(
                  color: Color.lerp(
                    tint,
                    context.tokens.hero,
                    .45,
                  )!.withValues(alpha: context.dark ? .42 : .25),
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: context.tokens.shadow.withValues(
                    alpha: context.dark ? .22 : .09,
                  ),
                  offset: const Offset(0, 9),
                  blurRadius: 12,
                ),
              ]
            : [],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * .11,
            left: size * .18,
            child: Container(
              width: size * .32,
              height: size * .06,
              decoration: BoxDecoration(
                color: context.tokens.highlight.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, 2),
            child: Icon(
              icon,
              size: size * .48,
              color: ink.withValues(alpha: .26),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -.6),
            child: Icon(icon, size: size * .48, color: ink),
          ),
        ],
      ),
    );
  }
}

class TactileAction extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
  const TactileAction({
    super.key,
    required this.label,
    required this.icon,
    required this.tint,
    required this.onTap,
  });
  @override
  State<TactileAction> createState() => _TactileActionState();
}

class _TactileActionState extends State<TactileAction> {
  bool pressed = false, hover = false;
  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: Semantics(
        button: true,
        label: widget.label,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          splashColor: context.tokens.transparent,
          highlightColor: context.tokens.transparent,
          onHighlightChanged: (v) => setState(() => pressed = v),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: reduce
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  transformAlignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, .0015)
                    ..translateByDouble(
                      0,
                      pressed
                          ? 4
                          : hover
                          ? -4
                          : 0,
                      0,
                      1,
                    )
                    ..rotateZ(
                      reduce
                          ? 0
                          : pressed
                          ? -.06
                          : hover
                          ? .055
                          : 0,
                    )
                    ..scaleByDouble(
                      pressed && !reduce ? .92 : 1,
                      pressed && !reduce ? .92 : 1,
                      1,
                      1,
                    ),
                  child: LayoutBuilder(
                    builder: (_, c) => DepthIcon(
                      widget.icon,
                      tint: widget.tint,
                      size: c.maxWidth < 58 ? 42 : 54,
                      raised: !pressed,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MantraHeadline extends StatefulWidget {
  final bool wide;
  const MantraHeadline({super.key, this.wide = false});
  @override
  State<MantraHeadline> createState() => _MantraHeadlineState();
}

class _MantraHeadlineState extends State<MantraHeadline> {
  int index = 0;
  static const phrases = [
    ('Small steps.', 'Big money energy.'),
    ('Make room.', 'For your next big thing.'),
    ('Plant good habits.', 'Grow your own way.'),
  ];
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final face = context.tokens.brand;
    final side = context.tokens.headlineSide;
    return Semantics(
      button: true,
      label: 'Change your money mantra',
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => index = (index + 1) % phrases.length);
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: context.tokens.transparent,
        hoverColor: context.tokens.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('YOUR DAILY MONEY ENERGY', style: context.type.labelSmall),
                const SizedBox(width: 8),
                Icon(
                  Icons.autorenew_rounded,
                  size: 14,
                  color: context.colors.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: reduced
                  ? Duration.zero
                  : const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, .12),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text.rich(
                key: ValueKey(index),
                TextSpan(
                  children: [
                    TextSpan(text: '${phrases[index].$1} '),
                    TextSpan(
                      text: phrases[index].$2,
                      style: TextStyle(
                        color: face,
                        shadows: [
                          Shadow(color: side, offset: const Offset(0, 1)),
                          Shadow(color: side, offset: const Offset(0, 2)),
                          Shadow(color: side, offset: const Offset(0, 3)),
                          Shadow(
                            color: face.withValues(alpha: .13),
                            offset: const Offset(0, 7),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                style: context.type.displaySmall?.copyWith(
                  fontSize: widget.wide ? 43 : 34,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A finite arrival animation; no idle ticker drains a phone's battery.
class Arrival extends StatelessWidget {
  final Widget child;
  const Arrival({super.key, required this.child});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 550),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (_, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, 18 * (1 - t)), child: child),
    ),
  );
}

class FloatingPlant extends StatefulWidget {
  final Widget child;
  final String label;
  const FloatingPlant({super.key, required this.child, required this.label});
  @override
  State<FloatingPlant> createState() => _FloatingPlantState();
}

class _FloatingPlantState extends State<FloatingPlant>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1450),
  );
  bool greeted = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!greeted) {
      greeted = true;
      if (!MediaQuery.disableAnimationsOf(context)) motion.forward();
    }
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${widget.label}. Tap to give your plant a little love.',
    child: Tooltip(
      message: 'A little love goes a long way',
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        splashColor: context.tokens.transparent,
        highlightColor: context.tokens.transparent,
        hoverColor: context.tokens.transparent,
        onTap: () {
          HapticFeedback.lightImpact();
          if (!MediaQuery.disableAnimationsOf(context)) motion.forward(from: 0);
        },
        child: AnimatedBuilder(
          animation: motion,
          child: widget.child,
          builder: (_, child) {
            final pulse = math.sin(motion.value * math.pi);
            return Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..translateByDouble(0, -pulse * 8, 0, 1)
                ..rotateZ(
                  math.sin(motion.value * math.pi * 4) *
                      .035 *
                      (1 - motion.value),
                ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (pulse > 0)
                    ...List.generate(4, (i) {
                      final angle = i * math.pi / 2 - .3;
                      return Transform.translate(
                        offset: Offset(
                          math.cos(angle) * (42 + 28 * motion.value),
                          math.sin(angle) * (42 + 28 * motion.value),
                        ),
                        child: Opacity(
                          opacity: pulse,
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 8 + i * 2,
                            color: context.tokens.loveSparkle,
                          ),
                        ),
                      );
                    }),
                  child!,
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
