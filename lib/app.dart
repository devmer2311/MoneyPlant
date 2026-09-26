import 'data/update_store.dart';
import 'features/update_prompt.dart';
import 'features/import/import_flow.dart';
import 'shared/lock_screen.dart';
import 'data/recurring_operations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'core/design.dart';
import 'data/garden_store.dart';
import 'data/reminder_store.dart';
import 'features/composer.dart';
import 'features/home.dart';
import 'features/pages.dart';
import 'features/settings.dart';
import 'shared/widgets.dart';
import 'shared/depth.dart';
import 'shared/notifications.dart';
import 'shared/launch_experience.dart';

class MoneyPlantApp extends ConsumerWidget {
  const MoneyPlantApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gardenProvider).data;
    final theme = data.theme;
    final pack = themePack(data.themePack);
    return MaterialApp(
      title: 'Money Plant',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(pack, Brightness.light),
      darkTheme: buildTheme(pack, Brightness.dark),
      themeMode: theme == 'system'
          ? ThemeMode.system
          : theme == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light,
      home: const LaunchExperience(
        child: UpdatePromptHost(child: GardenShell()),
      ),
      builder: (context, child) => LockGate(
        child: GardenNoticeHost(key: gardenNoticeKey, child: child!),
      ),
    );
  }
}

class GardenShell extends ConsumerStatefulWidget {
  const GardenShell({super.key});
  @override
  ConsumerState<GardenShell> createState() => _GardenShellState();
}

class _GardenShellState extends ConsumerState<GardenShell>
    with WidgetsBindingObserver {
  int index = 0;
  late final ReminderStore reminders;
  @override
  void initState() {
    super.initState();
    reminders = ref.read(reminderProvider);
    reminders.addListener(_onReminder);
    WidgetsBinding.instance.addObserver(this);
    _onReminder();
  }

  void _onReminder() {
    final destination = reminders.takeDestination();
    if (destination == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (destination == 'app-update') {
        ref.read(updateProvider).check(notificationTap: true);
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
      navigate(
        destination == 'splits'
            ? 3
            : destination == 'insights'
            ? 1
            : 0,
      );
      if (destination == 'expense') openComposer(context);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      reminders.refresh();
      if (ref.read(updateProvider).ready) {
        ref.read(updateProvider).check(resume: true);
      }
      ref.read(gardenProvider).runRecurring().catchError((Object e) {
        if (mounted) {
          toast(context, 'Recurring entries could not be saved. Try again.');
        }
      });
    }
  }

  @override
  void dispose() {
    reminders.removeListener(_onReminder);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  static const names = ['Overview', 'Insights', 'Tasks', 'Splits', 'Ledger'];
  static const icons = [
    Icons.grid_view_rounded,
    Icons.bar_chart_rounded,
    Icons.task_alt_rounded,
    Icons.people_outline_rounded,
    Icons.receipt_long_outlined,
  ];
  void navigate(int next) => setState(() => index = next);
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(gardenProvider);
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final page = [
      HomePage(onNavigate: navigate),
      const InsightsPage(),
      const TasksPage(),
      const SplitsPage(),
      const LedgerPage(),
    ][index];
    Widget navigation(bool rail) => rail
        ? Column(
            children: [
              Row(
                children: [
                  const DepthIcon(Icons.eco_rounded, size: 42),
                  const SizedBox(width: 10),
                  Text(
                    'money\nplant.',
                    style: context.type.headlineMedium?.copyWith(height: .95),
                  ),
                ],
              ),
              const SizedBox(height: 54),
              ...List.generate(
                5,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: index == i
                        ? (context.tokens.selectedSurface)
                        : context.tokens.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => navigate(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 17,
                        ),
                        child: Row(
                          children: [
                            DepthIcon(
                              icons[i],
                              size: 31,
                              raised: index == i,
                              tint: index == i
                                  ? context.tokens.receive
                                  : context.tokens.owe,
                            ),
                            const SizedBox(width: 14),
                            Text(names[i], style: context.type.titleMedium),
                            if (index == i) ...[
                              const Spacer(),
                              const Icon(Icons.north_east, size: 16),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: context.tokens.navigation,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline, size: 20),
                    const SizedBox(height: 12),
                    Text(
                      'Just you & your money.',
                      style: context.type.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Private by nature.\nStored on this device.',
                      style: TextStyle(fontSize: 11, height: 1.7),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextButton.icon(
                onPressed: () => sheet(context, const SettingsSheet()),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Settings'),
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              5,
              (i) => Expanded(
                child: Semantics(
                  selected: index == i,
                  button: true,
                  label: names[i],
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => navigate(i),
                    child: AnimatedContainer(
                      duration: GardenMotion.duration,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: index == i
                            ? context.tokens.receive
                            : context.tokens.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            scale: index == i ? 1.07 : .9,
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : GardenMotion.duration,
                            curve: Curves.easeOutBack,
                            child: DepthIcon(
                              icons[i],
                              size: 28,
                              raised: index == i,
                              tint: index == i
                                  ? context.tokens.receive
                                  : context.tokens.navigationInk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            i == 0 ? 'Home' : names[i],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: index == i
                                  ? context.tokens.onReceive
                                  : context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              Container(
                width: 224,
                padding: const EdgeInsets.fromLTRB(24, 36, 20, 24),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: context.colors.onSurface.withValues(alpha: .06),
                    ),
                  ),
                ),
                child: navigation(true),
              ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 40 : 22,
                      22,
                      wide ? 40 : 22,
                      12,
                    ),
                    child: Row(
                      children: [
                        if (!wide) ...[
                          const Icon(Icons.eco_rounded, size: 25),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          wide ? 'YOUR PERSONAL MONEY SPACE' : 'money plant.',
                          style: wide
                              ? context.type.labelSmall
                              : context.type.titleLarge,
                        ),
                        const Spacer(),
                        if (wide)
                          Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: Text(
                              DateFormat('EEEE, d MMMM').format(DateTime.now()),
                              style: TextStyle(
                                fontSize: 12,
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        IconButton(
                          tooltip: context.dark
                              ? 'Switch to light theme'
                              : 'Switch to dark theme',
                          onPressed: () => perform(
                            context,
                            () => store.change(
                              (d) => d.theme = context.dark ? 'light' : 'dark',
                            ),
                          ),
                          icon: Icon(
                            context.dark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            size: 21,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Settings',
                          onPressed: () =>
                              sheet(context, const SettingsSheet()),
                          icon: const Icon(Icons.tune_rounded, size: 21),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: ValueKey(index),
                      padding: EdgeInsets.fromLTRB(
                        wide ? 40 : 20,
                        14,
                        wide ? 40 : 20,
                        28,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: AnimatedSwitcher(
                            duration: GardenMotion.duration,
                            child: KeyedSubtree(
                              key: ValueKey(index),
                              child: Arrival(child: page),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!wide)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                      child: Surface(
                        padding: const EdgeInsets.all(6),
                        child: navigation(false),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: index == 4
          ? FloatingActionButton(
              tooltip: 'Add transaction',
              onPressed: () => sheet(
                context,
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...['Expense', 'Income', 'Split', 'Task'].map(
                      (mode) => ListTile(
                        title: Text(mode),
                        onTap: () {
                          Navigator.pop(context);
                          openComposer(
                            context,
                            mode: mode == 'Split'
                                ? 'expense'
                                : mode.toLowerCase(),
                            split: mode == 'Split',
                          );
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Import statement'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ImportFlow()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
