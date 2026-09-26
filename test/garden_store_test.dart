import 'package:flutter_test/flutter_test.dart';
import 'package:money_plant/core/models.dart';
import 'package:money_plant/data/garden_store.dart';
import 'package:money_plant/features/reports.dart';

class MemoryRepository implements GardenRepository {
  String? value;
  bool fail = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    if (fail) throw StateError('Disk full');
    this.value = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryRepository repository;
  late GardenStore store;
  setUp(() {
    repository = MemoryRepository();
    store = GardenStore(repository);
  });
  Entry entry({
    String id = 'entry',
    int amount = 10000,
    String kind = 'expense',
    DateTime? date,
  }) => Entry(
    id: id,
    title: 'Coffee',
    amount: amount,
    kind: kind,
    date: date ?? DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
  );
  BillSplit bill({String payer = 'self'}) => BillSplit(
    id: 'bill',
    title: 'Dinner',
    total: 10000,
    date: DateTime(2026, 1, 1),
    method: SplitMethod.equal,
    payerId: payer,
    portions: const {'self': 3334, 'a': 3333, 'b': 3333},
  );
  const people = [Person(id: 'a', name: 'Alex'), Person(id: 'b', name: 'Sam')];
  test('currency parser is exact and rejects invalid precision', () {
    expect(parseMoney('1,234.56'), 123456);
    expect(parseMoney('0.01'), 1);
    for (final value in ['-1', '0', '1.234', 'NaN', '1e5', '']) {
      expect(() => parseMoney(value), throwsFormatException);
    }
  });
  test('equal split distributes every paise deterministically', () {
    expect(allocateSplit(10000, SplitMethod.equal, [1, 1, 1]), [
      3334,
      3333,
      3333,
    ]);
    expect(allocateSplit(1, SplitMethod.equal, [1, 1, 1]), [1, 0, 0]);
  });
  test('custom, percentage and shares allocate exact totals', () {
    expect(allocateSplit(10000, SplitMethod.custom, [4000, 6000]), [
      4000,
      6000,
    ]);
    expect(allocateSplit(10000, SplitMethod.percentage, [2550, 7450]), [
      2550,
      7450,
    ]);
    expect(allocateSplit(10000, SplitMethod.shares, [2, 1, 1]), [
      5000,
      2500,
      2500,
    ]);
    for (var total = 1; total < 300; total++) {
      expect(
        allocateSplit(total, SplitMethod.shares, [
          1,
          2,
          5,
          9,
        ]).fold(0, (a, b) => a + b),
        total,
      );
    }
  });
  test('invalid totals and participants are rejected', () {
    expect(
      () => allocateSplit(100, SplitMethod.custom, [20, 30]),
      throwsFormatException,
    );
    expect(
      () => allocateSplit(100, SplitMethod.percentage, [4000, 5000]),
      throwsFormatException,
    );
    expect(
      () => allocateSplit(100, SplitMethod.shares, [0, 0]),
      throwsFormatException,
    );
    expect(
      () => allocateSplit(100, SplitMethod.shares, [-1, 2]),
      throwsFormatException,
    );
    expect(
      () => allocateSplit(100, SplitMethod.equal, [1]),
      throwsFormatException,
    );
  });
  test('entries persist, edit across months and retain ID', () async {
    await store.saveEntry(entry());
    await store.saveEntry(entry(amount: 15000, date: DateTime(2026, 2, 12)));
    final reopened = GardenStore(repository);
    await reopened.load();
    expect(reopened.data.entries.single.id, 'entry');
    expect(reopened.monthTotal(false, DateTime(2026, 1)), 0);
    expect(reopened.monthTotal(false, DateTime(2026, 2)), 15000);
    await store.removeEntry('entry');
    expect(store.balance, 0);
    await store.saveEntry(entry());
    expect(store.balance, -10000);
    expect(store.xp, 5); // Undo and edit do not farm XP.
  });
  test('future entries do not change available balance', () async {
    await store.saveEntry(
      entry(kind: 'income', date: DateTime.now().add(const Duration(days: 2))),
    );
    expect(store.balance, 0);
    expect(store.data.entries.length, 1);
  });
  test('failed writes leave published and persisted state unchanged', () async {
    await store.saveEntry(entry());
    repository.fail = true;
    await expectLater(store.saveEntry(entry(amount: 700)), throwsStateError);
    expect(store.balance, -10000);
    expect(GardenData.decode(repository.value!).entries.single.amount, 10000);
  });
  test('task completion only records money when explicitly chosen', () async {
    final task = GardenTask(
      id: 't',
      title: 'Collect from Alex',
      date: DateTime(2027),
      amount: 20000,
      direction: 'collect',
    );
    await store.saveTask(task);
    expect(store.balance, 0);
    await store.completeTask('t');
    expect(store.balance, 0);
    expect(store.xp, 10);
    await store.completeTask('t', record: true);
    expect(store.balance, 0);
    expect(store.xp, 10);
    await store.saveTask(GardenTask.fromJson({...task.toJson(), 'id': 't2'}));
    await store.completeTask('t2', record: true);
    expect(store.balance, 20000);
    await store.completeTask('t2', record: true);
    expect(store.data.entries.length, 1);
  });
  test(
    'goal contributions distinguish progress from cash and award once',
    () async {
      await store.saveGoal(
        Goal(id: 'g', title: 'Headphones', target: 10000, date: DateTime(2027)),
      );
      await store.contribute('g', 5000);
      expect(store.balance, 0);
      expect(store.progress('g'), 5000);
      await store.contribute('g', 5000, record: true);
      expect(store.balance, -5000);
      expect(store.xp, 100);
      await store.contribute('g', 1000);
      expect(store.xp, 100);
      final reopened = GardenStore(repository);
      await reopened.load();
      expect(reopened.progress('g'), 11000);
    },
  );
  test(
    'user-paid split keeps full expense and tracks partial reimbursements',
    () async {
      await store.saveSplit(bill(), people);
      expect(store.balance, -10000);
      expect(store.receivable, 6666);
      await store.recordPayment('bill', 'a', 1000, DateTime(2026, 1, 2));
      expect(store.receivable, 5666);
      expect(store.balance, -9000);
      expect(store.remaining(bill(), 'a'), 2333);
      await store.recordPayment('bill', 'a', 2333, DateTime(2026, 1, 3));
      expect(store.remaining(bill(), 'a'), 0);
      expect(store.data.payments.length, 2);
      expect(
        store.monthTotal(true, DateTime(2026, 1)),
        0,
      ); // Reimbursement is not earned income.
      await expectLater(
        store.recordPayment('bill', 'a', 1, DateTime.now()),
        throwsFormatException,
      );
      await expectLater(
        store.removeEntry(store.data.entries.first.id),
        throwsFormatException,
      );
    },
  );
  test(
    'other payer creates a liability without fictional cash movement',
    () async {
      await store.saveSplit(bill(payer: 'a'), people);
      expect(store.balance, 0);
      expect(store.owed, 3334);
      expect(store.receivable, 0);
      await store.recordPayment('bill', 'self', 1000, DateTime(2026, 1, 2));
      expect(store.owed, 2334);
      expect(store.balance, -1000);
      await store.recordPayment('bill', 'b', 10, DateTime.now());
      expect(store.remaining(bill(payer: 'a'), 'b'), 3323);
      expect(
        store.balance,
        -1000,
      ); // Third-party payment has no personal cash movement.
    },
  );
  test('split message contains computed amounts and payment state', () async {
    await store.saveSplit(bill(), people);
    final text = splitMessage(store, bill());
    expect(text, contains('Alex'));
    expect(text, contains('33.33 pending'));
    expect(text, contains('You — ₹33.34 · Paid'));
  });
  test('PDF is generated offline from bundled font and data', () async {
    await store.saveSplit(bill(), people);
    final bytes = await splitPdf(store, bill());
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });
  test('streak uses tracking days and tolerates yesterday as latest', () async {
    await store.change((d) {
      d.activity['entry:a'] = '2026-09-18T10:00:00';
      d.activity['task:b'] = '2026-09-19T10:00:00';
    });
    expect(store.streak(DateTime(2026, 9, 20)), 2);
    expect(store.streak(DateTime(2026, 9, 21)), 0);
  });
  test(
    'backup roundtrip preserves relationships and rejects corrupt amounts',
    () async {
      await store.saveSplit(bill(), people);
      await store.recordPayment('bill', 'a', 200, DateTime(2026, 1, 2));
      final backup = store.data.encode();
      await store.restore(backup);
      expect(store.receivable, 6466);
      await expectLater(
        store.restore(backup.replaceFirst('"total":10000', '"total":9999')),
        throwsFormatException,
      );
      expect(store.receivable, 6466);
      await expectLater(
        store.restore('{"schemaVersion":99}'),
        throwsFormatException,
      );
    },
  );
}
