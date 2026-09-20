import 'dart:convert';

import 'package:uuid/uuid.dart';

String newId() => const Uuid().v4();
typedef Json = Map<String, dynamic>;

// Money is always stored as integer minor units. Never calculate with rupees.
int parseMoney(String value) {
  final input = value.trim().replaceAll(',', '');
  if (!RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(input)) {
    throw const FormatException(
      'Enter an amount with up to two decimal places.',
    );
  }
  final parts = input.split('.');
  final result =
      int.parse(parts[0]) * 100 +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  if (result <= 0) {
    throw const FormatException('Amount must be greater than zero.');
  }
  return result;
}

class Entry {
  final String id, title, category, kind, notes;
  final int amount;
  final DateTime date, createdAt;
  final String? splitId, goalId;
  const Entry({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.createdAt,
    this.category = 'Other',
    this.kind = 'expense',
    this.notes = '',
    this.splitId,
    this.goalId,
  });
  bool get incoming => kind == 'income' || kind == 'reimbursement';
  Json toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'category': category,
    'kind': kind,
    'notes': notes,
    'splitId': splitId,
    'goalId': goalId,
  };
  factory Entry.fromJson(Json j) => Entry(
    id: j['id'],
    title: j['title'],
    amount: j['amount'],
    date: DateTime.parse(j['date']),
    createdAt: DateTime.parse(j['createdAt']),
    category: j['category'],
    kind: j['kind'],
    notes: j['notes'] ?? '',
    splitId: j['splitId'],
    goalId: j['goalId'],
  );
}

class GardenTask {
  final String id, title, direction, notes;
  final DateTime date;
  final int amount;
  final bool completed;
  final String? personId;
  const GardenTask({
    required this.id,
    required this.title,
    required this.date,
    this.amount = 0,
    this.direction = 'none',
    this.completed = false,
    this.notes = '',
    this.personId,
  });
  Json toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'amount': amount,
    'direction': direction,
    'completed': completed,
    'notes': notes,
    'personId': personId,
  };
  factory GardenTask.fromJson(Json j) => GardenTask(
    id: j['id'],
    title: j['title'],
    date: DateTime.parse(j['date']),
    amount: j['amount'],
    direction: j['direction'],
    completed: j['completed'],
    notes: j['notes'] ?? '',
    personId: j['personId'],
  );
}

class Goal {
  final String id, title, icon;
  final int target;
  final DateTime date;
  const Goal({
    required this.id,
    required this.title,
    required this.target,
    required this.date,
    this.icon = '✦',
  });
  Json toJson() => {
    'id': id,
    'title': title,
    'target': target,
    'date': date.toIso8601String(),
    'icon': icon,
  };
  factory Goal.fromJson(Json j) => Goal(
    id: j['id'],
    title: j['title'],
    target: j['target'],
    date: DateTime.parse(j['date']),
    icon: j['icon'],
  );
}

class Contribution {
  final String id, goalId;
  final int amount;
  final DateTime date;
  const Contribution({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
  });
  Json toJson() => {
    'id': id,
    'goalId': goalId,
    'amount': amount,
    'date': date.toIso8601String(),
  };
  factory Contribution.fromJson(Json j) => Contribution(
    id: j['id'],
    goalId: j['goalId'],
    amount: j['amount'],
    date: DateTime.parse(j['date']),
  );
}

class Person {
  final String id, name;
  const Person({required this.id, required this.name});
  Json toJson() => {'id': id, 'name': name};
  factory Person.fromJson(Json j) => Person(id: j['id'], name: j['name']);
}

enum SplitMethod { equal, custom, percentage, shares }

class BillSplit {
  final String id, title, payerId;
  final int total;
  final DateTime date;
  final SplitMethod method;
  final Map<String, int> portions;
  const BillSplit({
    required this.id,
    required this.title,
    required this.total,
    required this.date,
    required this.method,
    required this.portions,
    this.payerId = 'self',
  });
  Json toJson() => {
    'id': id,
    'title': title,
    'total': total,
    'date': date.toIso8601String(),
    'method': method.name,
    'portions': portions,
    'payerId': payerId,
  };
  factory BillSplit.fromJson(Json j) => BillSplit(
    id: j['id'],
    title: j['title'],
    total: j['total'],
    date: DateTime.parse(j['date']),
    method: SplitMethod.values.byName(j['method']),
    portions: Map<String, int>.from(j['portions']),
    payerId: j['payerId'],
  );
}

class Payment {
  final String id, splitId, personId;
  final int amount;
  final DateTime date;
  const Payment({
    required this.id,
    required this.splitId,
    required this.personId,
    required this.amount,
    required this.date,
  });
  Json toJson() => {
    'id': id,
    'splitId': splitId,
    'personId': personId,
    'amount': amount,
    'date': date.toIso8601String(),
  };
  factory Payment.fromJson(Json j) => Payment(
    id: j['id'],
    splitId: j['splitId'],
    personId: j['personId'],
    amount: j['amount'],
    date: DateTime.parse(j['date']),
  );
}

