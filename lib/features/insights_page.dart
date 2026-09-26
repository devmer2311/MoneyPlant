import 'budgets.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/design.dart';
import '../data/garden_store.dart';
import '../shared/widgets.dart';

import 'pages.dart';

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
        BudgetCard(month: month),
        const SizedBox(height: 20),
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
                                duration: GardenMotion.duration,
                                height: 8 + value / maxSpend * 115,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: m == month
                                      ? context.colors.primary
                                      : (context.tokens.chartTrack),
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
                    Tag('✦ First seed', color: context.tokens.receive),
                  if (store.data.goals.isNotEmpty)
                    Tag('✦ Goal setter', color: context.tokens.owe),
                  if (store.streak() >= 7)
                    Tag(
                      '✦ Growing · 7 day streak',
                      color: context.tokens.receive,
                    ),
                  if (store.data.activity.keys.any(
                    (k) => k.startsWith('goal:'),
                  ))
                    Tag('✦ Goal keeper', color: context.tokens.owe),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
