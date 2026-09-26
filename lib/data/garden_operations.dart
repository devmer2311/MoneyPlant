import '../core/models.dart';
import '../core/settle.dart';
import 'garden_store.dart';

void applyPayment(
  GardenData d,
  String splitId,
  String person,
  int amount,
  DateTime date, {
  String note = '',
  String? importRef,
}) {
  final split = d.splits.firstWhere((s) => s.id == splitId);
  final paid = d.payments
      .where((p) => p.splitId == splitId && p.personId == person)
      .fold(0, (a, p) => a + p.amount);
  if (person == split.payerId ||
      !split.portions.containsKey(person) ||
      amount <= 0 ||
      amount > split.portions[person]! - paid) {
    throw const FormatException(
      'Payment must be within the outstanding amount.',
    );
  }
  final id = newId();
  d.payments.add(
    Payment(
      id: id,
      splitId: splitId,
      personId: person,
      amount: amount,
      date: date,
      note: note,
    ),
  );
  if (person == 'self' || split.payerId == 'self') {
    d.entries.add(
      Entry(
        id: newId(),
        title: split.title,
        amount: amount,
        date: date,
        createdAt: DateTime.now(),
        kind: split.payerId == 'self' ? 'reimbursement' : 'settlement',
        category: 'Settlement',
        splitId: splitId,
        paymentId: id,
        notes: note,
        importRef: importRef,
      ),
    );
  }
}

void applySplit(
  GardenData d,
  BillSplit split, {
  String category = 'Food',
  String? importRef,
}) {
  if (d.splits.any((s) => s.id == split.id)) {
    throw const FormatException('This split is already saved.');
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
        notes: split.notes,
        splitId: split.id,
        importRef: importRef,
      ),
    );
  }
}

