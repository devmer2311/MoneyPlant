import 'people/person_page.dart';
import '../shared/actions.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/design.dart';
import '../core/models.dart';
import '../data/garden_store.dart';
import '../shared/widgets.dart';
import '../shared/depth.dart';
import 'composer.dart';

export 'ledger_page.dart';
export 'tasks_page.dart';
export 'splits/splits_page.dart';
export 'people/person_page.dart';
export 'insights_page.dart';

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
                    color: context.tokens.headingShadow,
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
    return Dismissible(
      key: ValueKey('entry:${e.id}'),
      confirmDismiss: (direction) async {
        if (e.splitId != null ||
            e.goalId != null ||
            e.id.startsWith('group:')) {
          return false;
        }
        if (direction == DismissDirection.startToEnd) {
          openComposer(context, mode: e.kind, entry: e);
          return false;
        }
        await changeWithUndo(
          context,
          store,
          () => store.removeEntry(e.id),
          'Entry removed',
        );
        return false;
      },
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: 12,
        leading: DepthIcon(
          icons[e.category] ?? Icons.swap_horiz,
          size: 42,
          tint: e.incoming
              ? context.tokens.receive
              : e.splitId != null
              ? context.tokens.owe
              : context.tokens.entryAccent,
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
            fontFamily: context.tokens.displayFont,
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: e.incoming ? context.colors.primary : null,
          ),
        ),
        onTap: () {
          final payment = store.data.payments
              .where((p) => p.id == e.paymentId)
              .firstOrNull;
          final split = store.data.splits
              .where((s) => s.id == e.splitId)
              .firstOrNull;
          final id = payment?.personId == 'self'
              ? split?.payerId
              : payment?.personId;
          final person = store.data.people.where((p) => p.id == id).firstOrNull;
          if (person != null) {
            openPerson(context, person);
          } else {
            sheet(context, _EntryDetails(entry: e));
          }
        },
      ),
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
