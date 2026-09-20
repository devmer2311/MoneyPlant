import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/design.dart';
import '../core/models.dart';
import '../data/garden_store.dart';
import '../shared/widgets.dart';
import '../shared/depth.dart';
import 'composer.dart';
import 'reports.dart';

class PageIntro extends StatelessWidget {
  final String title, subtitle;
  final String? action;
  final VoidCallback? onTap;
  const PageIntro(
    this.title,
    this.subtitle, {
    super.key,
    this.action,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 26),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 16,
      spacing: 20,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: context.type.displaySmall?.copyWith(
                shadows: [
                  Shadow(
                    color: context.dark
                        ? const Color(0xFF45553B)
                        : const Color(0xFFDFE8D2),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
        if (action != null)
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add, size: 18),
            label: Text(action!),
          ),
      ],
    ),
  );
}

class EntryTile extends ConsumerWidget {
  final Entry entry;
  const EntryTile({super.key, required this.entry});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(gardenProvider);
    final e = entry;
    final icons = {
      'Food': Icons.restaurant_outlined,
      'Travel': Icons.train_outlined,
      'Shopping': Icons.shopping_bag_outlined,
      'Bills': Icons.bolt_outlined,
      'Health': Icons.favorite_border,
      'Salary': Icons.work_outline,
      'Settlement': Icons.people_outline,
      'Savings': Icons.flag_outlined,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 12,
      leading: DepthIcon(
        icons[e.category] ?? Icons.swap_horiz,
        size: 42,
        tint: e.incoming
            ? Palette.lime
            : e.splitId != null
            ? Palette.lilac
            : const Color(0xFFF4DAC6),
      ),
      title: Text(
        e.title,
        style: context.type.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${e.category} · ${DateFormat('d MMM').format(e.date)}${e.date.isAfter(DateTime.now()) ? ' · Planned' : ''}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Text(
        '${e.incoming ? '+' : '−'}${money(e.amount, store.data.currency, true)}',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: e.incoming ? context.colors.primary : null,
        ),
      ),
      onTap: () => sheet(context, _EntryDetails(entry: e)),
    );
  }
}

class _EntryDetails extends ConsumerWidget {
  final Entry entry;
  const _EntryDetails({required this.entry});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(gardenProvider);
    final linked = entry.splitId != null || entry.goalId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(entry.title, style: context.type.headlineMedium),
        const SizedBox(height: 20),
        FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(
            '${entry.incoming ? '+' : '−'}${money(entry.amount, store.data.currency)}',
            style: context.type.displayLarge,
          ),
        ),
        const SizedBox(height: 24),
        Tag('${entry.category} · ${entry.kind}'),
        const SizedBox(height: 16),
        Text(DateFormat('EEEE, d MMMM yyyy · HH:mm').format(entry.date)),
        if (entry.notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(entry.notes),
          ),
        const SizedBox(height: 24),
        if (linked)
          const Text(
            'This entry belongs to a split or goal. Its financial history is preserved here.',
          )
        else ...[
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              openComposer(context, mode: entry.kind, entry: entry);
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit entry'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              openComposer(
                context,
                mode: entry.kind,
                entry: Entry.fromJson({
                  ...entry.toJson(),
                  'id': newId(),
                  'createdAt': DateTime.now().toIso8601String(),
                }),
              );
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Duplicate'),
          ),
          TextButton.icon(
            onPressed: () async {
              final root = Navigator.of(context);
              final confirmed = await confirmRemove(
                context,
                entry.title,
                money(entry.amount, store.data.currency),
              );
              if (!confirmed || !context.mounted) return;
              final ok = await perform(
                context,
                () => store.removeEntry(entry.id),
              );
              if (context.mounted && ok) {
                final messenger = ScaffoldMessenger.of(context);
                root.pop();
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Entry removed'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        store.saveEntry(entry).catchError((Object _) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not restore. Please try again.',
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove entry'),
          ),
        ],
      ],
    );
  }
}

Future<bool> confirmRemove(
  BuildContext context,
  String title,
  String subtitle,
) async =>
    await sheet<bool>(
      context,
      Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              size: 40,
              color: context.colors.error,
            ),
            const SizedBox(height: 18),
            Text(
              'Let this one go?',
              style: context.type.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.type.titleLarge,
            ),
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep it'),
            ),
          ],
        ),
      ),
    ) ??
    false;

