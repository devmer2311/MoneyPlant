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
  final String? splitId, goalId, importRef, recurringId, paymentId;
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
    this.importRef,
    this.recurringId,
    this.paymentId,
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
    'importRef': importRef,
    'recurringId': recurringId,
    'paymentId': paymentId,
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
    importRef: j['importRef'],
    recurringId: j['recurringId'],
    paymentId: j['paymentId'],
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
  final String id, title, payerId, notes;
  final String? groupId;
  final List<SplitItem> items;
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
    this.groupId,
    this.items = const [],
    this.notes = '',
  });
  Json toJson() => {
    'id': id,
    'title': title,
    'total': total,
    'date': date.toIso8601String(),
    'method': method.name,
    'portions': portions,
    'payerId': payerId,
    'groupId': groupId,
    'items': items.map((x) => x.toJson()).toList(),
    'notes': notes,
  };
  factory BillSplit.fromJson(Json j) => BillSplit(
    id: j['id'],
    title: j['title'],
    total: j['total'],
    date: DateTime.parse(j['date']),
    method: SplitMethod.values.byName(j['method']),
    portions: Map<String, int>.from(j['portions']),
    payerId: j['payerId'],
    groupId: j['groupId'],
    items: (j['items'] as List? ?? [])
        .map((x) => SplitItem.fromJson(Map<String, dynamic>.from(x)))
        .toList(),
    notes: j['notes'] ?? '',
  );
}

class Payment {
  final String id, splitId, personId, note;
  final int amount;
  final DateTime date;
  const Payment({
    required this.id,
    required this.splitId,
    required this.personId,
    required this.amount,
    required this.date,
    this.note = '',
  });
  Json toJson() => {
    'note': note,
    'id': id,
    'splitId': splitId,
    'personId': personId,
    'amount': amount,
    'date': date.toIso8601String(),
  };
  factory Payment.fromJson(Json j) => Payment(
    note: j['note'] ?? '',
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

class Profile {
  final String displayName;
  final String upiId;
  final String payeeName;
  final bool includeQr;
  final bool includeUpiLink;
  const Profile({
    this.displayName = '',
    this.upiId = '',
    this.payeeName = '',
    this.includeQr = true,
    this.includeUpiLink = true,
  });
  Json toJson() => {
    'displayName': displayName,
    'upiId': upiId,
    'payeeName': payeeName,
    'includeQr': includeQr,
    'includeUpiLink': includeUpiLink,
  };
  factory Profile.fromJson(Json j) => Profile(
    displayName: j['displayName'] ?? '',
    upiId: j['upiId'] ?? '',
    payeeName: j['payeeName'] ?? '',
    includeQr: j['includeQr'] ?? true,
    includeUpiLink: j['includeUpiLink'] ?? true,
  );
}

class Group {
  final String id;
  final String name;
  final String emoji;
  final List<String> memberIds;
  final DateTime createdAt;
  final bool archived;
  const Group({
    required this.id,
    required this.name,
    this.emoji = '🌱',
    required this.memberIds,
    required this.createdAt,
    this.archived = false,
  });
  Json toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'memberIds': memberIds,
    'createdAt': createdAt.toIso8601String(),
    'archived': archived,
  };
  factory Group.fromJson(Json j) => Group(
    id: j['id'],
    name: j['name'],
    emoji: j['emoji'] ?? '🌱',
    memberIds: List<String>.from(j['memberIds']),
    createdAt: DateTime.parse(j['createdAt']),
    archived: j['archived'] ?? false,
  );
}

class GroupSettlement {
  final String id;
  final String groupId;
  final String fromId;
  final String toId;
  final int amount;
  final DateTime date;
  final String note;
  const GroupSettlement({
    required this.id,
    required this.groupId,
    required this.fromId,
    required this.toId,
    required this.amount,
    required this.date,
    this.note = '',
  });
  Json toJson() => {
    'id': id,
    'groupId': groupId,
    'fromId': fromId,
    'toId': toId,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
  };
  factory GroupSettlement.fromJson(Json j) => GroupSettlement(
    id: j['id'],
    groupId: j['groupId'],
    fromId: j['fromId'],
    toId: j['toId'],
    amount: j['amount'],
    date: DateTime.parse(j['date']),
    note: j['note'] ?? '',
  );
}

class SplitItem {
  final String name;
  final int amount;
  final List<String> personIds;
  final String kind;
  const SplitItem({
    required this.name,
    required this.amount,
    this.personIds = const [],
    this.kind = 'item',
  });
  Json toJson() => {
    'name': name,
    'amount': amount,
    'personIds': personIds,
    'kind': kind,
  };
  factory SplitItem.fromJson(Json j) => SplitItem(
    name: j['name'],
    amount: j['amount'],
    personIds: List<String>.from(j['personIds'] ?? []),
    kind: j['kind'] ?? 'item',
  );
}

class RecurringRule {
  final String id;
  final String title;
  final int amount;
  final String category;
  final String kind;
  final String frequency;
  final int? dayOfMonth;
  final int? weekday;
  final DateTime startDate;
  final DateTime? endDate;
  final bool paused;
  final String? lastGeneratedPeriod;
  const RecurringRule({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.kind = 'expense',
    this.frequency = 'monthly',
    this.dayOfMonth,
    this.weekday,
    required this.startDate,
    this.endDate,
    this.paused = false,
    this.lastGeneratedPeriod,
  });
  Json toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category,
    'kind': kind,
    'frequency': frequency,
    'dayOfMonth': dayOfMonth,
    'weekday': weekday,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'paused': paused,
    'lastGeneratedPeriod': lastGeneratedPeriod,
  };
  factory RecurringRule.fromJson(Json j) => RecurringRule(
    id: j['id'],
    title: j['title'],
    amount: j['amount'],
    category: j['category'],
    kind: j['kind'] ?? 'expense',
    frequency: j['frequency'] ?? 'monthly',
    dayOfMonth: j['dayOfMonth'],
    weekday: j['weekday'],
    startDate: DateTime.parse(j['startDate']),
    endDate: j['endDate'] == null ? null : DateTime.parse(j['endDate']),
    paused: j['paused'] ?? false,
    lastGeneratedPeriod: j['lastGeneratedPeriod'],
  );
}

