import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design.dart';
import '../core/models.dart';
import '../core/reminders.dart';
import '../data/garden_store.dart';
import '../data/reminder_store.dart';
import '../shared/depth.dart';
import '../shared/widgets.dart';

class ReminderSettingsPage extends ConsumerStatefulWidget {
  const ReminderSettingsPage({super.key});
  @override
  ConsumerState<ReminderSettingsPage> createState() =>
      _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends ConsumerState<ReminderSettingsPage> {
  int preview = 0;
  static final messages = [
    dailyMessages[0],
    eveningMessages[0],
    monthlyMessage,
    weeklyMessage,
    budgetMessage(80),
    budgetMessage(100),
  ];
  Future<void> chooseTime(String key, int minute) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
    );
    if (time != null && mounted) {
      final store = ref.read(reminderProvider);
      await store.update(
        store.preferences.update(key, time.hour * 60 + time.minute),
      );
    }
  }

  Future<void> chooseBudget() async {
    final store = ref.read(reminderProvider);
    final input = TextEditingController(
      text: store.preferences.budget == 0
          ? ''
          : (store.preferences.budget / 100).toStringAsFixed(2),
    );
    String? problem;
    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('A little spending boundary'),
          content: TextField(
            controller: input,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText:
                  'Monthly budget (${ref.read(gardenProvider).data.currency})',
              errorText: problem,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 0),
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                try {
                  Navigator.pop(context, parseMoney(input.text));
                } on FormatException catch (e) {
                  setDialogState(() => problem = e.message);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    // The route's exit transition may still use its text controller.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
    if (result != null && mounted) {
      await store.update(store.preferences.update('budget', result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(reminderProvider);
    final p = store.preferences;
    final copy = messages[preview];
    final editable = store.ready && !store.busy;
    String time(int value) =>
        TimeOfDay(hour: value ~/ 60, minute: value % 60).format(context);
    Widget category(
      String title,
      String subtitle,
      IconData icon,
      String key,
      bool value,
      String timeKey,
      int minute,
    ) => Surface(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: DepthIcon(icon, size: 38),
            title: Text(title),
            subtitle: Text(subtitle),
            value: value,
            onChanged: editable ? (v) => store.update(p.update(key, v)) : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: editable && value
                  ? () => chooseTime(timeKey, minute)
                  : null,
              icon: const Icon(Icons.schedule_rounded, size: 18),
              label: Text(time(minute)),
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Little nudges, big love.')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 2,
                        child: Image.asset(
                          reminderImage,
                          fit: BoxFit.contain,
                          semanticLabel: 'A smiling money plant, watering can, hearts and a tiny coin purse',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'A little love from your plant.',
                      style: context.type.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cute Hinglish reminders, right when you need a tiny nudge. Private, local, and always in your control.',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'NOTIFICATION PREVIEW',
                      style: context.type.labelSmall,
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Column(
                        key: ValueKey(preview),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(copy.title, style: context.type.titleLarge),
                          const SizedBox(height: 6),
                          Text(copy.body),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(
                        () => preview = (preview + 1) % messages.length,
                      ),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: const Text('Show another little nudge'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!store.supported)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'You’re previewing the design. Scheduled notifications and pictures in the notification tray work in the Android app.',
                  ),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Let my plant nudge me'),
                subtitle: Text(
                  !store.supported
                      ? 'Android app required'
                      : p.enabled && !store.allowed
                      ? 'Blocked in Android notification settings'
                      : p.enabled
                      ? 'Your plant is ready to nudge you'
                      : 'Off until you choose to enable',
                ),
                value: p.enabled,
                onChanged: editable && store.supported
                    ? (v) => store.update(p.update('enabled', v))
                    : null,
              ),
              if (store.error != null)
                Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.error!,
                        style: TextStyle(color: context.colors.error),
                      ),
                      TextButton(
                        onPressed: store.busy
                            ? null
                            : () => store.ready
                                  ? store.refresh()
                                  : store.initialize(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              category(
                'Daily expense check-in',
                'A different little sentence each day 🌼',
                Icons.wb_sunny_rounded,
                'daily',
                p.daily,
                'dailyMinute',
                p.dailyMinute,
              ),
              const SizedBox(height: 12),
              category(
                'Before you say goodnight',
                'A soft evening nudge 🌙',
                Icons.bedtime_rounded,
                'evening',
                p.evening,
                'eveningMinute',
                p.eveningMinute,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Daily check-ins repeat at your chosen times, even on days you have already logged an expense. Turn either one off whenever you like.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              category(
                'New month, fresh leaves',
                'On the 1st: budget + savings watering time 💧',
                Icons.spa_rounded,
                'monthly',
                p.monthly,
                'monthlyMinute',
                p.monthlyMinute,
              ),
              const SizedBox(height: 12),
              category(
                'Clear the split scene',
                'Only while you have unsettled splits 🫶',
                Icons.people_alt_rounded,
                'weekly',
                p.weekly,
                'weeklyMinute',
                p.weeklyMinute,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: DropdownButtonFormField<int>(
                  initialValue: p.weekday,
                  decoration: const InputDecoration(
                    labelText: 'Weekly split reminder day',
                  ),
                  items: [
                    for (var i = 1; i <= 7; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(
                          [
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday',
                            'Sunday',
                          ][i - 1],
                        ),
                      ),
                  ],
                  onChanged: editable && p.weekly
                      ? (v) => store.update(p.update('weekday', v!))
                      : null,
                ),
              ),
              Surface(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const DepthIcon(
                        Icons.favorite_rounded,
                        size: 38,
                      ),
                      title: const Text('Gentle budget heads-up'),
                      subtitle: const Text(
                        'At 80% and 100%. Care, never guilt 💚',
                      ),
                      value: p.budgetWarnings,
                      onChanged: editable
                          ? (v) => store.update(p.update('budgetWarnings', v))
                          : null,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        p.budget > 0
                            ? money(
                                p.budget,
                                ref.watch(gardenProvider).data.currency,
                              )
                            : 'Set a monthly budget',
                      ),
                      subtitle: const Text('Tap to set or clear'),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: editable ? chooseBudget : null,
                    ),
                    const Text(
                      'Uses this month’s recorded money out, including full split payments and outgoing settlements. Future-dated entries are excluded. Each warning appears at most once per month.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (store.supported)
                FilledButton.icon(
                  onPressed: editable && p.enabled && store.allowed
                      ? () async {
                          await store.sendTest();
                          if (context.mounted && store.error == null) {
                            toast(
                              context,
                              'Your plant sent a hello 🌱 Check your notification tray.',
                            );
                          }
                        }
                      : null,
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text('Send me a test nudge'),
                ),
              const SizedBox(height: 12),
              const Text(
                'Reminders follow your local timezone. Android may deliver them a little later to save battery. Expand a notification to see its illustration. Notification settings stay on this device and are not included in backups.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
