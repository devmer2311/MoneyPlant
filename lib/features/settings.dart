import 'settings/app_updates.dart';
import 'settings/privacy.dart';

import 'package:file_picker/file_picker.dart';

import 'settings/data_export.dart';
import 'import/import_flow.dart';
import 'settings/recurring_page.dart';
import 'settings/get_paid.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../core/design.dart';
import '../data/garden_store.dart';
import '../shared/widgets.dart';
import 'reports.dart';
import 'settings/theme_picker.dart';
import 'reminder_settings.dart';
import '../shared/depth.dart';

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(gardenProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Make yourself at home.', style: context.type.headlineMedium),
        const SizedBox(height: 26),
        Text('APPEARANCE', style: context.type.labelSmall),
        const SizedBox(height: 14),
        const ThemePicker(),
        const SizedBox(height: 14),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'light',
              label: Text('Light'),
              icon: Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment(
              value: 'dark',
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode_outlined),
            ),
            ButtonSegment(value: 'system', label: Text('Auto')),
          ],
          selected: {store.data.theme},
          onSelectionChanged: (v) =>
              perform(context, () => store.change((d) => d.theme = v.first)),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          initialValue: store.data.currency,
          decoration: const InputDecoration(labelText: 'Currency'),
          items: [
            'INR',
            'USD',
            'EUR',
          ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged:
              store.data.entries.isNotEmpty ||
                  store.data.splits.isNotEmpty ||
                  store.data.goals.isNotEmpty ||
                  store.data.tasks.isNotEmpty ||
                  store.data.recurring.isNotEmpty ||
                  store.data.budgets.isNotEmpty
              ? null
              : (v) => perform(
                  context,
                  () => store.change((d) => d.currency = v!),
                ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose your currency before adding data. Currency conversion is not performed.',
          style: TextStyle(fontSize: 11),
        ),
        const Divider(),
        Text('LITTLE NUDGES', style: context.type.labelSmall),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const DepthIcon(
            Icons.notifications_active_rounded,
            size: 42,
          ),
          title: const Text('Cute reminders'),
          subtitle: const Text(
            'Little nudges for expenses, splits & your money plant 🌱',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ReminderSettingsPage(),
            ),
          ),
        ),
        const Divider(),
        if (store.data.currency == 'INR') const GetPaid(),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.repeat),
          title: const Text('Recurring entries'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecurringPage()),
          ),
        ),
        const PrivacySettings(),
        Text('YOUR DATA', style: context.type.labelSmall),
        ListTile(
          title: const Text('Import bank statement'),
          leading: const Icon(Icons.upload_file),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ImportFlow()),
          ),
        ),
        ListTile(
          title: const Text('Export CSV'),
          leading: const Icon(Icons.table_view),
          onTap: () => perform(context, () => exportCsv(context, store)),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock_outline),
          title: const Text('Private by nature'),
          subtitle: const Text(
            'Saved on this device. No account. No bank connection. Export a backup before clearing app or browser data.',
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.ios_share),
          title: const Text('Export a backup'),
          subtitle: const Text(
            'All entries, goals, people, splits, and preferences.',
          ),
          onTap: () => perform(context, () async {
            await SharePlus.instance.share(
              ShareParams(
                files: [
                  XFile.fromData(
                    utf8.encode(store.data.encode()),
                    mimeType: 'application/json',
                  ),
                ],
                fileNameOverrides: ['money-plant-backup.json'],
                sharePositionOrigin: shareOrigin(context),
              ),
            );
          }),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.copy_outlined),
          title: const Text('Copy backup JSON'),
          onTap: () => perform(
            context,
            () => Clipboard.setData(ClipboardData(text: store.data.encode())),
            success: 'Backup copied. Store it somewhere safe.',
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.restore),
          title: const Text('Restore a backup'),
          subtitle: const Text('Paste a Money Plant JSON backup.'),
          onTap: () => sheet(context, const RestoreSheet()),
        ),
        const Divider(),
        const AppUpdateSettings(),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.eco_outlined),
            title: Text('Money Plant', style: context.type.titleLarge),
            subtitle: Text(
              snapshot.hasData
                  ? 'Version ${snapshot.data!.version} · Build ${snapshot.data!.buildNumber}'
                  : 'Your private money garden',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Built with 💖 in India by DJ Khatri',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: context.tokens.displayFont,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(
          'PDF import uses Syncfusion under its Community or commercial license. Eligibility and terms: syncfusion.com/products/communitylicense',
          style: TextStyle(fontSize: 11),
        ),
        TextButton(
          onPressed: () =>
              showLicensePage(context: context, applicationName: 'Money Plant'),
          child: const Text('Open-source licenses'),
        ),
      ],
    );
  }
}

class RestoreSheet extends ConsumerStatefulWidget {
  const RestoreSheet({super.key});
  @override
  ConsumerState<RestoreSheet> createState() => _RestoreSheetState();
}

class _RestoreSheetState extends ConsumerState<RestoreSheet> {
  final value = TextEditingController();
  bool confirmed = false;
  @override
  void dispose() {
    value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Bring your garden back.', style: context.type.headlineMedium),
      const SizedBox(height: 16),
      TextField(
        controller: value,
        maxLines: 6,
        decoration: const InputDecoration(labelText: 'Paste backup JSON'),
      ),
      OutlinedButton.icon(
        onPressed: () => perform(context, () async {
          final file = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['json'],
            withData: true,
          );
          if (file != null) {
            value.text = utf8.decode(file.files.single.bytes!);
          }
        }),
        icon: const Icon(Icons.file_open),
        label: const Text('Choose backup file'),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Replace this device’s data with the backup.'),
        value: confirmed,
        onChanged: (v) => setState(() => confirmed = v!),
      ),
      const SizedBox(height: 18),
      FilledButton(
        onPressed: !confirmed
            ? null
            : () async {
                final store = ref.read(gardenProvider);
                final ok = await perform(
                  context,
                  () => store.restore(value.text),
                );
                if (context.mounted && ok) {
                  Navigator.pop(context);
                  toast(context, 'Your garden is restored.');
                }
              },
        child: const Text('Restore backup'),
      ),
    ],
  );
}
