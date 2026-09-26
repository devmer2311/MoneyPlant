import 'import/import_flow.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/design.dart';
import '../data/garden_store.dart';
import '../shared/widgets.dart';
import 'composer.dart';

import 'pages.dart';

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
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ImportFlow()),
          ),
          icon: const Icon(Icons.upload_file),
          label: const Text('Import statement'),
        ),
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
