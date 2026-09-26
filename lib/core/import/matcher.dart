import '../../core/models.dart';
import '../../data/garden_store.dart';
import 'statement_parser.dart';

void matchRows(List<StatementRow> rows, GardenStore store) {
  for (final row in rows) {
    row.duplicate =
        store.data.entries.any((e) => e.importRef == row.ref) ||
        store.data.activity.containsKey('import:${row.ref}');
    row.possibleDuplicate = store.data.entries.any(
      (e) =>
          e.importRef == null &&
          e.amount == row.amount &&
          e.incoming == row.credit &&
          e.date.year == row.date.year &&
          e.date.month == row.date.month &&
          e.date.day == row.date.day,
    );
    row.selected = !row.duplicate && !row.possibleDuplicate;
    if (!row.credit || row.duplicate) continue;
    final matches = <(BillSplit, String)>[];
    for (final s in store.data.splits.where(
      (s) => s.payerId == 'self' && s.groupId == null,
    )) {
      for (final p in s.portions.keys.where((p) => p != 'self')) {
        if (store.remaining(s, p) == row.amount) matches.add((s, p));
      }
    }
    if (matches.length == 1) {
      row.splitId = matches.single.$1.id;
      row.personId = matches.single.$2;
    } else {
      final named = matches
          .where(
            (m) => row.title.toLowerCase().contains(
              store.personName(m.$2).toLowerCase(),
            ),
          )
          .toList();
      if (named.length == 1) {
        row.splitId = named.single.$1.id;
        row.personId = named.single.$2;
      }
    }
    if (row.personId == null) {
      final totals = store.data.people
          .where((p) => store.personNet(p.id) == row.amount)
          .toList();
      if (totals.length == 1) {
        row.personId = totals.single.id;
      }
    }
  }
}

Future<void> commitImport(
  GardenStore store,
  List<StatementRow> rows, {
  String? key,
  ColumnMapping? mapping,
  List<Person> people = const [],
}) => store.change((d) {
  for (final p in people) {
    if (!d.people.any((x) => x.id == p.id)) d.people.add(p);
  }
  for (final row in rows.where((r) => r.selected && !r.duplicate)) {
    if (d.entries.any((e) => e.importRef == row.ref) ||
        d.activity.containsKey('import:${row.ref}')) {
      continue;
    }
    if (row.personId != null && row.splitId == null) {
      store.settleAllInto(d, row.personId!, row.amount, row.date);
    } else if (row.splitId != null && row.personId != null) {
      applyPayment(
        d,
        row.splitId!,
        row.personId!,
        row.amount,
        row.date,
        note: row.narration,
        importRef: row.ref,
      );
    } else if (row.people.isNotEmpty && !row.credit) {
      final ids = ['self', ...row.people.where((p) => p != 'self')];
      final parts = allocateSplit(
        row.amount,
        row.method,
        ids.map((id) => row.weights[id] ?? 1).toList(),
      );
      applySplit(
        d,
        BillSplit(
          id: newId(),
          title: row.title,
          total: row.amount,
          date: row.date,
          method: row.method,
          payerId: row.payerId,
          portions: Map.fromIterables(ids, parts),
          notes: row.narration,
        ),
        category: row.category,
        importRef: row.ref,
      );
    } else {
      d.entries.add(
        Entry(
          id: newId(),
          title: row.title,
          amount: row.amount,
          date: row.date,
          createdAt: DateTime.now(),
          category: row.category,
          kind: row.credit ? 'income' : 'expense',
          notes: row.narration,
          importRef: row.ref,
        ),
      );
    }
    d.activity['import:${row.ref}'] = DateTime.now().toIso8601String();
  }
  if (key != null && mapping != null) d.importMappings[key] = mapping;
});
