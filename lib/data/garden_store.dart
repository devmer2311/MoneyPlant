import 'garden_operations.dart';
export 'garden_operations.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models.dart';

abstract class GardenRepository {
  Future<String?> read();
  Future<void> write(String value);
}

class LocalGardenRepository implements GardenRepository {
  final SharedPreferencesAsync preferences = SharedPreferencesAsync();
  @override
  Future<String?> read() => preferences.getString('money_plant.garden.v1');
  @override
  Future<void> write(String value) =>
      preferences.setString('money_plant.garden.v1', value);
}

final gardenProvider = ChangeNotifierProvider<GardenStore>(
  (ref) => throw StateError('Initialize the garden before opening the app.'),
);

class GardenStore extends ChangeNotifier {
  final GardenRepository repository;
  GardenData _data = GardenData();
  GardenData get data => _data;
  bool _saving = false;
  GardenStore(this.repository);
  Future<void> load() async {
    final raw = await repository.read();
    if (raw != null) {
      final loaded = GardenData.decode(raw);
      loaded.validate();
      _data = loaded;
    }
    notifyListeners();
  }

  // Commit one complete snapshot, then publish. Failed writes never change UI state.
  Future<void> change(void Function(GardenData) apply) async {
    if (_saving) throw StateError('A save is in progress. Please try again.');
    _saving = true;
    try {
      final next = GardenData.decode(_data.encode());
      apply(next);
      next.validate();
      await repository.write(next.encode());
      _data = next;
      notifyListeners();
    } finally {
      _saving = false;
    }
  }

  Future<void> restore(String raw) async {
    if (_saving) throw StateError('A save is in progress.');
    final restored = GardenData.decode(raw);
    restored.validate();
    _saving = true;
    try {
      await repository.write(restored.encode());
      _data = restored;
      notifyListeners();
    } finally {
      _saving = false;
    }
  }

