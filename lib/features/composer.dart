import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/design.dart';
import '../core/models.dart';
import '../data/garden_store.dart';
import '../shared/widgets.dart';

void openComposer(
  BuildContext context, {
  String mode = 'expense',
  Entry? entry,
  GardenTask? task,
  Goal? goal,
  bool split = false,
}) => sheet(
  context,
  Composer(mode: mode, entry: entry, task: task, goal: goal, split: split),
);

class Composer extends ConsumerStatefulWidget {
  final String mode;
  final Entry? entry;
  final GardenTask? task;
  final Goal? goal;
  final bool split;
  const Composer({
    super.key,
    required this.mode,
    this.entry,
    this.task,
    this.goal,
    this.split = false,
  });
  @override
  ConsumerState<Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<Composer> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title, amount, notes;
  final person = TextEditingController();
  final people = <Person>[];
  final weights = <String, TextEditingController>{
    'self': TextEditingController(text: '1'),
  };
  late String mode, category, direction;
  String payer = 'self';
  String? taskPerson;
  late DateTime date;
  late bool split;
  bool saving = false;
  SplitMethod method = SplitMethod.equal;
  String? error;
  @override
  void initState() {
    super.initState();
    mode = widget.mode;
    title = TextEditingController(
      text: widget.entry?.title ?? widget.task?.title ?? widget.goal?.title,
    );
    final initialAmount =
        widget.entry?.amount ?? widget.task?.amount ?? widget.goal?.target;
    amount = TextEditingController(
      text: initialAmount == null || initialAmount == 0
          ? ''
          : (initialAmount / 100).toStringAsFixed(2),
    );
    notes = TextEditingController(
      text: widget.entry?.notes ?? widget.task?.notes,
    );
    category = widget.entry?.category ?? (mode == 'income' ? 'Salary' : 'Food');
    direction = widget.task?.direction ?? 'none';
    taskPerson = widget.task?.personId;
    date =
        widget.entry?.date ??
        widget.task?.date ??
        widget.goal?.date ??
        DateTime.now();
    split = widget.split;
  }

  @override
  void dispose() {
    title.dispose();
    amount.dispose();
    notes.dispose();
    person.dispose();
    for (final c in weights.values) {
      c.dispose();
    }
    super.dispose();
  }

  void addPerson() {
    final name = person.text.trim();
    if (name.isEmpty) return;
    final existing = ref
        .read(gardenProvider)
        .data
        .people
        .where((p) => p.name.toLowerCase() == name.toLowerCase())
        .firstOrNull;
    final p = existing ?? Person(id: newId(), name: name);
    if (people.any((x) => x.id == p.id) || name.toLowerCase() == 'you') return;
    setState(() {
      people.add(p);
      weights[p.id] = TextEditingController(text: '1');
      person.clear();
    });
  }

