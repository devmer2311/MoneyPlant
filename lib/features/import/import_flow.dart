import 'split_options.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/models.dart';
import '../../core/import/statement_parser.dart';
import '../../core/import/matcher.dart';
import '../../data/garden_store.dart';
import '../../shared/actions.dart';
import '../../shared/widgets.dart';

class ImportFlow extends ConsumerStatefulWidget {
  final bool creditsOnly;
  const ImportFlow({super.key, this.creditsOnly = false});
  @override
  ConsumerState<ImportFlow> createState() => _ImportFlowState();
}

class _ImportFlowState extends ConsumerState<ImportFlow> {
  List<StatementRow> rows = [];
  final List<Person> newPeople = [];
  String filename = '', error = '', query = '';
  late String filter = widget.creditsOnly ? 'Credits' : 'All';
  bool busy = false;
  DateTimeRange? range;
  List<List<String>> cells = [];
  int header = 0;
  ColumnMapping? mapping;
  String? key;
  Future<void> pick() async {
    setState(() => busy = true);
    try {
      final file = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'pdf', 'xls'],
        withData: true,
      );
      if (file == null) return;
      final f = file.files.single;
      filename = f.name;
      try {
        cells = await statementCells(f.bytes!, f.extension!.toLowerCase());
      } catch (e) {
        if (f.extension?.toLowerCase() != 'pdf' ||
            !RegExp(
              'password|encrypt',
              caseSensitive: false,
            ).hasMatch(e.toString())) {
          rethrow;
        }
        if (!mounted) return;
        final password = await askText(
          context,
          'PDF password (not saved)',
          secret: true,
        );
        if (password == null) return;
        cells = await statementCells(f.bytes!, 'pdf', password: password);
      }
      final detected = detectMapping(cells);
      header = detected.$1;
      key = headerKey(cells[header]);
      mapping =
          ref.read(gardenProvider).data.importMappings[key] ?? detected.$2;
      if (mapping == null) {
        if (!mounted) return;
        mapping = await showDialog<ColumnMapping>(
          context: context,
          builder: (_) => MappingDialog(headers: cells[header]),
        );
      }
      if (mapping == null) return;
      rows = parseStatement(cells, header, mapping!);
      matchRows(rows, ref.read(gardenProvider));
      error = '';
    } catch (e) {
      error = e.toString().replaceFirst('FormatException: ', '');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(gardenProvider);
    final people = [...store.data.people, ...newPeople];
    final visible = rows
        .where(
          (r) =>
              (range == null ||
                  (!r.date.isBefore(range!.start) &&
                      r.date.isBefore(
                        range!.end.add(const Duration(days: 1)),
                      ))) &&
              (filter == 'All' ||
                  filter == 'Credits' && r.credit ||
                  filter == 'Debits' && !r.credit ||
                  filter == 'Matches' && r.personId != null) &&
              '${r.title} ${r.narration}'.toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList();
    final selected = rows.where((r) => r.selected && !r.duplicate).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import bank statement'),
        actions: [
          IconButton(
            onPressed: busy ? null : pick,
            tooltip: 'Choose file',
            icon: const Icon(Icons.file_open),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: busy || selected.isEmpty
                ? null
                : () async {
                    setState(() => busy = true);
                    await changeWithUndo(
                      context,
                      store,
                      () => commitImport(
                        store,
                        rows,
                        key: key,
                        mapping: mapping,
                        people: newPeople,
                      ),
                      'Added ${selected.length} items 🌱',
                    );
                    if (mounted) {
                      setState(() {
                        matchRows(rows, store);
                        busy = false;
                      });
                    }
                  },
            child: Text(
              'Add ${selected.length} items · ${money(selected.where((r) => !r.credit).fold(0, (a, r) => a + r.amount), store.data.currency)} out · ${money(selected.where((r) => r.credit).fold(0, (a, r) => a + r.amount), store.data.currency)} in',
            ),
          ),
        ),
      ),
      body: busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (rows.isEmpty)
                  FilledButton.icon(
                    onPressed: pick,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Choose CSV, XLSX or PDF'),
                  ),
                if (error.isNotEmpty)
                  Text(error, style: TextStyle(color: context.colors.error)),
                if (filename.isNotEmpty)
                  Text(
                    '$filename · ${rows.length} transactions · ${rows.where((r) => r.duplicate).length} already added · ${rows.where((r) => r.personId != null).length} matches',
                  ),
                if (rows.isNotEmpty) ...[
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search transactions',
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      range == null
                          ? 'Filter date range'
                          : '${range!.start.toIso8601String().split('T').first} – ${range!.end.toIso8601String().split('T').first}',
                    ),
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        initialDateRange: range,
                      );
                      if (picked != null && mounted) {
                        setState(() => range = picked);
                      }
                    },
                  ),
                  if (range != null)
                    TextButton(
                      onPressed: () => setState(() => range = null),
                      child: const Text('Clear dates'),
                    ),
                  Wrap(
                    children: ['All', 'Debits', 'Credits', 'Matches']
                        .map(
                          (v) => ChoiceChip(
                            label: Text(v),
                            selected: filter == v,
                            onSelected: (_) => setState(() => filter = v),
                          ),
                        )
                        .toList(),
                  ),
                  CheckboxListTile(
                    title: const Text('Select all new'),
                    value: rows
                        .where((r) => !r.duplicate && !r.possibleDuplicate)
                        .every((r) => r.selected),
                    onChanged: (v) => setState(() {
                      for (final r in rows.where(
                        (r) => !r.duplicate && !r.possibleDuplicate,
                      )) {
                        r.selected = v!;
                      }
                    }),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final name = await askText(
                        context,
                        'Add a person for splits',
                      );
                      if (name == null || name.trim().isEmpty) return;
                      if (name.toLowerCase() == 'you' ||
                          people.any(
                            (p) => p.name.toLowerCase() == name.toLowerCase(),
                          )) {
                        return;
                      }
                      setState(
                        () => newPeople.add(
                          Person(id: newId(), name: name.trim()),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add person for splits'),
                  ),
                  ...visible.map(
                    (r) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              value: r.selected && !r.duplicate,
                              onChanged: r.duplicate
                                  ? null
                                  : (v) => setState(() => r.selected = v!),
                              title: Text(
                                '${r.title} · ${money(r.amount, store.data.currency)}',
                              ),
                              subtitle: Text(
                                r.duplicate
                                    ? 'Already added'
                                    : r.possibleDuplicate
                                    ? 'Looks already added?'
                                    : r.narration,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: r.duplicate
                                      ? null
                                      : () async {
                                          final text = await askText(
                                            context,
                                            'Transaction title',
                                            initial: r.title,
                                          );
                                          if (text != null) {
                                            setState(() => r.title = text);
                                          }
                                        },
                                  child: const Text('Edit title'),
                                ),
                                TextButton(
                                  onPressed: r.duplicate
                                      ? null
                                      : () async {
                                          final text = await askText(
                                            context,
                                            'Category',
                                            initial: r.category,
                                          );
                                          if (text != null &&
                                              text.trim().isNotEmpty) {
                                            setState(() {
                                              r.category = text.trim();
                                              if (mapping != null) {
                                                mapping =
                                                    ColumnMapping.fromJson({
                                                      ...mapping!.toJson(),
                                                      'categoryRules': {
                                                        ...mapping!
                                                            .categoryRules,
                                                        r.title.toLowerCase():
                                                            text.trim(),
                                                      },
                                                    });
                                              }
                                            });
                                          }
                                        },
                                  child: Text(r.category),
                                ),
                                if (r.credit && !r.duplicate)
                                  TextButton(
                                    onPressed: () async {
                                      final target =
                                          await showDialog<(String, String)>(
                                            context: context,
                                            builder: (c) => SimpleDialog(
                                              title: const Text(
                                                'Record this payment for…',
                                              ),
                                              children: [
                                                for (final split
                                                    in store.data.splits.where(
                                                      (s) =>
                                                          s.payerId == 'self' &&
                                                          s.groupId == null,
                                                    ))
                                                  for (final id
                                                      in split.portions.keys
                                                          .where(
                                                            (id) =>
                                                                id != 'self' &&
                                                                store.remaining(
                                                                      split,
                                                                      id,
                                                                    ) >=
                                                                    r.amount,
                                                          ))
                                                    SimpleDialogOption(
                                                      onPressed: () =>
                                                          Navigator.pop(c, (
                                                            split.id,
                                                            id,
                                                          )),
                                                      child: Text(
                                                        '${store.personName(id)} · ${split.title} · ${money(store.remaining(split, id), store.data.currency)}',
                                                      ),
                                                    ),
                                              ],
                                            ),
                                          );
                                      if (target != null) {
                                        setState(() {
                                          r.splitId = target.$1;
                                          r.personId = target.$2;
                                        });
                                      }
                                    },
                                    child: const Text('Match payment'),
                                  ),
                                if (r.people.isNotEmpty)
                                  TextButton(
                                    onPressed: () async {
                                      await sheet(
                                        context,
                                        ImportSplitOptions(
                                          row: r,
                                          people: people,
                                        ),
                                      );
                                      if (mounted) setState(() {});
                                    },
                                    child: const Text('Who paid? / More…'),
                                  ),
                                if (r.personId != null)
                                  InputChip(
                                    label: Text(
                                      '🤝 ${store.personName(r.personId!)} payment',
                                    ),
                                    onDeleted: () => setState(() {
                                      r.splitId = null;
                                      r.personId = null;
                                    }),
                                  ),
                                if (!r.credit && !r.duplicate)
                                  FilterChip(
                                    label: const Text('Split'),
                                    selected: r.people.isNotEmpty,
                                    onSelected: (v) => setState(() {
                                      if (!v) {
                                        r.people.clear();
                                      } else if (people.isNotEmpty) {
                                        r.people.add(people.first.id);
                                      }
                                    }),
                                  ),
                              ],
                            ),
                            if (r.people.isNotEmpty)
                              Wrap(
                                children: people
                                    .map(
                                      (p) => FilterChip(
                                        label: Text(p.name),
                                        selected: r.people.contains(p.id),
                                        onSelected: (v) => setState(
                                          () => v
                                              ? r.people.add(p.id)
                                              : r.people.remove(p.id),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class MappingDialog extends StatefulWidget {
  final List<String> headers;
  const MappingDialog({super.key, required this.headers});
  @override
  State<MappingDialog> createState() => _MappingDialogState();
}

class _MappingDialogState extends State<MappingDialog> {
  final map = <String, int>{};
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Match statement columns'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: aliases.keys
            .map(
              (key) => DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: key),
                items: List.generate(
                  widget.headers.length,
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text(
                      '${i + 1}: ${widget.headers[i]}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                onChanged: (v) => setState(() => map[key] = v!),
              ),
            )
            .toList(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: !map.containsKey('date') || !map.containsKey('description')
            ? null
            : () => Navigator.pop(context, ColumnMapping.fromJson(map)),
        child: const Text('Use mapping'),
      ),
    ],
  );
}
