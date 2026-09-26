import 'dart:async';

import 'package:flutter/material.dart';

import '../core/design.dart';
import 'depth.dart';

final gardenNoticeKey = GlobalKey<GardenNoticeHostState>();

/// Sits above the Navigator, including modal routes and their scrims.
class GardenNoticeHost extends StatefulWidget {
  final Widget child;
  const GardenNoticeHost({super.key, required this.child});
  @override
  State<GardenNoticeHost> createState() => GardenNoticeHostState();
}

class GardenNoticeHostState extends State<GardenNoticeHost> {
  String? message;
  bool error = false;
  int revision = 0;
  Timer? timeout;
  void show(String value, {bool isError = false}) {
    timeout?.cancel();
    setState(() {
      message = value;
      error = isError;
      revision++;
    });
    timeout = Timer(const Duration(seconds: 5), dismiss);
  }

  void dismiss() {
    timeout?.cancel();
    if (mounted) setState(() => message = null);
  }

  @override
  void dispose() {
    timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      Positioned(
        top: MediaQuery.paddingOf(context).top + 14,
        left: 16,
        right: 16,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : GardenMotion.duration,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, -.25),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: message == null
                  ? const SizedBox.shrink()
                  : Semantics(
                      key: ValueKey(revision),
                      liveRegion: true,
                      child: Material(
                        elevation: 16,
                        shadowColor: context.tokens.shadow.withValues(
                          alpha: .22,
                        ),
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                          child: Row(
                            children: [
                              DepthIcon(
                                error
                                    ? Icons.priority_high_rounded
                                    : Icons.check_rounded,
                                tint: error
                                    ? context.tokens.expenseAccent
                                    : context.tokens.receive,
                                size: 36,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  message!,
                                  style: context.type.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                key: const ValueKey('dismiss_notice'),
                                onPressed: dismiss,
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 19,
                                  semanticLabel: 'Dismiss notification',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    ],
  );
}

void showGardenNotice(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  final host = gardenNoticeKey.currentState;
  if (host != null) {
    host.show(message, isError: error);
  } else {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