  List<int> allocation() {
    final values = ['self', ...people.map((p) => p.id)].map((id) {
      if (method == SplitMethod.equal) return 1;
      final raw = weights[id]!.text.trim();
      if (raw == '0' || raw == '0.00') return 0;
      return method == SplitMethod.shares ? int.parse(raw) : parseMoney(raw);
    }).toList();
    return allocateSplit(parseMoney(amount.text), method, values);
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final store = ref.read(gardenProvider);
      final value = mode == 'task' && amount.text.isEmpty
          ? 0
          : parseMoney(amount.text);
      if (mode == 'task') {
        await store.saveTask(
          GardenTask(
            id: widget.task?.id ?? newId(),
            title: title.text.trim(),
            amount: value,
            date: date,
            direction: direction,
            notes: notes.text.trim(),
            completed: widget.task?.completed ?? false,
            personId: taskPerson,
          ),
        );
      } else if (mode == 'goal') {
        await store.saveGoal(
          Goal(
            id: widget.goal?.id ?? newId(),
            title: title.text.trim(),
            target: value,
            date: date,
          ),
        );
      } else if (split) {
        final portions = allocation();
        final ids = ['self', ...people.map((p) => p.id)];
        await store.saveSplit(
          BillSplit(
            id: newId(),
            title: title.text.trim(),
            total: value,
            date: date,
            method: method,
            portions: Map.fromIterables(ids, portions),
            payerId: payer,
          ),
          people,
          category: category,
          notes: notes.text.trim(),
        );
      } else {
        await store.saveEntry(
          Entry(
            id: widget.entry?.id ?? newId(),
            title: title.text.trim(),
            amount: value,
            date: date,
            createdAt: widget.entry?.createdAt ?? DateTime.now(),
            category: category,
            kind: mode,
            notes: notes.text.trim(),
          ),
        );
      }
      HapticFeedback.lightImpact();
      if (mounted) {
        Navigator.pop(context);
        toast(context, 'Saved. A little care goes a long way 🌱');
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e.toString().replaceFirst('FormatException: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(gardenProvider);
    List<int>? preview;
    String? splitError;
    if (split) {
      try {
        preview = allocation();
      } catch (e) {
        splitError = e.toString().replaceFirst('FormatException: ', '');
      }
    }
    final editing =
        widget.entry != null || widget.task != null || widget.goal != null;
    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${editing ? 'Edit' : 'New'} ${split ? 'split' : mode}',
                  style: context.type.headlineMedium,
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            mode == 'goal'
                ? 'Make room for something good.'
                : mode == 'task'
                ? 'Less on your mind. More in your garden.'
                : 'Small moments. A clearer money story.',
            style: TextStyle(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          if (!editing && mode != 'goal')
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Expense')),
                  ButtonSegment(value: 'income', label: Text('Income')),
                  ButtonSegment(value: 'task', label: Text('Task')),
                ],
                selected: {mode},
                onSelectionChanged: (v) => setState(() {
                  mode = v.first;
                  split = false;
                  category = mode == 'income' ? 'Salary' : 'Food';
                }),
              ),
            ),
          TextFormField(
            controller: amount,
            style: context.type.displaySmall,
            decoration: InputDecoration(
              prefixText: '${store.data.currency}  ',
              hintText: '0.00',
              labelText: mode == 'goal'
                  ? 'Target amount'
                  : mode == 'task'
                  ? 'Amount (optional)'
                  : 'Amount',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (mode == 'task' && (v ?? '').isEmpty) return null;
              try {
                parseMoney(v ?? '');
                return null;
              } catch (_) {
                return 'Enter a positive amount, up to 2 decimals.';
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: title,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: mode == 'goal'
                  ? 'What are you saving for?'
                  : mode == 'task'
                  ? 'What needs doing?'
                  : 'What was it for?',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Give this a name.' : null,
          ),
          const SizedBox(height: 18),
          if (mode == 'expense' || mode == 'income')
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children:
                  (mode == 'income'
                          ? ['Salary', 'Freelance', 'Gift', 'Other']
                          : [
                              'Food',
                              'Travel',
                              'Shopping',
                              'Bills',
                              'Health',
                              'Other',
                            ])
                      .map(
                        (c) => ChoiceChip(
                          label: Text(c),
                          selected: category == c,
                          onSelected: (_) => setState(() => category = c),
                        ),
                      )
                      .toList(),
            ),
          if (mode == 'task') ...[
            DropdownButtonFormField<String>(
              initialValue: direction,
              decoration: const InputDecoration(labelText: 'Money direction'),
              items: ['none', 'lend', 'borrow', 'repay', 'collect']
                  .map(
                    (d) => DropdownMenuItem(
                      value: d,
                      child: Text(d == 'none' ? 'Just a task' : d),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => direction = v!),
            ),
            const SizedBox(height: 12),
            if (store.data.people.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: taskPerson,
                decoration: const InputDecoration(
                  labelText: 'Person (optional)',
                ),
                items: store.data.people
                    .map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => taskPerson = v),
              ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [-1, 0, 1]
                .map(
                  (offset) => ActionChip(
                    label: Text(['Yesterday', 'Today', 'Tomorrow'][offset + 1]),
                    onPressed: () => setState(() {
                      final now = DateTime.now();
                      date = DateTime(
                        now.year,
                        now.month,
                        now.day + offset,
                        now.hour,
                        now.minute,
                      );
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(DateFormat('EEE, d MMM yyyy').format(date)),
            onPressed: () async {
              final chosen = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(1970),
                lastDate: DateTime(2100),
              );
              if (chosen != null) {
                setState(
                  () => date = DateTime(
                    chosen.year,
                    chosen.month,
                    chosen.day,
                    date.hour,
                    date.minute,
                  ),
                );
              }
            },
          ),
          if (mode != 'goal')
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('More options'),
              children: [
                TextFormField(
                  controller: notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: Text('Time · ${DateFormat.Hm().format(date)}'),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(date),
                    );
                    if (time != null) {
                      setState(
                        () => date = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          if (mode == 'expense' && !editing) ...[
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('Split this bill', style: context.type.titleLarge),
              subtitle: const Text('Good times, fair shares.'),
              value: split,
              onChanged: (v) => setState(() => split = v),
            ),
            if (split) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: person,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Add a person',
                      ),
                      onSubmitted: (_) => addPerson(),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: 'Add person',
                    onPressed: addPerson,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              if (store.data.people.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 6,
                    children: store.data.people
                        .where((p) => !people.any((x) => x.id == p.id))
                        .map(
                          (p) => ActionChip(
                            label: Text(p.name),
                            onPressed: () {
                              person.text = p.name;
                              addPerson();
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: SplitMethod.values
                    .map(
                      (m) => ChoiceChip(
                        label: Text(m.name),
                        selected: method == m,
                        onSelected: (_) => setState(() => method = m),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              ...List.generate(people.length + 1, (i) {
                final id = i == 0 ? 'self' : people[i - 1].id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Palette.lilac,
                        child: Text(
                          i == 0 ? 'Y' : people[i - 1].name[0],
                          style: const TextStyle(color: Palette.ink),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(i == 0 ? 'You' : people[i - 1].name),
                      ),
                      if (method != SplitMethod.equal)
                        SizedBox(
                          width: 86,
                          child: TextField(
                            controller: weights[id],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              suffixText: method == SplitMethod.percentage
                                  ? '%'
                                  : null,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      const SizedBox(width: 10),
                      AnimatedSwitcher(
                        duration: Palette.motion,
                        child: Text(
                          preview == null
                              ? '—'
                              : money(preview[i], store.data.currency),
                          key: ValueKey(preview?[i]),
                        ),
                      ),
                      if (i > 0)
                        IconButton(
                          tooltip: 'Remove person',
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => setState(() {
                            people.removeAt(i - 1);
                            weights.remove(id)?.dispose();
                            if (payer == id) payer = 'self';
                          }),
                        ),
                    ],
                  ),
                );
              }),
              DropdownButtonFormField<String>(
                key: ValueKey(payer),
                initialValue: payer,
                decoration: const InputDecoration(labelText: 'Who paid?'),
                items: [
                  const DropdownMenuItem(
                    value: 'self',
                    child: Text('You paid the bill'),
                  ),
                  ...people.map(
                    (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ),
                ],
                onChanged: (v) => setState(() => payer = v!),
              ),
              const SizedBox(height: 12),
              Text(
                splitError ??
                    'Every little bit accounted for. Shares match the total.',
                style: TextStyle(
                  color: splitError == null
                      ? context.colors.primary
                      : context.colors.error,
                ),
              ),
            ],
          ],
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                error!,
                style: TextStyle(color: context.colors.error),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: saving || (split && preview == null) ? null : save,
            child: Text(
              saving ? 'Saving…' : 'Save ${split ? 'split' : mode}  ↗',
            ),
          ),
        ],
      ),
    );
  }
}

class AmountSheet extends StatefulWidget {
  final String title, subtitle, currency;
  final int? initial;
  final bool allowRecord;
  final Future<void> Function(int, bool) onSave;
  const AmountSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currency,
    required this.onSave,
    this.initial,
    this.allowRecord = false,
  });
  @override
  State<AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<AmountSheet> {
  late final TextEditingController amount = TextEditingController(
    text: widget.initial == null
        ? ''
        : (widget.initial! / 100).toStringAsFixed(2),
  );
  bool record = false, saving = false;
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(widget.title, style: context.type.headlineMedium),
      const SizedBox(height: 8),
      Text(widget.subtitle),
      const SizedBox(height: 24),
      TextField(
        controller: amount,
        autofocus: true,
        style: context.type.displaySmall,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          prefixText: '${widget.currency} ',
          hintText: '0.00',
        ),
      ),
      if (widget.allowRecord)
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Also record as an expense'),
          subtitle: const Text('Off: update goal progress only.'),
          value: record,
          onChanged: (v) => setState(() => record = v),
        ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: saving
            ? null
            : () async {
                setState(() => saving = true);
                final ok = await perform(
                  context,
                  () => widget.onSave(parseMoney(amount.text), record),
                );
                if (context.mounted && ok) {
                  Navigator.pop(context);
                  toast(context, 'Saved. Your garden is growing 🌱');
                } else if (mounted) {
                  setState(() => saving = false);
                }
              },
        child: Text(saving ? 'Saving…' : 'Confirm  ↗'),
      ),
    ],
  );
}