extension GardenOperations on GardenStore {
  int taskNet(String person) => data.tasks
      .where((t) => t.personId == person && !t.completed)
      .fold(
        0,
        (a, t) =>
            a +
            (['lend', 'collect'].contains(t.direction)
                ? t.amount
                : ['borrow', 'repay'].contains(t.direction)
                ? -t.amount
                : 0),
      );
  int personNet(String person) => _personNet(data, person);
  Future<void> updateSplit(
    BillSplit next,
    List<Person> people, {
    String category = 'Food',
    String notes = '',
  }) => change((d) {
    final old = d.splits.firstWhere((s) => s.id == next.id);
    final payments = d.payments.where((p) => p.splitId == next.id).toList();
    if (payments.isNotEmpty && next.payerId != old.payerId) {
      throw const FormatException(
        'Remove existing payments before changing who paid.',
      );
    }
    for (final id in old.portions.keys) {
      final paid = payments
          .where((p) => p.personId == id)
          .fold(0, (a, p) => a + p.amount);
      if ((next.portions[id] ?? 0) < paid) {
        throw FormatException(
          '${personName(id)} has already paid more than this share.',
        );
      }
    }
    for (final person in people) {
      if (!d.people.any((p) => p.id == person.id)) d.people.add(person);
    }
    d.splits[d.splits.indexOf(old)] = next;
    final linked = d.entries
        .where((e) => e.splitId == next.id && e.kind == 'expense')
        .firstOrNull;
    d.entries.removeWhere((e) => e.splitId == next.id && e.kind == 'expense');
    if (next.payerId == 'self') {
      d.entries.add(
        Entry(
          id: linked?.id ?? newId(),
          title: next.title,
          amount: next.total,
          date: next.date,
          createdAt: linked?.createdAt ?? DateTime.now(),
          category: category,
          notes: notes,
          splitId: next.id,
          importRef: linked?.importRef,
        ),
      );
    }
  });
  Future<void> deleteSplit(String id) => change((d) {
    d.splits.removeWhere((s) => s.id == id);
    d.payments.removeWhere((p) => p.splitId == id);
    d.entries.removeWhere((e) => e.splitId == id);
  });
  Future<void> removePayment(String id) => change((d) {
    final p = d.payments.firstWhere((p) => p.id == id);
    final links = d.entries.where((e) => e.paymentId == id).toList();
    if (links.isEmpty) {
      final legacy = d.entries
          .where(
            (e) =>
                e.paymentId == null &&
                e.splitId == p.splitId &&
                e.amount == p.amount &&
                e.date == p.date &&
                ['reimbursement', 'settlement'].contains(e.kind),
          )
          .toList();
      if (legacy.length > 1) {
        throw const FormatException(
          'This older payment has ambiguous ledger links. Restore or edit the split instead.',
        );
      }
      if (legacy.isNotEmpty) d.entries.remove(legacy.single);
    }
    d.entries.removeWhere((e) => e.paymentId == id);
    d.payments.remove(p);
  });
  Future<void> renamePerson(String id, String name) => change((d) {
    name = name.trim();
    if (name.isEmpty ||
        name.toLowerCase() == 'you' ||
        d.people.any(
          (p) => p.id != id && p.name.toLowerCase() == name.toLowerCase(),
        )) {
      throw const FormatException('Use a unique name other than You.');
    }
    final i = d.people.indexWhere((p) => p.id == id);
    d.people[i] = Person(id: id, name: name);
  });
  Future<void> deletePerson(String id) => change((d) {
    if (d.splits.any((s) => s.portions.containsKey(id)) ||
        d.tasks.any((t) => t.personId == id) ||
        d.groups.any((g) => g.memberIds.contains(id))) {
      throw const FormatException(
        'This person has history. Merge them instead.',
      );
    }
    d.people.removeWhere((p) => p.id == id);
  });
  Future<void> mergePeople(String from, String to) => change((d) {
    if (from == to ||
        !d.people.any((p) => p.id == from) ||
        !d.people.any((p) => p.id == to)) {
      throw const FormatException('Choose two different people.');
    }
    String rewrite(String id) => id == from ? to : id;
    for (var i = 0; i < d.splits.length; i++) {
      final s = d.splits[i];
      final portions = <String, int>{};
      for (final p in s.portions.entries) {
        portions.update(
          rewrite(p.key),
          (v) => v + p.value,
          ifAbsent: () => p.value,
        );
      }
      d.splits[i] = BillSplit.fromJson({
        ...s.toJson(),
        'payerId': rewrite(s.payerId),
        'portions': portions,
        'items': s.items
            .map(
              (item) => {
                ...item.toJson(),
                'personIds': item.personIds.map(rewrite).toSet().toList(),
              },
            )
            .toList(),
      });
    }
    for (var i = 0; i < d.payments.length; i++) {
      final p = d.payments[i];
      d.payments[i] = Payment.fromJson({
        ...p.toJson(),
        'personId': rewrite(p.personId),
      });
    }
    final internal = d.payments
        .where(
          (p) =>
              d.splits.any((s) => s.id == p.splitId && s.payerId == p.personId),
        )
        .map((p) => p.id)
        .toSet();
    d.payments.removeWhere((p) => internal.contains(p.id));
    d.entries.removeWhere((e) => internal.contains(e.paymentId));
    for (var i = 0; i < d.tasks.length; i++) {
      final t = d.tasks[i];
      if (t.personId == from) {
        d.tasks[i] = GardenTask.fromJson({...t.toJson(), 'personId': to});
      }
    }
    for (var i = 0; i < d.groups.length; i++) {
      final g = d.groups[i];
      d.groups[i] = Group.fromJson({
        ...g.toJson(),
        'memberIds': g.memberIds.map(rewrite).toSet().toList(),
      });
    }
    for (var i = 0; i < d.groupSettlements.length; i++) {
      final p = d.groupSettlements[i];
      d.groupSettlements[i] = GroupSettlement.fromJson({
        ...p.toJson(),
        'fromId': rewrite(p.fromId),
        'toId': rewrite(p.toId),
      });
    }
    d.groupSettlements.removeWhere((p) => p.fromId == p.toId);
    d.people.removeWhere((p) => p.id == from);
  });
  Future<void> settleAll(String person, int amount, DateTime date) =>
      change((d) => settleAllInto(d, person, amount, date));
  void settleAllInto(GardenData d, String person, int amount, DateTime date) {
    final net = _personNet(d, person);
    if (amount < 0 || amount > net.abs()) {
      throw const FormatException('Amount exceeds the net balance.');
    }
    final full = amount == net.abs();
    var left = amount;
    int take(int due, bool incoming) {
      if (full) return due;
      if (incoming != (net > 0)) return 0;
      final pay = left < due ? left : due;
      left -= pay;
      return pay;
    }

    final splits = d.splits.where((s) => s.groupId == null).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    for (final split in splits) {
      final debtor = split.payerId == 'self'
          ? person
          : split.payerId == person
          ? 'self'
          : null;
      if (debtor == null) continue;
      final pay = take(_remaining(d, split, debtor), debtor == person);
      if (pay > 0) {
        applyPayment(d, split.id, debtor, pay, date, note: 'Settle all');
      }
    }
    for (final group in d.groups) {
      for (final transfer in simplifyDebts(_groupBalances(d, group.id))) {
        final incoming = transfer.fromId == person && transfer.toId == 'self';
        final outgoing = transfer.fromId == 'self' && transfer.toId == person;
        if (!incoming && !outgoing) continue;
        final pay = take(transfer.amount, incoming);
        if (pay > 0) {
          applyGroupPayment(
            d,
            group.id,
            Transfer(transfer.fromId, transfer.toId, pay),
            date,
          );
        }
      }
    }
    for (var i = 0; i < d.tasks.length; i++) {
      final task = d.tasks[i];
      if (task.personId != person ||
          task.completed ||
          task.direction == 'none') {
        continue;
      }
      final incoming = ['lend', 'collect'].contains(task.direction);
      final pay = take(task.amount, incoming);
      if (pay <= 0) continue;
      d.entries.add(
        Entry(
          id: newId(),
          title: task.title,
          amount: pay,
          date: date,
          createdAt: DateTime.now(),
          kind: incoming ? 'reimbursement' : 'settlement',
          category: 'Settlement',
        ),
      );
      d.tasks[i] = GardenTask.fromJson({
        ...task.toJson(),
        'completed': pay == task.amount,
        'amount': pay == task.amount ? task.amount : task.amount - pay,
      });
    }
  }

