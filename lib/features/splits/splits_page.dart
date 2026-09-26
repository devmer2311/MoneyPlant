import '../../shared/payment_row.dart';
import '../../shared/confetti.dart';
import '../import/import_flow.dart';
import 'groups_page.dart';
import '../../shared/actions.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design.dart';
import '../../data/garden_store.dart';
import '../../shared/widgets.dart';
import '../composer.dart';
import '../reports.dart';

import '../pages.dart';

class SplitsPage extends ConsumerWidget {
  const SplitsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(gardenProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ImportFlow(creditsOnly: true),
            ),
          ),
          icon: const Icon(Icons.upload_file),
          label: const Text('Import settlements'),
        ),
        PageIntro(
          'Good times. Fair shares.',
          'Keep the friendship. Lose the awkward maths.',
          action: 'Split a bill',
          onTap: () => openComposer(context, split: true),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GroupsPage()),
          ),
          icon: const Icon(Icons.groups_outlined),
          label: const Text('Groups & trips'),
        ),
        Row(
          children: [
            Expanded(
              child: Surface(
                color: context.tokens.selectedSurface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('To receive'),
                    const SizedBox(height: 14),
                    FittedBox(
                      child: MoneyCounter(
                        value: store.receivable,
                        currency: store.data.currency,
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
                color: context.tokens.oweSurface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('To pay'),
                    const SizedBox(height: 14),
                    FittedBox(
                      child: MoneyCounter(
                        value: store.owed,
                        currency: store.data.currency,
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
                          avatar: Hero(
                            tag: 'person:${p.id}',
                            child: CircleAvatar(child: Text(p.name[0])),
                          ),
                          label: Text(p.name),
                          onPressed: () => openPerson(context, p),
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
                    onLongPress: () => sheet(
                      context,
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: const Text('Share'),
                            onTap: () => perform(
                              context,
                              () => shareSplit(context, store, s),
                            ),
                          ),
                          ListTile(
                            title: const Text('PDF'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SplitReportPage(store: store, split: s),
                                ),
                              );
                            },
                          ),
                          if (s.payerId == 'self')
                            ListTile(
                              title: const Text('Nudge'),
                              onTap: () {
                                Navigator.pop(context);
                                sheet(
                                  context,
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (final person
                                          in store.data.people.where(
                                            (p) => store.remaining(s, p.id) > 0,
                                          ))
                                        ListTile(
                                          title: Text(person.name),
                                          onTap: () {
                                            Navigator.pop(context);
                                            sheet(
                                              context,
                                              NudgeSheet(
                                                person: person,
                                                amount: store.remaining(
                                                  s,
                                                  person.id,
                                                ),
                                                split: s,
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ListTile(
                            title: const Text('Edit'),
                            onTap: () {
                              Navigator.pop(context);
                              openComposer(context, bill: s);
                            },
                          ),
                        ],
                      ),
                    ),
                    title: Text(s.title, style: context.type.titleLarge),
                    subtitle: Text(
                      '${s.portions.length} people · ${DateFormat('d MMM').format(s.date)} · ${store.personName(s.payerId)} paid',
                    ),
                    trailing: Text(
                      money(s.total, store.data.currency, true),
                      style: context.type.titleLarge,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'Edit' || action == 'Duplicate') {
                            openComposer(
                              context,
                              bill: s,
                              duplicate: action == 'Duplicate',
                            );
                          } else if (await confirmRemove(
                                context,
                                s.title,
                                'This also removes its payments and linked ledger entries.',
                              ) &&
                              context.mounted) {
                            await changeWithUndo(
                              context,
                              store,
                              () => store.deleteSplit(s.id),
                              'Split removed',
                            );
                          }
                        },
                        itemBuilder: (_) => ['Edit', 'Duplicate', 'Delete']
                            .map((x) => PopupMenuItem(value: x, child: Text(x)))
                            .toList(),
                      ),
                    ],
                  ),
                  if (s.items.isNotEmpty)
                    ExpansionTile(
                      title: const Text('Items'),
                      children: s.items
                          .map(
                            (i) => ListTile(
                              title: Text(i.name),
                              trailing: Text(
                                money(i.amount, store.data.currency),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  const Divider(),
                  ...s.portions.entries.map((p) {
                    final rest = store.remaining(s, p.key);
                    final canPay = rest > 0;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: context.tokens.owe,
                        child: Text(
                          store.personName(p.key)[0],
                          style: TextStyle(color: context.tokens.onReceive),
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
                            (p) => PaymentRow(
                              store: store,
                              paymentId: p.id,
                              child: ListTile(
                                onLongPress: () => changeWithUndo(
                                  context,
                                  store,
                                  () => store.removePayment(p.id),
                                  'Payment removed',
                                ),
                                title: Text(store.personName(p.personId)),
                                subtitle: Text(
                                  DateFormat('d MMM yyyy · HH:mm')
                                      .format(p.date),
                                ),
                                trailing: Text(
                                  money(p.amount, store.data.currency),
                                ),
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
