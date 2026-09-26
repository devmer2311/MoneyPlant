import '../shared/actions.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/design.dart';
import '../core/models.dart';
import '../data/garden_store.dart';
import '../shared/widgets.dart';
import 'composer.dart';

import 'pages.dart';

class TaskTile extends ConsumerWidget {
  final GardenTask task;
  const TaskTile({super.key, required this.task});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(gardenProvider);
    return Dismissible(
      key: ValueKey('task:${task.id}'),
      confirmDismiss: (_) async {
        if (!task.completed) {
          await changeWithUndo(
            context,
            store,
            () => store.completeTask(task.id),
            'Task completed',
          );
        }
        return false;
      },
      child: ListTile(
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