class ColumnMapping {
  final int date;
  final int description;
  final int? debit;
  final int? credit;
  final int? amount;
  final int? type;
  final int? reference;
  final Map<String, String> categoryRules;
  const ColumnMapping({
    required this.date,
    required this.description,
    this.debit,
    this.credit,
    this.amount,
    this.type,
    this.reference,
    this.categoryRules = const {},
  });
  Json toJson() => {
    'date': date,
    'description': description,
    'debit': debit,
    'credit': credit,
    'amount': amount,
    'type': type,
    'reference': reference,
    'categoryRules': categoryRules,
  };
  factory ColumnMapping.fromJson(Json j) => ColumnMapping(
    date: j['date'],
    description: j['description'],
    debit: j['debit'],
    credit: j['credit'],
    amount: j['amount'],
    type: j['type'],
    reference: j['reference'],
    categoryRules: Map<String, String>.from(j['categoryRules'] ?? {}),
  );
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
  static const themePackIds = ['garden', 'sakura', 'neon', 'mango', 'ocean'];
  String theme, currency, themePack;
  Profile profile;
  final List<Group> groups;
  final List<GroupSettlement> groupSettlements;
  final List<RecurringRule> recurring;
  final Map<String, int> budgets;
  final Map<String, ColumnMapping> importMappings;
  bool appLock;
  GardenData({
    List<Entry>? entries,
    List<GardenTask>? tasks,
    List<Goal>? goals,
    List<Contribution>? contributions,
    List<Person>? people,
    List<BillSplit>? splits,
    List<Payment>? payments,
    Map<String, String>? activity,
    this.themePack = 'garden',
    this.profile = const Profile(),
    this.appLock = false,
    List<Group>? groups,
    List<GroupSettlement>? groupSettlements,
    List<RecurringRule>? recurring,
    Map<String, int>? budgets,
    Map<String, ColumnMapping>? importMappings,
    this.theme = 'light',
    this.currency = 'INR',
  }) : entries = entries ?? [],
       tasks = tasks ?? [],
       goals = goals ?? [],
       contributions = contributions ?? [],
       people = people ?? [],
       splits = splits ?? [],
       payments = payments ?? [],
       activity = activity ?? {},
       groups = groups ?? [],
       groupSettlements = groupSettlements ?? [],
       recurring = recurring ?? [],
       budgets = budgets ?? {},
       importMappings = importMappings ?? {};
  Json toJson() => {
    'schemaVersion': 2,
    'themePack': themePack,
    'profile': profile.toJson(),
    'appLock': appLock,
    'groups': groups.map((x) => x.toJson()).toList(),
    'groupSettlements': groupSettlements.map((x) => x.toJson()).toList(),
    'recurring': recurring.map((x) => x.toJson()).toList(),
    'budgets': budgets,
    'importMappings': importMappings.map((k, v) => MapEntry(k, v.toJson())),
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
      groups.map((e) => e.id),
      groupSettlements.map((e) => e.id),
      recurring.map((e) => e.id),
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
    require(
      people.map((p) => p.name.trim().toLowerCase()).toSet().length ==
          people.length,
    );
    for (final p in people) {
      require(
        p.id != 'self' &&
            p.name.trim().isNotEmpty &&
            p.name.trim().toLowerCase() != 'you',
      );
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
    require(themePackIds.contains(themePack));
    require(
      profile.upiId.isEmpty ||
          RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z][a-zA-Z0-9]{1,63}$')
              .hasMatch(profile.upiId),
    );
    bool member(String id) => id == 'self' || people.any((p) => p.id == id);
    for (final task in tasks) {
      require(task.personId == null || member(task.personId!));
    }
    for (final entry in entries) {
      require(entry.importRef == null || entry.importRef!.trim().isNotEmpty);
      // Recurring references are provenance: deleting a rule keeps its entries.
      require(
        entry.recurringId == null || entry.recurringId!.trim().isNotEmpty,
      );
      require(
        entry.paymentId == null ||
            payments.any(
              (p) =>
                  p.id == entry.paymentId &&
                  p.splitId == entry.splitId &&
                  p.amount == entry.amount,
            ),
      );
    }
    final paymentLinks = entries
        .map((e) => e.paymentId)
        .whereType<String>()
        .toList();
    require(paymentLinks.toSet().length == paymentLinks.length);
    for (final group in groups) {
      require(
        group.name.trim().isNotEmpty &&
            group.emoji.trim().isNotEmpty &&
            group.memberIds.length >= 2,
      );
      require(
        group.memberIds.toSet().length == group.memberIds.length &&
            group.memberIds.every(member),
      );
    }
    for (final split in splits) {
      require(
        split.groupId == null ||
            groups.any(
              (g) =>
                  g.id == split.groupId &&
                  split.portions.keys.every(g.memberIds.contains),
            ),
      );
      if (split.items.isNotEmpty) {
        require(
          split.items.fold(
                0,
                (sum, item) =>
                    sum +
                    (item.kind == 'discount' ? -item.amount : item.amount),
              ) ==
              split.total,
        );
        for (final item in split.items) {
          require(
            item.name.trim().isNotEmpty &&
                item.amount > 0 &&
                ['item', 'tax', 'tip', 'discount'].contains(item.kind),
          );
          require(
            item.personIds.toSet().length == item.personIds.length &&
                item.personIds.every(split.portions.containsKey),
          );
          require(item.kind != 'item' || item.personIds.isNotEmpty);
        }
      }
    }
    for (final settlement in groupSettlements) {
      require(settlement.amount > 0 && settlement.fromId != settlement.toId);
      require(
        groups.any(
          (g) =>
              g.id == settlement.groupId &&
              g.memberIds.contains(settlement.fromId) &&
              g.memberIds.contains(settlement.toId),
        ),
      );
    }
    for (final rule in recurring) {
      require(
        rule.title.trim().isNotEmpty &&
            rule.amount > 0 &&
            rule.category.trim().isNotEmpty,
      );
      require(
        ['expense', 'income'].contains(rule.kind) &&
            ['weekly', 'monthly', 'yearly'].contains(rule.frequency),
      );
      require(rule.endDate == null || !rule.endDate!.isBefore(rule.startDate));
      require(
        rule.weekday == null || (rule.weekday! >= 1 && rule.weekday! <= 7),
      );
      require(
        rule.dayOfMonth == null ||
            (rule.dayOfMonth! >= 1 && rule.dayOfMonth! <= 31),
      );
      require(
        rule.lastGeneratedPeriod == null ||
            RegExp(r'^\d{4}(-\d{2}(-\d{2})?)?$')
                .hasMatch(rule.lastGeneratedPeriod!),
      );
    }
    for (final budget in budgets.entries) {
      require(budget.key.trim().isNotEmpty && budget.value > 0);
    }
    for (final mapping in importMappings.entries) {
      final value = mapping.value;
      require(mapping.key.trim().isNotEmpty);
      final columns = [
        value.date,
        value.description,
        value.debit,
        value.credit,
        value.amount,
        value.type,
        value.reference,
      ].whereType<int>().toList();
      require(
        columns.every((v) => v >= 0) &&
            columns.toSet().length == columns.length,
      );
      require(
        (value.amount != null && value.type != null) ||
            value.debit != null ||
            value.credit != null,
      );
      require(
        value.categoryRules.entries.every(
          (e) => e.key.trim().isNotEmpty && e.value.trim().isNotEmpty,
        ),
      );
    }
    for (final date in activity.values) {
      DateTime.parse(date);
    }
  }