// Largest-remainder allocation preserves the exact total, including 100 / 3.
List<int> allocateSplit(int total, SplitMethod method, List<int> weights) {
  if (total <= 0 || weights.length < 2 || weights.any((v) => v < 0)) {
    throw const FormatException(
      'Add at least two people and a positive total.',
    );
  }
  if (method == SplitMethod.custom) {
    if (weights.fold(0, (a, b) => a + b) != total) {
      throw const FormatException('Custom amounts must add up to the bill.');
    }
    return List.of(weights);
  }
  final values = method == SplitMethod.equal
      ? List.filled(weights.length, 1)
      : weights;
  final sum = values.fold(0, (a, b) => a + b);
  if (sum <= 0 || (method == SplitMethod.percentage && sum != 10000)) {
    throw const FormatException(
      'Percentages must total 100%; shares must be positive.',
    );
  }
  final result = values.map((v) => total * v ~/ sum).toList();
  final order = List.generate(values.length, (i) => i)
    ..sort((a, b) {
      final diff = (total * values[b] % sum).compareTo(total * values[a] % sum);
      return diff == 0 ? a.compareTo(b) : diff;
    });
  final remainder = total - result.fold(0, (a, b) => a + b);
  for (var i = 0; i < remainder; i++) {
    result[order[i]]++;
  }
  return result;
}

class GardenData {
  final List<Entry> entries;
  final List<GardenTask> tasks;
  final List<Goal> goals;
  final List<Contribution> contributions;
  final List<Person> people;
  final List<BillSplit> splits;
  final List<Payment> payments;
  final Map<String, String> activity;
  String theme, currency;
  GardenData({
    List<Entry>? entries,
    List<GardenTask>? tasks,
    List<Goal>? goals,
    List<Contribution>? contributions,
    List<Person>? people,
    List<BillSplit>? splits,
    List<Payment>? payments,
    Map<String, String>? activity,
    this.theme = 'light',
    this.currency = 'INR',
  }) : entries = entries ?? [],
       tasks = tasks ?? [],
       goals = goals ?? [],
       contributions = contributions ?? [],
       people = people ?? [],
       splits = splits ?? [],
       payments = payments ?? [],
       activity = activity ?? {};
  Json toJson() => {
    'schemaVersion': 1,
    'entries': entries.map((x) => x.toJson()).toList(),
    'tasks': tasks.map((x) => x.toJson()).toList(),
    'goals': goals.map((x) => x.toJson()).toList(),
    'contributions': contributions.map((x) => x.toJson()).toList(),
    'people': people.map((x) => x.toJson()).toList(),
    'splits': splits.map((x) => x.toJson()).toList(),
    'payments': payments.map((x) => x.toJson()).toList(),
    'activity': activity,
    'theme': theme,
    'currency': currency,
  };
  String encode() => jsonEncode(toJson());
  void validate() {
    void require(bool condition) {
      if (!condition) {
        throw const FormatException(
          'This backup contains invalid or inconsistent data.',
        );
      }
    }

    require(
      ['light', 'dark', 'system'].contains(theme) &&
          ['INR', 'USD', 'EUR'].contains(currency),
    );
    for (final ids in [
      entries.map((e) => e.id),
      tasks.map((e) => e.id),
      goals.map((e) => e.id),
      people.map((e) => e.id),
      splits.map((e) => e.id),
      payments.map((e) => e.id),
      contributions.map((e) => e.id),
    ]) {
      require(
        ids.every((id) => id.isNotEmpty) && ids.toSet().length == ids.length,
      );
    }
    for (final e in entries) {
      require(
        e.amount > 0 &&
            e.title.trim().isNotEmpty &&
            [
              'expense',
              'income',
              'reimbursement',
              'settlement',
            ].contains(e.kind),
      );
    }
    for (final p in people) {
      require(p.id != 'self' && p.name.trim().isNotEmpty);
    }
    for (final g in goals) {
      require(g.target > 0 && g.title.trim().isNotEmpty);
    }
    for (final c in contributions) {
      require(c.amount > 0 && goals.any((g) => g.id == c.goalId));
    }
    for (final t in tasks) {
      require(
        t.title.trim().isNotEmpty &&
            t.amount >= 0 &&
            [
              'none',
              'lend',
              'borrow',
              'repay',
              'collect',
            ].contains(t.direction),
      );
    }
    for (final s in splits) {
      require(
        s.total > 0 &&
            s.title.trim().isNotEmpty &&
            s.portions.length >= 2 &&
            s.portions.containsKey('self') &&
            s.portions.containsKey(s.payerId),
      );
      require(
        s.portions.values.every((a) => a >= 0) &&
            s.portions.values.fold(0, (a, b) => a + b) == s.total,
      );
      require(
        s.portions.keys.every(
          (id) => id == 'self' || people.any((p) => p.id == id),
        ),
      );
      for (final person in s.portions.keys) {
        final paid = payments
            .where((p) => p.splitId == s.id && p.personId == person)
            .fold(0, (a, p) => a + p.amount);
        require(paid <= s.portions[person]!);
      }
    }
    for (final p in payments) {
      require(
        p.amount > 0 &&
            splits.any(
              (s) =>
                  s.id == p.splitId &&
                  s.portions.containsKey(p.personId) &&
                  s.payerId != p.personId,
            ),
      );
    }
    for (final date in activity.values) {
      DateTime.parse(date);
    }
  }

  factory GardenData.decode(String raw) {
    final j = jsonDecode(raw) as Json;
    if (j['schemaVersion'] != 1) {
      throw const FormatException('Unsupported backup version.');
    }
    List<T> read<T>(String key, T Function(Json) fn) =>
        (j[key] as List).map((x) => fn(Map<String, dynamic>.from(x))).toList();
    return GardenData(
      entries: read('entries', Entry.fromJson),
      tasks: read('tasks', GardenTask.fromJson),
      goals: read('goals', Goal.fromJson),
      contributions: read('contributions', Contribution.fromJson),
      people: read('people', Person.fromJson),
      splits: read('splits', BillSplit.fromJson),
      payments: read('payments', Payment.fromJson),
      activity: Map<String, String>.from(j['activity']),
      theme: j['theme'],
      currency: j['currency'],
    );
  }
}