class LedgerPage extends ConsumerStatefulWidget {
  const LedgerPage({super.key});
  @override
  ConsumerState<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends ConsumerState<LedgerPage> {
  String query = '', filter = 'All', category = 'All categories';
  DateTimeRange? range;
  bool oldest = false;
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(gardenProvider);
    final entries =
        store.data.entries
            .where(
              (e) =>
                  '${e.title} ${e.notes} ${e.category}'.toLowerCase().contains(
                    query.toLowerCase(),
                  ) &&
                  (filter == 'All' ||
                      filter == 'Income' && e.kind == 'income' ||
                      filter == 'Expense' && !e.incoming ||
                      filter == 'Split' && e.splitId != null) &&
                  (category == 'All categories' || category == e.category) &&
                  (range == null ||
                      !e.date.isBefore(range!.start) &&
                          e.date.isBefore(
                            range!.end.add(const Duration(days: 1)),
                          )),
            )
            .toList()
          ..sort(
            (a, b) =>
                oldest ? a.date.compareTo(b.date) : b.date.compareTo(a.date),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageIntro(
          'Your money story.',
          'Every little thing, beautifully accounted for.',
        ),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search transactions, notes, categories…',
          ),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...['All', 'Income', 'Expense', 'Split'].map(
              (f) => ChoiceChip(
                label: Text(f),
                selected: filter == f,
                onSelected: (_) => setState(() => filter = f),
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.date_range, size: 16),
              label: Text(
                range == null
                    ? 'Date range'
                    : '${DateFormat.MMMd().format(range!.start)} – ${DateFormat.MMMd().format(range!.end)}',
              ),
              onPressed: () async {
                final r = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(1970),
                  lastDate: DateTime(2100),
                  initialDateRange: range,
                );
                if (r != null) setState(() => range = r);
              },
            ),
            if (range != null)
              ActionChip(
                label: const Text('Clear dates'),
                onPressed: () => setState(() => range = null),
              ),
            ActionChip(
              label: Text(oldest ? 'Oldest first ↑' : 'Newest first ↓'),
              onPressed: () => setState(() => oldest = !oldest),
            ),
          ],
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: category,
          items: [
            'All categories',
            ...store.data.entries.map((e) => e.category).toSet(),
          ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => category = v!),
        ),
        const SizedBox(height: 24),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (entries.isEmpty)
                EmptyGarden(
                  title: 'A clean page',
                  message: 'No transactions match this view.',
                  action: 'Add an entry',
                  onTap: () => openComposer(context),
                )
              else
                ...List.generate(
                  entries.length,
                  (i) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (i == 0 ||
                          DateFormat.yMd().format(entries[i].date) !=
                              DateFormat.yMd().format(entries[i - 1].date))
                        Padding(
                          padding: const EdgeInsets.only(top: 18, bottom: 5),
                          child: Text(
                            DateFormat('EEEE, d MMMM yyyy')
                                .format(entries[i].date)
                                .toUpperCase(),
                            style: context.type.labelSmall,
                          ),
                        ),
                      EntryTile(entry: entries[i]),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class TaskTile extends ConsumerWidget {
  final GardenTask task;
  const TaskTile({super.key, required this.task});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(gardenProvider);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconButton(
        tooltip: task.completed ? 'Completed' : 'Complete task',
        icon: Icon(
          task.completed ? Icons.check_circle : Icons.circle_outlined,
          color: task.completed
              ? context.colors.primary
              : context.colors.onSurfaceVariant,
        ),
        onPressed: task.completed
            ? null
            : () async {
                if (task.amount == 0 || task.direction == 'none') {
                  await perform(
                    context,
                    () => store.completeTask(task.id),
                    success: 'One less thing. +10 XP 🌱',
                  );
                  return;
                }
                await sheet(
                  context,
                  Builder(
                    builder: (context) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'One less thing on your mind.',
                          style: context.type.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(task.title),
                        const SizedBox(height: 8),
                        Text(
                          'Record ${money(task.amount, store.data.currency)} as ${['borrow', 'collect'].contains(task.direction) ? 'income' : 'an expense'}?',
                        ),
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: () async {
                            final ok = await perform(
                              context,
                              () => store.completeTask(task.id, record: true),
                            );
                            if (context.mounted && ok) Navigator.pop(context);
                          },
                          child: const Text('Record & complete'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final ok = await perform(
                              context,
                              () => store.completeTask(task.id),
                            );
                            if (context.mounted && ok) Navigator.pop(context);
                          },
                          child: const Text('Complete only'),
                        ),
                      ],
                    ),
                  ),
                );
              },
      ),
      title: Text(
        task.title,
        style: context.type.titleMedium?.copyWith(
          decoration: task.completed ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        '${DateFormat('d MMM').format(task.date)}${task.amount > 0 ? ' · ${money(task.amount, store.data.currency, true)}' : ''}${task.personId != null ? ' · ${store.personName(task.personId!)}' : ''}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: PopupMenuButton<String>(
        tooltip: 'Task options',
        onSelected: (v) async {
          if (v == 'edit') {
            openComposer(context, mode: 'task', task: task);
          } else if (await confirmRemove(
                context,
                task.title,
                'Remove this task from your garden?',
              ) &&
              context.mounted) {
            await perform(
              context,
              () => store.change(
                (d) => d.tasks.removeWhere((t) => t.id == task.id),
              ),
            );
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}

class TasksPage extends ConsumerWidget {
  const TasksPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(gardenProvider);
    final tasks = [...store.data.tasks]
      ..sort((a, b) => a.date.compareTo(b.date));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageIntro(
          'A clearer head.',
          'Little plans for a lighter tomorrow.',
          action: 'Add task',
          onTap: () => openComposer(context, mode: 'task'),
        ),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(
                'To do · ${tasks.where((t) => !t.completed).length}',
              ),
              if (!tasks.any((t) => !t.completed))
                const EmptyGarden(
                  title: 'A clear garden',
                  message: 'Nothing on the list. Enjoy the breathing room.',
                  icon: Icons.check_rounded,
                ),
              ...tasks.where((t) => !t.completed).map((t) => TaskTile(task: t)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (tasks.any((t) => t.completed))
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionTitle(
                  'Done & dusted',
                  action: 'Clear',
                  onTap: () async {
                    if (await confirmRemove(
                          context,
                          'Clear completed tasks',
                          'Your earned XP will stay.',
                        ) &&
                        context.mounted) {
                      await perform(
                        context,
                        () => store.change(
                          (d) => d.tasks.removeWhere((t) => t.completed),
                        ),
                      );
                    }
                  },
                ),
                ...tasks
                    .where((t) => t.completed)
                    .map((t) => TaskTile(task: t)),
              ],
            ),
          ),
      ],
    );
  }
}

