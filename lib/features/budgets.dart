import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design.dart';
import '../core/models.dart';
import '../core/upi.dart';
import '../data/garden_store.dart';
import '../shared/actions.dart';
import '../shared/widgets.dart';

class BudgetCard extends ConsumerWidget {
  final DateTime month;
  const BudgetCard({super.key, required this.month});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(gardenProvider);
    final categories = {
      'Food',
      'Transport',
      'Shopping',
      'Bills',
      'Entertainment',
      'Other',
      ...store.data.budgets.keys,
      ...store.data.entries
          .where((e) => e.kind == 'expense')
          .map((e) => e.category),
    };
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Monthly category budgets', style: context.type.titleLarge),
          ...categories.map((category) {
            final budget = store.data.budgets[category];
            final spent = store.data.entries
                .where(
                  (e) =>
                      e.kind == 'expense' &&
                      e.category == category &&
                      e.date.year == month.year &&
                      e.date.month == month.month &&
                      !e.date.isAfter(DateTime.now()),
                )
                .fold(0, (a, e) => a + e.amount);
            final ratio = budget == null ? 0.0 : spent / budget;
            final color = ratio >= 1
                ? context.tokens.danger
                : ratio >= .8
                ? context.tokens.warning
                : context.tokens.brand;
            final today = DateTime.now();
            final days =
                DateTime(month.year, month.month + 1, 0).day -
                (today.year == month.year && today.month == month.month
                    ? today.day - 1
                    : 0);
            final left = (budget ?? 0) - spent;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(category),
              subtitle: budget == null
                  ? const Text('Tap to set a budget')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${money(left, store.data.currency)} left · $days days · ${money(left > 0 ? left ~/ days : 0, store.data.currency)}/day',
                        ),
                        LinearProgressIndicator(
                          value: ratio.clamp(0, 1),
                          color: color,
                        ),
                      ],
                    ),
              trailing: budget == null
                  ? const Icon(Icons.add)
                  : Text(money(budget, store.data.currency)),
              onTap: () async {
                final value = await askText(
                  context,
                  '$category monthly budget (0 removes)',
                  initial: budget == null ? '' : minorDecimal(budget),
                );
                if (value != null && context.mounted) {
                  await perform(
                    context,
                    () => store.change((d) {
                      if (value.trim() == '0') {
                        d.budgets.remove(category);
                      } else {
                        d.budgets[category] = parseMoney(value);
                      }
                    }),
                  );
                }
              },
            );
          }),
        ],
      ),
    );
  }
}