  void activity(GardenData d, String key) =>
      d.activity.putIfAbsent(key, () => DateTime.now().toIso8601String());
  Future<void> saveEntry(Entry entry) => change((d) {
    if (entry.amount <= 0 || entry.title.trim().isEmpty) {
      throw const FormatException('Add a title and positive amount.');
    }
    d.entries.removeWhere((e) => e.id == entry.id);
    d.entries.add(entry);
    activity(d, 'entry:${entry.id}');
  });
  Future<void> removeEntry(String id) => change((d) {
    final e = d.entries.firstWhere((x) => x.id == id);
    if (e.splitId != null || e.goalId != null || e.id.startsWith('group:')) {
      throw const FormatException(
        'Manage this linked entry from its split or goal.',
      );
    }
    d.entries.removeWhere((x) => x.id == id);
  });
  Future<void> saveTask(GardenTask task) => change((d) {
    d.tasks.removeWhere((x) => x.id == task.id);
    d.tasks.add(task);
  });
  Future<void> completeTask(String id, {bool record = false}) => change((d) {
    final index = d.tasks.indexWhere((x) => x.id == id);
    final task = d.tasks[index];
    if (task.completed) return;
    d.tasks[index] = GardenTask.fromJson({...task.toJson(), 'completed': true});
    if (record && task.amount > 0 && task.direction != 'none') {
      d.entries.add(
        Entry(
          id: newId(),
          title: task.title,
          amount: task.amount,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          category: 'Personal',
          kind: ['collect', 'borrow'].contains(task.direction)
              ? 'income'
              : 'expense',
        ),
      );
    }
    activity(d, 'task:$id');
  });
  Future<void> saveGoal(Goal goal) => change((d) {
    d.goals.removeWhere((x) => x.id == goal.id);
    d.goals.add(goal);
  });
  int progress(String id) => data.contributions
      .where((x) => x.goalId == id)
      .fold(0, (a, b) => a + b.amount);
  Future<void> contribute(String goalId, int amount, {bool record = false}) =>
      change((d) {
        if (amount <= 0) {
          throw const FormatException('Enter a positive contribution.');
        }
        final goal = d.goals.firstWhere((g) => g.id == goalId);
        d.contributions.add(
          Contribution(
            id: newId(),
            goalId: goalId,
            amount: amount,
            date: DateTime.now(),
          ),
        );
        if (record) {
          d.entries.add(
            Entry(
              id: newId(),
              title: goal.title,
              amount: amount,
              date: DateTime.now(),
              createdAt: DateTime.now(),
              category: 'Savings',
              goalId: goalId,
            ),
          );
        }
        if (d.contributions
                .where((c) => c.goalId == goalId)
                .fold(0, (a, c) => a + c.amount) >=
            goal.target) {
          activity(d, 'goal:$goalId');
        }
      });
  String personName(String id) => id == 'self'
      ? 'You'
      : data.people.where((p) => p.id == id).firstOrNull?.name ??
            'Unknown person';
  Future<void> saveSplit(
    BillSplit split,
    List<Person> people, {
    String category = 'Food',
    String notes = '',
  }) => change((d) {
    if (split.total <= 0 ||
        split.portions.length < 2 ||
        !split.portions.containsKey('self') ||
        !split.portions.containsKey(split.payerId) ||
        split.portions.values.any((v) => v < 0) ||
        split.portions.values.fold(0, (a, b) => a + b) != split.total) {
      throw const FormatException('The shares must add up to the bill.');
    }
    if (d.splits.any((s) => s.id == split.id)) {
      throw StateError('This split is already saved.');
    }
    for (final person in people) {
      if (!d.people.any((p) => p.id == person.id)) d.people.add(person);
    }
    d.splits.add(split);
    if (split.payerId == 'self') {
      d.entries.add(
        Entry(
          id: newId(),
          title: split.title,
          amount: split.total,
          date: split.date,
          createdAt: DateTime.now(),
          category: category,
          notes: notes,
          splitId: split.id,
        ),
      );
    }
    activity(d, 'entry:${split.id}');
  });
  int paid(BillSplit split, String person) => data.payments
      .where((p) => p.splitId == split.id && p.personId == person)
      .fold(0, (a, b) => a + b.amount);
  int remaining(BillSplit split, String person) => person == split.payerId
      ? 0
      : (split.portions[person] ?? 0) - paid(split, person);
  int get receivable => data.people
      .map((p) => personNet(p.id))
      .where((v) => v > 0)
      .fold(0, (a, b) => a + b);
  int get owed => -data.people
      .map((p) => personNet(p.id))
      .where((v) => v < 0)
      .fold(0, (a, b) => a + b);
  Future<void> recordPayment(
    String splitId,
    String person,
    int amount,
    DateTime date,
  ) => change((d) => applyPayment(d, splitId, person, amount, date));
  List<Entry> get posted =>
      data.entries.where((e) => !e.date.isAfter(DateTime.now())).toList();
  int get balance =>
      posted.fold(0, (a, e) => a + (e.incoming ? e.amount : -e.amount));
  int monthTotal(bool income, DateTime month) => posted
      .where(
        (e) =>
            e.date.year == month.year &&
            e.date.month == month.month &&
            (income ? e.kind == 'income' : e.kind == 'expense'),
      )
      .fold(0, (a, e) => a + e.amount);
  int get xp => data.activity.keys.fold(
    0,
    (a, key) =>
        a +
        (key.startsWith('goal:')
            ? 100
            : key.startsWith('entry:')
            ? 5
            : 10),
  );
  int streak([DateTime? now]) {
    final today = now ?? DateTime.now();
    var day = DateTime(today.year, today.month, today.day);
    final dates = data.activity.values.map((s) {
      final d = DateTime.parse(s);
      return DateTime(d.year, d.month, d.day);
    }).toSet();
    if (!dates.contains(day)) day = DateTime(day.year, day.month, day.day - 1);
    var count = 0;
    while (dates.contains(day)) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  int get stage => (xp ~/ 100).clamp(0, 5);
  String get stageName => [
    'Seed',
    'Sprout',
    'Young plant',
    'Healthy plant',
    'Blooming plant',
    'Money tree',
  ][stage];
}
