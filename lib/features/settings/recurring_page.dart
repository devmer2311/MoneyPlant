import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/models.dart';
import '../../data/garden_store.dart';
import '../../data/recurring_operations.dart';
import '../../shared/actions.dart';
import '../../shared/widgets.dart';

class RecurringPage extends ConsumerWidget {
  const RecurringPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gardenProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Recurring entries')),
      body: ListView(
        children: [
          if (s.data.recurring.isEmpty)
            const ListTile(
              title: Text('Use Repeat when adding income or an expense.'),
            ),
          ...s.data.recurring.map(
            (r) => ListTile(
              title: Text(r.title),
              subtitle: Text(
                '${r.frequency} · ${money(r.amount, s.data.currency)}',
              ),
              onTap: () => sheet(context, RecurringEditor(rule: r)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: !r.paused,
                    onChanged: (v) => perform(
                      context,
                      () => s.saveRecurring(
                        RecurringRule.fromJson({...r.toJson(), 'paused': !v}),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => changeWithUndo(
                      context,
                      s,
                      () => s.change(
                        (d) => d.recurring.removeWhere((x) => x.id == r.id),
                      ),
                      'Recurring rule removed',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecurringEditor extends ConsumerStatefulWidget {
  final RecurringRule rule;
  const RecurringEditor({super.key, required this.rule});
  @override
  ConsumerState<RecurringEditor> createState() => _RecurringEditorState();
}

class _RecurringEditorState extends ConsumerState<RecurringEditor> {
  late final title = TextEditingController(text: widget.rule.title),
      amount = TextEditingController(
        text:
            '${widget.rule.amount ~/ 100}.${(widget.rule.amount % 100).toString().padLeft(2, '0')}',
      ),
      category = TextEditingController(text: widget.rule.category);
  late String frequency = widget.rule.frequency, kind = widget.rule.kind;
  late DateTime start = widget.rule.startDate;
  DateTime? end;
  @override
  void initState() {
    super.initState();
    end = widget.rule.endDate;
  }

  @override
  void dispose() {
    title.dispose();
    amount.dispose();
    category.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: title,
        decoration: const InputDecoration(labelText: 'Title'),
      ),
      TextField(
        controller: amount,
        decoration: const InputDecoration(labelText: 'Amount'),
        keyboardType: TextInputType.number,
      ),
      TextField(
        controller: category,
        decoration: const InputDecoration(labelText: 'Category'),
      ),
      DropdownButtonFormField<String>(
        initialValue: frequency,
        decoration: const InputDecoration(labelText: 'Frequency'),
        items: [
          'weekly',
          'monthly',
          'yearly',
        ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) => setState(() => frequency = v!),
      ),
      DropdownButtonFormField<String>(
        initialValue: kind,
        decoration: const InputDecoration(labelText: 'Type'),
        items: [
          'expense',
          'income',
        ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) => setState(() => kind = v!),
      ),
      TextButton(
        onPressed: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: start,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (date != null) setState(() => start = date);
        },
        child: Text(
          'Schedule from ${start.toIso8601String().split('T').first}',
        ),
      ),
      TextButton(
        onPressed: () async {
          if (end != null) {
            setState(() => end = null);
            return;
          }
          final date = await showDatePicker(
            context: context,
            initialDate: start,
            firstDate: start,
            lastDate: DateTime(2100),
          );
          if (date != null) setState(() => end = date);
        },
        child: Text(
          end == null
              ? 'Add end date'
              : 'Ends ${end!.toIso8601String().split('T').first} · Clear',
        ),
      ),
      FilledButton(
        onPressed: () async {
          final ok = await perform(
            context,
            () => ref
                .read(gardenProvider)
                .saveRecurring(
                  RecurringRule.fromJson({
                    ...widget.rule.toJson(),
                    'title': title.text.trim(),
                    'amount': parseMoney(amount.text),
                    'category': category.text.trim(),
                    'kind': kind,
                    'frequency': frequency,
                    'startDate': start.toIso8601String(),
                    'endDate': end?.toIso8601String(),
                    'dayOfMonth': start.day,
                    'weekday': start.weekday,
                  }),
                ),
          );
          if (ok && context.mounted) Navigator.pop(context);
        },
        child: const Text('Save recurring rule'),
      ),
    ],
  );
}
