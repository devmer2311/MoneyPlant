import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_updates.dart';
import '../../data/reminder_store.dart';
import '../../data/update_background.dart';
import '../../data/update_store.dart';
import '../../shared/widgets.dart';
import '../update_prompt.dart';

class AppUpdateSettings extends ConsumerWidget {
  const AppUpdateSettings({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updates = ref.watch(updateProvider);
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('More info'),
          subtitle: Text(
            websiteUri() == null
                ? 'Our website is coming soon. Visit Money Plant on GitHub.'
                : 'Visit the Money Plant website',
          ),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => openAppLink(
            context,
            websiteUri() ??
                Uri.parse('https://github.com/devmer2311/MoneyPlant'),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.system_update),
          title: const Text('Check for updates'),
          subtitle: const Text(
            'Checks GitHub releases. Stays quiet when offline.',
          ),
          onTap: () => updates.check(notificationTap: true),
        ),
        if (backgroundUpdatesSupported) ...[
          SwitchListTile(
            title: const Text('Daily update checks'),
            subtitle: const Text(
              'Check when internet is available. Android controls the timing.',
            ),
            value: updates.daily,
            onChanged: (value) =>
                perform(context, () => updates.setDaily(value)),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Allow update notifications'),
            subtitle: const Text(
              'One notification per new version. Tap it to open the update prompt.',
            ),
            onTap: () => perform(context, () async {
              final allowed = await ref
                  .read(reminderProvider)
                  .gateway
                  .permission(request: true);
              if (context.mounted) {
                toast(
                  context,
                  allowed ? 'Update notifications are allowed.' : 'Allow notifications in Android settings to receive update alerts.',
                );
              }
            }),
          ),
        ],
      ],
    );
  }
}
