import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_updates.dart';
import '../data/update_store.dart';
import '../shared/widgets.dart';

Future<void> openAppLink(BuildContext context, Uri uri) async {
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    /* A device may have no browser handler. */
  }
  if (context.mounted) {
    toast(context, 'Could not open the browser. Please try again.');
  }
}

class UpdatePromptHost extends ConsumerStatefulWidget {
  final Widget child;
  const UpdatePromptHost({super.key, required this.child});
  @override
  ConsumerState<UpdatePromptHost> createState() => _UpdatePromptHostState();
}

class _UpdatePromptHostState extends ConsumerState<UpdatePromptHost> {
  late final UpdateStore store;
  int seen = 0;
  bool showing = false;
  Timer? delay;
  @override
  void initState() {
    super.initState();
    store = ref.read(updateProvider)..addListener(changed);
    changed();
  }

  void changed() {
    if (!mounted ||
        showing ||
        delay != null ||
        store.pending == null ||
        seen == store.promptId) {
      return;
    }
    // Let the launch animation finish; never block the shell on a network call.
    delay = Timer(const Duration(milliseconds: 1500), () async {
      delay = null;
      if (!mounted) return;
      seen = store.promptId;
      showing = true;
      await showDialog<void>(
        context: context,
        builder: (_) => UpdateDialog(release: store.pending!),
      );
      showing = false;
      changed();
    });
  }

  @override
  void dispose() {
    delay?.cancel();
    store.removeListener(changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class UpdateDialog extends StatelessWidget {
  final AppRelease release;
  const UpdateDialog({super.key, required this.release});
  @override
  Widget build(BuildContext context) {
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final target =
        websiteUri() ?? (android ? release.apk : null) ?? release.page;
    return AlertDialog(
      icon: const Icon(Icons.system_update_outlined),
      title: Text('New version v${release.version} is ready 🌱'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A fresh update for your money garden.'),
            if (android && release.apk != null)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Download the APK in your browser, then open it to install the update. Your phone will ask before installing.',
                ),
              ),
            TextButton(
              onPressed: () => openAppLink(context, release.page),
              child: const Text('What’s new?'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Later'),
        ),
        FilledButton.icon(
          onPressed: () => openAppLink(context, target),
          icon: const Icon(Icons.download),
          label: const Text('Update'),
        ),
      ],
    );
  }
}