  factory GardenData.decode(String raw) {
    try {
      return GardenData._decode(raw);
    } on FormatException catch (error) {
      if (error.message == 'Unsupported backup version.') rethrow;
      throw const FormatException(
        'This backup contains invalid or inconsistent data.',
      );
    } on Object {
      throw const FormatException(
        'This backup contains invalid or inconsistent data.',
      );
    }
  }

  factory GardenData._decode(String raw) {
    final j = jsonDecode(raw) as Json;
    if (![1, 2].contains(j['schemaVersion'])) {
      throw const FormatException('Unsupported backup version.');
    }
    List<T> read<T>(String key, T Function(Json) fn) =>
        (j[key] as List).map((x) => fn(Map<String, dynamic>.from(x))).toList();
    if (j['themePack'] != null && j['themePack'] is! String) {
      throw const FormatException(
        'This backup contains invalid or inconsistent data.',
      );
    }
    final data = GardenData(
      themePack: themePackIds.contains(j['themePack'])
          ? j['themePack']
          : 'garden',
      profile: Profile.fromJson(Map<String, dynamic>.from(j['profile'] ?? {})),
      appLock: j['appLock'] ?? false,
      groups: j['groups'] == null ? [] : read('groups', Group.fromJson),
      groupSettlements: j['groupSettlements'] == null
          ? []
          : read('groupSettlements', GroupSettlement.fromJson),
      recurring: j['recurring'] == null
          ? []
          : read('recurring', RecurringRule.fromJson),
      budgets: Map<String, int>.from(j['budgets'] ?? {}),
      importMappings: (j['importMappings'] as Map? ?? {}).map(
        (k, v) => MapEntry(
          k as String,
          ColumnMapping.fromJson(Map<String, dynamic>.from(v)),
        ),
      ),
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
    data.validate();
    return data;
  }
}
