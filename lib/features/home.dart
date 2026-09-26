import '../core/recurring.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design.dart';
import '../data/garden_store.dart';
import '../shared/widgets.dart';
import '../shared/depth.dart';
import 'composer.dart';
import 'pages.dart';

class HomePage extends ConsumerWidget {
  final ValueChanged<int> onNavigate;
  const HomePage({super.key, required this.onNavigate});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(gardenProvider);
    final currency = store.data.currency;
    final now = DateTime.now();
    final recent = [...store.data.entries]
      ..sort((a, b) => b.date.compareTo(a.date));
    final pending = store.data.tasks.where((t) => !t.completed).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 700;
        Widget columns(
          Widget left,
          Widget right, {
          int leftFlex = 3,
          int rightFlex = 2,
        }) => wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: leftFlex, child: left),
                  const SizedBox(width: 20),
                  Expanded(flex: rightFlex, child: right),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [left, const SizedBox(height: 20), right],
              );
        final hero = Surface(
          color: context.tokens.hero,
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'AVAILABLE BALANCE',
                      style: TextStyle(
                        color: context.tokens.heroMuted,
                        fontSize: 10,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: store.balance.toDouble()),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, _) => Text(
                    money(value.round(), currency),
                    style: context.type.displayLarge?.copyWith(
                      color: context.tokens.heroInk,
                      shadows: [
                        Shadow(
                          color: context.tokens.heroShadow,
                          offset: Offset(0, 3),
                        ),
                        Shadow(
                          color: context.tokens.translucentShadow,
                          offset: Offset(0, 7),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                store.data.entries.isEmpty
                    ? 'A fresh start. So much room to grow.'
                    : 'A little awareness makes a big difference.',
                style: TextStyle(color: context.tokens.heroMuted, fontSize: 12),
              ),
              const SizedBox(height: 28),
              Divider(color: context.tokens.heroDivider, height: 1),
              const SizedBox(height: 23),
              Row(
                children: [
                  Expanded(
                    child: _HeroStat(
                      'Income this month',
                      money(store.monthTotal(true, now), currency, true),
                      Icons.south_west,
                      context.tokens.receive,
                    ),
                  ),
                  Expanded(
                    child: _HeroStat(
                      'Spent this month',
                      money(store.monthTotal(false, now), currency, true),
                      Icons.north_east,
                      context.tokens.owe,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
        final garden = Surface(
          color: context.tokens.savingSurface,
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Your little garden', style: context.type.titleLarge),
                  const Spacer(),
                  const Icon(Icons.auto_awesome_outlined, size: 19),
                ],
              ),
              Center(child: PlantArt(stage: store.stage, size: 150)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      store.stageName,
                      style: context.type.titleMedium,
                    ),
                  ),
                  Tag('${store.xp} XP'),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: store.stage == 5 ? 1 : (store.xp % 100) / 100,
                  minHeight: 5,
                  color: context.tokens.brand,
                  backgroundColor: context.colors.onSurface.withValues(
                    alpha: .08,
                  ),
                ),
              ),
              const SizedBox(height: 11),
              Text(
                store.streak() == 0
                    ? 'Log a little. Grow a little.'
                    : '${store.streak()} day streak · Look at you grow.',
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MantraHeadline(wide: wide),
                      const SizedBox(height: 10),
                      Text(
                        'Track the little things. Grow into bigger dreams.',
                        style: TextStyle(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (wide)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Tag('LET’S GROW ↗', color: context.tokens.owe),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            wide ? columns(hero, garden) : hero,
            const SizedBox(height: 26),
            Surface(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (i) {
                  const labels = ['Expense', 'Income', 'Task', 'Split', 'Goal'];
                  const icons = [
                    Icons.north_east,
                    Icons.south_west,
                    Icons.check_rounded,
                    Icons.call_split_rounded,
                    Icons.flag_outlined,
                  ];
                  final tints = [
                    context.tokens.expenseAccent,
                    context.tokens.receive,
                    context.tokens.owe,
                    context.tokens.splitAccent,
                    context.tokens.goalAccent,
                  ];
                  return Expanded(
                    child: TactileAction(
                      label: labels[i],
                      icon: icons[i],
                      tint: tints[i],
                      onTap: () => openComposer(
                        context,
                        mode: [
                          'expense',
                          'income',
                          'task',
                          'expense',
                          'goal',
                        ][i],
                        split: i == 3,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 26),
            if (store.data.recurring.any((r) => !r.paused))
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Upcoming this week'),
                    ...store.data.recurring.expand(
                      (r) =>
                          occurrences(
                                r,
                                DateTime.now().add(const Duration(days: 7)),
                              )
                              .where((date) => date.isAfter(DateTime.now()))
                              .map(
                                (date) => ListTile(
                                  title: Text(r.title),
                                  subtitle: Text(dateKey(date)),
                                  trailing: Text(money(r.amount, currency)),
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            if (!wide) ...[garden, const SizedBox(height: 26)],
            columns(
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionTitle(
                      'The latest',
                      action: 'View all',
                      onTap: () => onNavigate(4),
                    ),
                    if (recent.isEmpty)
                      EmptyGarden(
                        title: 'Your story starts here',
                        message: 'Coffee, payday, or a little treat.\nGive your first transaction a home.',
                        icon: Icons.receipt_long_outlined,
                        action: 'Add your first entry',
                        onTap: () => openComposer(context),
                      )
                    else
                      ...recent.take(5).map((e) => EntryTile(entry: e)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Surface(
                    color: context.tokens.oweSurface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_outline_rounded),
                            const Spacer(),
                            IconButton(
                              tooltip: 'View splits',
                              onPressed: () => onNavigate(3),
                              icon: const Icon(Icons.north_east),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          store.receivable == 0 && store.owed == 0
                              ? 'Split the bill. Keep the vibe.'
                              : '${money(store.receivable, currency, true)} to receive',
                          style: context.type.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          store.owed == 0
                              ? 'Split the memories. Settle the money.'
                              : '${money(store.owed, currency)} still to pay.',
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton(
                          onPressed: () => openComposer(context, split: true),
                          child: const Text('Split a bill  ↗'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Surface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionTitle(
                          'On your mind',
                          action: 'Tasks',
                          onTap: () => onNavigate(2),
                        ),
                        if (pending.isEmpty)
                          const Text(
                            'Nothing due. Take a little breather. ☁',
                            style: TextStyle(fontSize: 12),
                          )
                        else
                          ...pending.take(3).map((t) => TaskTile(task: t)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SectionTitle(
              'Dream it. Grow it.',
              action: 'New goal',
              onTap: () => openComposer(context, mode: 'goal'),
            ),
            if (store.data.goals.isEmpty)
              Surface(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.tokens.selectedSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.flag_outlined, size: 26),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Something worth saving for?',
                            style: context.type.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'A weekend away. A rainy day. Your next big thing.',
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Create goal',
                      onPressed: () => openComposer(context, mode: 'goal'),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: store.data.goals
                    .map(
                      (g) => SizedBox(
                        width: wide
                            ? (constraints.maxWidth - 20) / 2
                            : constraints.maxWidth,
                        child: GoalCard(goal: g),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 30),
            Center(
              child: Text(
                'GROW AT YOUR OWN PACE  ·  MONEY PLANT',
                style: context.type.labelSmall,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _HeroStat(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 19),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: context.tokens.heroMuted, fontSize: 10),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: context.tokens.displayFont,
                  fontSize: 23,
                  color: context.tokens.highlight,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
