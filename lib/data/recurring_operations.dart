import '../core/models.dart';
import '../core/recurring.dart';
import 'garden_store.dart';

extension RecurringOperations on GardenStore {
  Future<void> saveRecurring(RecurringRule rule) => change((d) {
    d.recurring.removeWhere((r) => r.id == rule.id);
    d.recurring.add(rule);
  });
  Future<void> runRecurring([DateTime? now]) async {
    final today = now ?? DateTime.now();
    final additions = <Entry>[];
    final periods = <String, String>{};
    final ids = data.entries.map((e) => e.id).toSet();
    for (final r in data.recurring) {
      for (final date in occurrences(r, today)) {
        final key = dateKey(date);
        if (r.lastGeneratedPeriod != null &&
            key.compareTo(r.lastGeneratedPeriod!) <= 0) {
          continue;
        }
        final id = 'rec:${r.id}:$key';
        if (!ids.contains(id)) {
          additions.add(
            Entry(
              id: id,
              title: r.title,
              amount: r.amount,
              date: date,
              createdAt: today,
              category: r.category,
              kind: r.kind,
              recurringId: r.id,
            ),
          );
        }
        periods[r.id] = key;
      }
    }
    if (additions.isEmpty && periods.isEmpty) return;
    await change((d) {
      d.entries.addAll(additions);
      for (var i = 0; i < d.recurring.length; i++) {
        final r = d.recurring[i];
        if (periods.containsKey(r.id)) {
          d.recurring[i] = RecurringRule.fromJson({
            ...r.toJson(),
            'lastGeneratedPeriod': periods[r.id],
          });
        }
      }
    });
  }
}