class GoalCard extends ConsumerWidget {
  final Goal goal;
  const GoalCard({super.key, required this.goal});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(gardenProvider);
    final saved = store.progress(goal.id);
    final ratio = (saved / goal.target).clamp(0.0, 1.0);
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined),
              const SizedBox(width: 12),
              Expanded(child: Text(goal.title, style: context.type.titleLarge)),
              PopupMenuButton<String>(
                tooltip: 'Goal options',
                onSelected: (v) async {
                  if (v == 'edit') {
                    openComposer(context, mode: 'goal', goal: goal);
                  } else if (await confirmRemove(
                        context,
                        goal.title,
                        'Remove goal and progress? Recorded expenses stay in your ledger.',
                      ) &&
                      context.mounted) {
                    await perform(
                      context,
                      () => store.change((d) {
                        d.goals.removeWhere((g) => g.id == goal.id);
                        d.contributions.removeWhere((c) => c.goalId == goal.id);
                      }),
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit goal')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete goal'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            money(saved, store.data.currency, true),
            style: context.type.headlineMedium,
          ),
          Text(
            'of ${money(goal.target, store.data.currency, true)} · ${DateFormat('d MMM yyyy').format(goal.date)}',
            style: TextStyle(
              fontSize: 11,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              color: context.colors.primary,
              backgroundColor: context.colors.primary.withValues(alpha: .10),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Tag(
                ratio >= 1
                    ? '✦ Goal complete!'
                    : '${(ratio * 100).round()}% of the way',
              ),
              const Spacer(),
              TextButton(
                onPressed: () => sheet(
                  context,
                  AmountSheet(
                    title: 'A little closer.',
                    subtitle: goal.title,
                    currency: store.data.currency,
                    allowRecord: true,
                    onSave: (amount, record) =>
                        store.contribute(goal.id, amount, record: record),
                  ),
                ),
                child: const Text('Add savings ↗'),
              ),
            ],
          ),
          if (store.data.contributions.any((c) => c.goalId == goal.id))
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Contribution history',
                style: TextStyle(fontSize: 12),
              ),
              children: store.data.contributions
                  .where((c) => c.goalId == goal.id)
                  .map(
                    (c) => ListTile(
                      dense: true,
                      title: Text(money(c.amount, store.data.currency)),
                      trailing: Text(DateFormat.yMMMd().format(c.date)),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class SplitsPage extends ConsumerWidget {
  const SplitsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(gardenProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageIntro(
          'Good times. Fair shares.',
          'Keep the friendship. Lose the awkward maths.',
          action: 'Split a bill',
          onTap: () => openComposer(context, split: true),
        ),
        Row(
          children: [
            Expanded(
              child: Surface(
                color: context.dark ? const Color(0xFF30462E) : Palette.lime,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('To receive'),
                    const SizedBox(height: 14),
                    FittedBox(
                      child: Text(
                        money(store.receivable, store.data.currency),
                        style: context.type.headlineMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Surface(
                color: context.dark ? const Color(0xFF393045) : Palette.lilac,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('To pay'),
                    const SizedBox(height: 14),
                    FittedBox(
                      child: Text(
                        money(store.owed, store.data.currency),
                        style: context.type.headlineMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (store.data.people.isNotEmpty)
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Your people'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: store.data.people
                      .map(
                        (p) => ActionChip(
                          avatar: CircleAvatar(child: Text(p.name[0])),
                          label: Text(p.name),
                          onPressed: () =>
                              sheet(context, PersonDetails(person: p)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        if (store.data.splits.isEmpty)
          Surface(
            child: EmptyGarden(
              title: 'Memories, minus the maths',
              message: 'Dinner, a trip, or the group gift.\nStart a split and keep everyone in the loop.',
              icon: Icons.people_outline,
              action: 'Split your first bill',
              onTap: () => openComposer(context, split: true),
            ),
          ),
        ...store.data.splits.reversed.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Surface(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.title, style: context.type.titleLarge),
                    subtitle: Text(
                      '${s.portions.length} people · ${DateFormat('d MMM').format(s.date)} · ${store.personName(s.payerId)} paid',
                    ),
                    trailing: Text(
                      money(s.total, store.data.currency, true),
                      style: context.type.titleLarge,
                    ),
                  ),
                  const Divider(),
                  ...s.portions.entries.map((p) {
                    final rest = store.remaining(s, p.key);
                    final canPay =
                        rest > 0 && (s.payerId == 'self' || p.key == 'self');
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Palette.lilac,
                        child: Text(
                          store.personName(p.key)[0],
                          style: const TextStyle(color: Palette.ink),
                        ),
                      ),
                      title: Text(
                        store.personName(p.key),
                        style: context.type.titleMedium,
                      ),
                      subtitle: Text(
                        '${money(p.value, store.data.currency)} · ${rest == 0
                            ? 'Paid'
                            : store.paid(s, p.key) > 0
                            ? 'Partial · ${money(rest, store.data.currency)} left'
                            : 'Pending'}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: canPay
                          ? TextButton(
                              onPressed: () => sheet(
                                context,
                                AmountSheet(
                                  title: p.key == 'self'
                                      ? 'Settle your share.'
                                      : '${store.personName(p.key)} paid you.',
                                  subtitle:
                                      '${s.title} · ${money(rest, store.data.currency)} remaining',
                                  currency: store.data.currency,
                                  initial: rest,
                                  onSave: (amount, _) => store.recordPayment(
                                    s.id,
                                    p.key,
                                    amount,
                                    DateTime.now(),
                                  ),
                                ),
                              ),
                              child: const Text('Settle ↗'),
                            )
                          : Icon(
                              rest == 0
                                  ? Icons.check_circle_outline
                                  : Icons.hourglass_empty,
                              size: 20,
                            ),
                    );
                  }),
                  if (store.data.payments.any((p) => p.splitId == s.id))
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'Payment history',
                        style: TextStyle(fontSize: 12),
                      ),
                      children: store.data.payments
                          .where((p) => p.splitId == s.id)
                          .map(
                            (p) => ListTile(
                              title: Text(store.personName(p.personId)),
                              subtitle: Text(
                                DateFormat('d MMM yyyy · HH:mm').format(p.date),
                              ),
                              trailing: Text(
                                money(p.amount, store.data.currency),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => perform(
                          context,
                          () => shareSplit(context, store, s),
                        ),
                        icon: const Icon(Icons.ios_share, size: 17),
                        label: const Text('Share summary'),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SplitReportPage(store: store, split: s),
                          ),
                        ),
                        icon: const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 17,
                        ),
                        label: const Text('PDF'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PersonDetails extends ConsumerWidget {
  final Person person;
  const PersonDetails({super.key, required this.person});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(gardenProvider);
    final splits = store.data.splits.where(
      (s) => s.portions.containsKey(person.id),
    );
    final receive = splits
        .where((s) => s.payerId == 'self')
        .fold(0, (a, s) => a + store.remaining(s, person.id));
    final owe = splits
        .where((s) => s.payerId == person.id)
        .fold(0, (a, s) => a + store.remaining(s, 'self'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(person.name, style: context.type.headlineMedium),
        const SizedBox(height: 20),
        Text(
          money(receive - owe, store.data.currency),
          style: context.type.displaySmall,
        ),
        Text(
          'Net balance · ${money(receive, store.data.currency)} to receive · ${money(owe, store.data.currency)} to pay',
        ),
        const Divider(),
        ...splits.map(
          (s) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.title),
            subtitle: Text(DateFormat.yMMMd().format(s.date)),
            trailing: Text(
              money(
                s.payerId == 'self'
                    ? store.remaining(s, person.id)
                    : s.payerId == person.id
                    ? -store.remaining(s, 'self')
                    : 0,
                store.data.currency,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});
  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(gardenProvider);
    final expenses = store.posted.where(
      (e) =>
          !e.incoming &&
          e.date.year == month.year &&
          e.date.month == month.month,
    );
    final categories = <String, int>{};
    for (final e in expenses) {
      categories.update(
        e.category,
        (v) => v + e.amount,
        ifAbsent: () => e.amount,
      );
    }
    final ordered = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = store.monthTotal(false, month);
    final income = store.monthTotal(true, month);
    final months = List.generate(
      6,
      (i) => DateTime(month.year, month.month - 5 + i),
    );
    final maxSpend = months
        .map((m) => store.monthTotal(false, m))
        .fold(1, math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageIntro(
          'See the bigger picture.',
          'A little perspective on where your money goes.',
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: () =>
                  setState(() => month = DateTime(month.year, month.month - 1)),
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              DateFormat('MMMM yyyy').format(month),
              style: context.type.titleLarge,
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: () =>
                  setState(() => month = DateTime(month.year, month.month + 1)),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Spending rhythm'),
              Text(
                money(total, store.data.currency),
                style: context.type.displaySmall,
              ),
              const SizedBox(height: 6),
              Text(
                '${money(income, store.data.currency)} income this month · Settlements are shown separately in your ledger.',
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 185,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: months.map((m) {
                    final value = store.monthTotal(false, m);
                    return Expanded(
                      child: Tooltip(
                        message:
                            '${DateFormat.yMMM().format(m)} · ${money(value, store.data.currency)}',
                        child: InkWell(
                          onTap: () => setState(() => month = m),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                money(value, store.data.currency, true),
                                style: const TextStyle(fontSize: 9),
                              ),
                              const SizedBox(height: 8),
                              AnimatedContainer(
                                duration: Palette.motion,
                                height: 8 + value / maxSpend * 115,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: m == month
                                      ? context.colors.primary
                                      : (context.dark
                                            ? const Color(0xFF47573B)
                                            : Palette.lime),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                DateFormat.MMM().format(m),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Where it went'),
              if (ordered.isEmpty)
                const EmptyGarden(
                  title: 'A little more time to bloom',
                  message: 'Add expenses to discover your spending patterns.',
                  icon: Icons.bar_chart,
                ),
              ...ordered.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(c.key)),
                          Text(
                            '${money(c.value, store.data.currency)} · ${(c.value / total * 100).round()}%',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: c.value / total,
                          minHeight: 7,
                          backgroundColor: context.colors.primary.withValues(
                            alpha: .08,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Small wins, real growth'),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  Tag('${store.streak()} day streak'),
                  Tag('${store.xp} XP'),
                  Tag(
                    '${store.data.tasks.where((t) => t.completed).length} tasks completed',
                  ),
                  Tag(
                    '${store.data.goals.where((g) => store.progress(g.id) >= g.target).length} goals reached',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (store.data.activity.keys.any(
                    (k) => k.startsWith('entry:'),
                  ))
                    const Tag('✦ First seed', color: Palette.lime),
                  if (store.data.goals.isNotEmpty)
                    const Tag('✦ Goal setter', color: Palette.lilac),
                  if (store.streak() >= 7)
                    const Tag('✦ Growing · 7 day streak', color: Palette.lime),
                  if (store.data.activity.keys.any(
                    (k) => k.startsWith('goal:'),
                  ))
                    const Tag('✦ Goal keeper', color: Palette.lilac),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
