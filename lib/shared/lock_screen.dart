import 'launch_experience.dart';

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../core/design.dart';
import '../data/garden_store.dart';

final localAuthentication = LocalAuthentication();
bool get supportsAppLock =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.windows);
Future<bool> authenticateGarden() => localAuthentication.authenticate(
  localizedReason: 'Unlock your private money garden',
  biometricOnly: false,
);

class LockGate extends ConsumerStatefulWidget {
  final Widget child;
  const LockGate({super.key, required this.child});
  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate>
    with WidgetsBindingObserver {
  bool unlocking = false;
  bool locked = false, privacy = false, prompt = false, initialized = false;
  DateTime? background;
  String status = 'Your garden is safe 🔒';
  bool lastEnabled = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> secure(bool enabled) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await const MethodChannel('money_plant/privacy')
            .invokeMethod('setSecure', enabled);
      } on MissingPluginException {
        /* Other platforms have no Android window. */
      }
    }
  }

  void unlock() async {
    if (prompt) return;
    setState(() => prompt = true);
    try {
      final ok = await authenticateGarden();
      if (!mounted) return;
      if (ok) {
        HapticFeedback.lightImpact();
        setState(() => unlocking = true);
        await Future<void>.delayed(
          MediaQuery.disableAnimationsOf(context)
              ? const Duration(milliseconds: 100)
              : const Duration(milliseconds: 700),
        );
        if (mounted) {
          setState(() {
            locked = false;
            unlocking = false;
          });
        }
      } else {
        setState(
          () => status = 'Fingerprint check cancelled. Your garden is safe 🔒',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => status = e.toString().toLowerCase().contains('lockout')
              ? 'Too many tries. Use your phone PIN.'
              : "That didn’t match. Try again.",
        );
      }
    } finally {
      if (mounted) setState(() => prompt = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!lastEnabled) return;
    if (state == AppLifecycleState.resumed) {
      final elapsed = background == null
          ? 0
          : DateTime.now().difference(background!).inSeconds;
      setState(() {
        privacy = false;
        if (elapsed > 60) locked = true;
      });
      background = null;
      if (locked && !prompt) unlock();
    } else if ([
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ].contains(state)) {
      background ??= DateTime.now();
      setState(() => privacy = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(gardenProvider).data.appLock && supportsAppLock;
    if (!initialized) {
      initialized = true;
      locked = enabled;
      if (enabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) => unlock());
      }
    }
    if (lastEnabled != enabled) {
      lastEnabled = enabled;
      secure(enabled);
      if (!enabled) locked = false;
    }
    return Stack(
      children: [
        ExcludeSemantics(
          excluding: locked || privacy,
          child: IgnorePointer(
            ignoring: locked || privacy,
            child: widget.child,
          ),
        ),
        if (locked)
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: unlocking ? 1.0 : 0.0),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? const Duration(milliseconds: 100)
                  : const Duration(milliseconds: 700),
              builder: (context, value, child) => ClipPath(
                clipper: GardenRevealClipper(.89 + .11 * value),
                child: child,
              ),
              child: LaserVault(onUnlock: unlock, busy: prompt, status: status),
            ),
          ),
        if (privacy)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: ColoredBox(
                color: context.tokens.canvas.withValues(alpha: .9),
                child: Center(
                  child: Icon(Icons.eco, size: 80, color: context.tokens.brand),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class LaserVault extends StatefulWidget {
  final VoidCallback onUnlock;
  final bool busy;
  final String status;
  const LaserVault({
    super.key,
    required this.onUnlock,
    required this.busy,
    required this.status,
  });
  @override
  State<LaserVault> createState() => _LaserVaultState();
}

class _LaserVaultState extends State<LaserVault>
    with SingleTickerProviderStateMixin {
  late final ticker = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  Offset? spark;
  DateTime? hit;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context)) {
      ticker.repeat();
    } else {
      ticker.stop();
    }
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  void touch(Offset position, Size size) {
    if (widget.busy || MediaQuery.disableAnimationsOf(context)) return;
    final now = DateTime.now();
    for (var i = 0; i < 6; i++) {
      final y = size.height * (i + 1) / 7;
      final end =
          y + math.sin(ticker.value * math.pi * 2 + i) * size.height * .3;
      final expected = y + (end - y) * position.dx / size.width;
      if ((position.dy - expected).abs() < 14) {
        if (hit == null || now.difference(hit!).inMilliseconds > 150) {
          HapticFeedback.mediumImpact();
          setState(() {
            spark = position;
            hit = now;
          });
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: context.tokens.hero,
    child: LayoutBuilder(
      builder: (context, bounds) => MouseRegion(
        onHover: (e) => touch(e.localPosition, bounds.biggest),
        child: GestureDetector(
          onPanDown: (e) => touch(e.localPosition, bounds.biggest),
          onPanUpdate: (e) => touch(e.localPosition, bounds.biggest),
          child: AnimatedBuilder(
            animation: ticker,
            builder: (context, _) => Stack(
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      painter: _VaultPainter(
                        widget.busy ? 0 : ticker.value,
                        context.tokens,
                        spark,
                        hit,
                        MediaQuery.disableAnimationsOf(context),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 80,
                            color: context.tokens.heroInk,
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'VAULT LOCKED',
                            style: context.type.headlineMedium?.copyWith(
                              color: context.tokens.heroInk,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.status,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.tokens.heroInk),
                          ),
                          const SizedBox(height: 40),
                          Semantics(
                            label: 'Unlock Money Plant',
                            button: true,
                            child: FilledButton.icon(
                              onPressed: widget.busy ? null : widget.onUnlock,
                              icon: const Icon(Icons.fingerprint),
                              label: Text(widget.busy ? 'Checking…' : 'Unlock'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _VaultPainter extends CustomPainter {
  final double t;
  final GardenTokens c;
  final Offset? spark;
  final DateTime? hit;
  final bool reduced;
  _VaultPainter(this.t, this.c, this.spark, this.hit, this.reduced);
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = RadialGradient(colors: c.heroGradient)
            .createShader(Offset.zero & s),
    );
    final age = hit == null
        ? 1.0
        : DateTime.now().difference(hit!).inMilliseconds / 550;
    final grid = Paint()
      ..color = c.highlight.withValues(alpha: .06)
      ..strokeWidth = 1;
    for (var i = 0; i < 12; i++) {
      final y = s.height * (.68 + i * .032) + (reduced ? 0 : (t * 30) % 20);
      canvas.drawLine(Offset(0, y), Offset(s.width, y), grid);
      canvas.drawLine(
        Offset(s.width / 2, s.height * .64),
        Offset((i - 3) * s.width / 6, s.height),
        grid,
      );
    }
    if (age < 1 && !reduced) {
      final text = TextPainter(
        text: TextSpan(
          text: 'INTRUSION DETECTED',
          style: TextStyle(
            color: c.danger,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset((s.width - text.width) / 2, s.height * .22));
    }
    for (var i = 0; i < 6; i++) {
      final y = s.height * (i + 1) / 7;
      final end = y + math.sin(t * math.pi * 2 + i) * s.height * .3;
      final color = age < .64 ? c.danger : c.highlight;
      for (final (width, alpha) in [(12.0, .08), (5.0, .25), (1.5, 1.0)]) {
        canvas.drawLine(
          Offset(-10, y),
          Offset(s.width + 10, end),
          Paint()
            ..color = color.withValues(alpha: alpha)
            ..strokeWidth = width,
        );
      }
    }
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(s.width / 2, s.height / 2 - 65),
          radius: 65 + i * 12,
        ),
        t * math.pi * 2 * (i.isEven ? 1 : -1) + i,
        math.pi * 1.6,
        false,
        Paint()
          ..color = c.highlight.withValues(alpha: .25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    if (!reduced) {
      final random = math.Random(42);
      for (var i = 0; i < 48; i++) {
        canvas.drawCircle(
          Offset(
            random.nextDouble() * s.width,
            (random.nextDouble() * s.height - t * 100) % s.height,
          ),
          1,
          Paint()..color = c.highlight.withValues(alpha: .2),
        );
      }
      if (spark != null && age < 1) {
        for (var i = 0; i < 24; i++) {
          final angle = i * math.pi / 12;
          canvas.drawCircle(
            spark! +
                Offset(
                  math.cos(angle) * 100 * age,
                  math.sin(angle) * 100 * age + age * age * 60,
                ),
            2,
            Paint()..color = c.danger.withValues(alpha: 1 - age),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_VaultPainter old) =>
      t != old.t || hit != old.hit || c != old.c;
}
