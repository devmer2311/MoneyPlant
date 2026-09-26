import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/garden_store.dart';
import '../../shared/lock_screen.dart';
import '../../shared/widgets.dart';

class PrivacySettings extends ConsumerWidget {
  const PrivacySettings({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(gardenProvider);
    return supportsAppLock
        ? SwitchListTile(
            title: const Text('Lock Money Plant'),
            subtitle: const Text(
              'Fingerprint or device PIN · Private in Recents',
            ),
            value: store.data.appLock,
            onChanged: (v) => perform(context, () async {
              if (!await authenticateGarden()) return;
              await store.change((d) => d.appLock = v);
            }),
          )
        : const SizedBox.shrink();
  }
}
