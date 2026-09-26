import 'package:flutter/material.dart';

import '../core/design.dart';

class PdfSkeleton extends StatefulWidget {
  const PdfSkeleton({super.key});
  @override
  State<PdfSkeleton> createState() => _PdfSkeletonState();
}

class _PdfSkeletonState extends State<PdfSkeleton>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.stop();
    } else {
      controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: List.generate(
          7,
          (i) => Container(
            height: i == 0 ? 90 : 24,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  context.tokens.surfaceAlt,
                  context.tokens.surface,
                  context.tokens.surfaceAlt,
                ],
                stops: [0, .2 + controller.value * .6, 1],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