  Map<String, int> groupBalances(String id) => _groupBalances(data, id);
  Future<void> saveGroup(Group group) => change((d) {
    d.groups.removeWhere((g) => g.id == group.id);
    d.groups.add(group);
  });
  Future<void> recordGroupSettlement(String groupId, Transfer transfer) =>
      change((d) {
        final net = groupBalances(groupId);
        if (transfer.amount <= 0 ||
            transfer.amount > -(net[transfer.fromId] ?? 0) ||
            transfer.amount > (net[transfer.toId] ?? 0)) {
          throw const FormatException(
            'Refresh the group balances before settling.',
          );
        }
        final id = newId();
        d.groupSettlements.add(
          GroupSettlement(
            id: id,
            groupId: groupId,
            fromId: transfer.fromId,
            toId: transfer.toId,
            amount: transfer.amount,
            date: DateTime.now(),
          ),
        );
        if (transfer.fromId == 'self' || transfer.toId == 'self') {
          d.entries.add(
            Entry(
              id: 'group:$id',
              title: d.groups.firstWhere((g) => g.id == groupId).name,
              amount: transfer.amount,
              date: DateTime.now(),
              createdAt: DateTime.now(),
              kind: transfer.toId == 'self' ? 'reimbursement' : 'settlement',
              category: 'Settlement',
            ),
          );
        }
      });
}

void applyGroupPayment(
  GardenData data,
  String groupId,
  Transfer transfer,
  DateTime date,
) {
  final id = newId();
  data.groupSettlements.add(
    GroupSettlement(
      id: id,
      groupId: groupId,
      fromId: transfer.fromId,
      toId: transfer.toId,
      amount: transfer.amount,
      date: date,
    ),
  );
  if (transfer.fromId == 'self' || transfer.toId == 'self') {
    data.entries.add(
      Entry(
        id: 'group:$id',
        title: data.groups.firstWhere((g) => g.id == groupId).name,
        amount: transfer.amount,
        date: date,
        createdAt: DateTime.now(),
        kind: transfer.toId == 'self' ? 'reimbursement' : 'settlement',
        category: 'Settlement',
      ),
    );
  }
}

Map<String, int> _groupBalances(GardenData d, String id) {
  final g = d.groups.firstWhere((g) => g.id == id);
  final net = {for (final p in g.memberIds) p: 0};
  for (final s in d.splits.where((s) => s.groupId == id)) {
    net[s.payerId] = net[s.payerId]! + s.total;
    for (final p in s.portions.entries) {
      net[p.key] = net[p.key]! - p.value;
    }
    for (final p in d.payments.where((p) => p.splitId == s.id)) {
      net[p.personId] = net[p.personId]! + p.amount;
      net[s.payerId] = net[s.payerId]! - p.amount;
    }
  }
  for (final p in d.groupSettlements.where((p) => p.groupId == id)) {
    net[p.fromId] = net[p.fromId]! + p.amount;
    net[p.toId] = net[p.toId]! - p.amount;
  }
  return net;
}

int _personNet(GardenData d, String person) {
  var net = d.tasks
      .where((t) => t.personId == person && !t.completed)
      .fold(
        0,
        (a, t) =>
            a +
            (['lend', 'collect'].contains(t.direction)
                ? t.amount
                : ['borrow', 'repay'].contains(t.direction)
                ? -t.amount
                : 0),
      );
  for (final split in d.splits.where((s) => s.groupId == null)) {
    if (split.payerId == 'self') {
      net += _remaining(d, split, person);
    } else if (split.payerId == person) {
      net -= _remaining(d, split, 'self');
    }
  }
  for (final group in d.groups) {
    for (final transfer in simplifyDebts(_groupBalances(d, group.id))) {
      if (transfer.fromId == person && transfer.toId == 'self') {
        net += transfer.amount;
      }
      if (transfer.fromId == 'self' && transfer.toId == person) {
        net -= transfer.amount;
      }
    }
  }
  return net;
}

int _remaining(GardenData d, BillSplit split, String person) =>
    person == split.payerId
    ? 0
    : (split.portions[person] ?? 0) -
          d.payments
              .where((p) => p.splitId == split.id && p.personId == person)
              .fold(0, (a, p) => a + p.amount);
