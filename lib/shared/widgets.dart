import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/design.dart';
import 'depth.dart';
import 'notifications.dart';

class Surface extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  const Surface({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(24),
  });
  @override
  Widget build(BuildContext context) => Material(
    color: color ?? context.colors.surface,
    borderRadius: BorderRadius.circular(Palette.radius),
    child: Padding(padding: padding, child: child),
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const SectionTitle(this.title, {super.key, this.action, this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Expanded(child: Text(title, style: context.type.titleLarge)),
        if (action != null)
          TextButton(onPressed: onTap, child: Text('$action ↗')),
      ],
    ),
  );
}

class Tag extends StatelessWidget {
  final String text;
  final Color? color;
  const Tag(this.text, {super.key, this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: color ?? context.colors.onSurface.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      text,
      style: context.type.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: color != null ? Palette.ink : null,
      ),
    ),
  );
}

class EmptyGarden extends StatelessWidget {
  final String title, message;
  final IconData icon;
  final String? action;
  final VoidCallback? onTap;
  const EmptyGarden({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.eco_outlined,
    this.action,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
    child: Column(
      children: [
        DepthIcon(icon, size: 64),
        const SizedBox(height: 16),
        Text(
          title,
          style: context.type.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: context.type.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        if (action != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OutlinedButton(onPressed: onTap, child: Text(action!)),
          ),
      ],
    ),
  );
}

class PlantArt extends StatelessWidget {
  final int stage;
  final double size;
  const PlantArt({super.key, this.stage = 0, this.size = 180});
  @override
  Widget build(BuildContext context) => FloatingPlant(
    label: 'Your money plant, growth stage ${stage + 1}',
    child: SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PlantPainter(stage)),
    ),
  );
}

class _PlantPainter extends CustomPainter {
  final int stage;
  _PlantPainter(this.stage);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200);
    canvas.drawOval(
      const Rect.fromLTWH(44, 173, 112, 17),
      Paint()..color = const Color(0xFF617856).withValues(alpha: .15),
    );
    final stem = Paint()
      ..color = Palette.forest
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final height = 92 - stage * 7.0;
    canvas.drawPath(
      Path()
        ..moveTo(100, 144)
        ..cubicTo(104, 118, 89, height + 23, 103, height),
      stem,
    );
    void leaf(double x, double y, double angle, double length) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      final path = Path()
        ..moveTo(0, 0)
        ..cubicTo(-10, -length * .8, 14, -length, 27, -length)
        ..cubicTo(36, -length * .3, 15, -3, 0, 0);
      canvas.drawShadow(path, const Color(0xFF254A24), 4, false);
      canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE3F7B4), Color(0xFF89B65A), Color(0xFF315E44)],
          ).createShader(Rect.fromLTWH(-10, -length, 45, length)),
      );
      canvas.drawPath(
        Path()
          ..moveTo(2, -3)
          ..quadraticBezierTo(12, -length / 2, 25, -length + 5),
        Paint()
          ..color = Palette.forest.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      canvas.restore();
    }

    leaf(101, 115, -.1, 52);
    leaf(98, 104, -math.pi / 2, 46);
    if (stage > 0) leaf(100, 86, .3, 44);
    if (stage > 1) leaf(98, 77, -1.5, 45);
    if (stage > 2) leaf(101, 65, .1, 44);
    if (stage > 3) leaf(102, 56, -1.2, 39);
    final pot = Path()
      ..moveTo(64, 137)
      ..lineTo(136, 137)
      ..lineTo(127, 170)
      ..quadraticBezierTo(100, 188, 73, 170)
      ..close();
    canvas.drawPath(
      pot,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFD4CAB5),
            Color(0xFFFFFFF0),
            Color(0xFFEDE4D2),
            Color(0xFFBCAF95),
          ],
        ).createShader(const Rect.fromLTWH(64, 137, 72, 45)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(60, 132, 80, 13),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFFF9EDDC),
    );
    canvas.drawOval(
      const Rect.fromLTWH(66, 133, 68, 7),
      Paint()..color = const Color(0xFF766F50),
    );
    canvas.drawLine(const Offset(100, 136), const Offset(100, 127), stem);
    for (final point in [
      const Offset(45, 76),
      const Offset(150, 49),
      const Offset(157, 113),
    ]) {
      final paint = Paint()
        ..color = const Color(0xFF70864D)
        ..strokeWidth = 1.5;
      canvas.drawLine(point.translate(-4, 0), point.translate(4, 0), paint);
      canvas.drawLine(point.translate(0, -4), point.translate(0, 4), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlantPainter oldDelegate) => stage != oldDelegate.stage;
}

Future<T?> sheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          child: child,
        ),
      ),
    );
void toast(BuildContext context, String message) {
  showGardenNotice(context, message);
}

Future<bool> perform(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null) toast(context, success);
    return true;
  } catch (e) {
    if (context.mounted) {
      showGardenNotice(
        context,
        e.toString().replaceFirst('FormatException: ', ''),
        error: true,
      );
    }
    return false;
  }
}
