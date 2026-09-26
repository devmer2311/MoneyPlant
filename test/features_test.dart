import 'package:money_plant/core/import/fingerprint.dart';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_plant/core/models.dart';
import 'package:money_plant/core/settle.dart';
import 'package:money_plant/core/upi.dart';
import 'package:money_plant/core/theme/packs.dart';
import 'package:money_plant/core/import/statement_parser.dart';
import 'package:money_plant/core/import/matcher.dart';
import 'package:money_plant/data/garden_store.dart';
import 'package:money_plant/data/recurring_operations.dart';
import 'package:money_plant/features/statements/statement_pdf.dart';

import 'garden_store_test.dart' show MemoryRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('statement SHA-1 matches the standard vector', () {
    expect(
      statementFingerprint('abc'),
      'a9993e364706816aba3e25717850c26c9cd0d89d',
    );
  });
  test('all packs preserve readable semantic pairs', () {
    for (final pack in themePacks) {
      for (final t in [pack.light, pack.dark]) {
        for (final p in [
          (t.ink, t.canvas),
          (t.ink, t.surface),
          (t.inkMuted, t.surface),
          (t.onBrand, t.brand),
          (t.onReceive, t.receive),
          (t.onOwe, t.owe),
        ]) {
          final a = p.$1.computeLuminance(), b = p.$2.computeLuminance();
          expect(
            ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05),
            greaterThanOrEqualTo(4.5),
            reason: pack.id,
          );
        }
      }
    }
  });
  test('UPI links preserve paise and encoded names', () {
    final uri = Uri.parse(
      upiLink(upiId: 'dev@bank', payeeName: 'Dev Kumar 🌱', amountMinor: 12345),
    );
    expect(uri.queryParameters['am'], '123.45');
    expect(uri.queryParameters['pn'], 'Dev Kumar 🌱');
  });
  test('item allocation and greedy transfers preserve integer totals', () {
    final result = itemPortions(
      [
        const SplitItem(name: 'meal', amount: 10001, personIds: ['self', 'a']),
        const SplitItem(name: 'tax', amount: 501, kind: 'tax'),
        const SplitItem(name: 'discount', amount: 100, kind: 'discount'),
      ],
      ['self', 'a', 'b'],
    );
    expect(result.values.reduce((a, b) => a + b), 10402);
    expect(result['b'], 0);
    final net = {'self': 500, 'a': -200, 'b': -300};
    for (final t in simplifyDebts(net)) {
      net[t.fromId] = net[t.fromId]! + t.amount;
      net[t.toId] = net[t.toId]! - t.amount;
    }
    expect(net.values.every((v) => v == 0), isTrue);
  });
  test(
    'split edit, payment removal and third-party settlements are atomic',
    () async {
      final repository = MemoryRepository();
      final s = GardenStore(repository);
      final bill = BillSplit(
        id: 'b',
        title: 'Dinner',
        total: 900,
        date: DateTime(2026),
        method: SplitMethod.equal,
        portions: {'self': 300, 'a': 300, 'b': 300},
      );
      await s.saveSplit(bill, [
        const Person(id: 'a', name: 'Alex'),
        const Person(id: 'b', name: 'Sam'),
      ]);
      await s.recordPayment('b', 'a', 100, DateTime(2026));
      final id = s.data.payments.single.id;
      expect(s.data.entries.last.paymentId, id);
      await s.removePayment(id);
      expect(s.remaining(bill, 'a'), 300);
      await s.recordPayment('b', 'a', 300, DateTime(2026));
      await expectLater(
        s.updateSplit(
          BillSplit.fromJson({
            ...bill.toJson(),
            'portions': {'self': 500, 'a': 100, 'b': 300},
          }),
          [],
        ),
        throwsFormatException,
      );
      expect(s.data.splits.single.portions['a'], 300);
      await s.deleteSplit('b');
      expect(s.data.payments, isEmpty);
      expect(s.data.entries, isEmpty);
    },
  );
  test('recurring catch-up clamps February and never duplicates', () async {
    final s = GardenStore(MemoryRepository());
    await s.saveRecurring(
      RecurringRule(
        id: 'r',
        title: 'Rent',
        amount: 10000,
        category: 'Bills',
        dayOfMonth: 31,
        startDate: DateTime(2026, 1, 31),
      ),
    );
    await s.runRecurring(DateTime(2026, 3, 31));
    expect(s.data.entries.length, 3);
    expect(s.data.entries[1].date, DateTime(2026, 2, 28));
    await s.runRecurring(DateTime(2026, 3, 31));
    expect(s.data.entries.length, 3);
  });
  test(
    'statement import is idempotent and matching does not invent income',
    () async {
      final s = GardenStore(MemoryRepository());
      final cells = await statementCells(
        utf8.encode(
          'Date,Description,Debit,Credit\n12/09/2026,UPI/DR/123/SWIGGY/YESB,123.45,\n13/09/2026,Salary,,1000.00\n',
        ),
        'csv',
      );
      final detected = detectMapping(cells);
      final rows = parseStatement(cells, detected.$1, detected.$2!);
      expect(rows.first.title, 'Swiggy');
      expect(rows.first.amount, 12345);
      await commitImport(s, rows);
      await commitImport(s, rows);
      expect(s.data.entries.length, 2);
    },
  );
  test('combined settlement imports use staged balances and roll back overpayments', () async {
    final s = GardenStore(MemoryRepository());
    for (final id in ['one', 'two']) {
      await s.saveSplit(
        BillSplit(
          id: id,
          title: id,
          total: 600,
          date: DateTime(2026),
          method: SplitMethod.equal,
          portions: {'self': 300, 'p': 300},
        ),
        [const Person(id: 'p', name: 'Pat')],
      );
    }
    StatementRow credit(String ref, int amount) => StatementRow(
      date: DateTime(2026),
      amount: amount,
      credit: true,
      narration: 'Pat payment',
      ref: ref,
      title: 'Pat',
      category: 'Other income',
    )..personId = 'p';
    final before = s.data.encode();
    await expectLater(
      commitImport(s, [credit('first', 400), credit('second', 400)]),
      throwsFormatException,
    );
    expect(s.data.encode(), before);
    await commitImport(s, [credit('first', 400), credit('second', 200)]);
    expect(s.personNet('p'), 0);
    expect(s.data.entries.where((e) => e.kind == 'income'), isEmpty);
    final count = s.data.entries.length;
    await commitImport(s, [credit('first', 400), credit('second', 200)]);
    expect(s.data.entries.length, count);
  });
  test('settle all offsets mixed directions in one write', () async {
    final s = GardenStore(MemoryRepository());
    for (final (id, payer, total) in [('a', 'self', 1000), ('b', 'p', 400)]) {
      await s.saveSplit(
        BillSplit(
          id: id,
          title: id,
          total: total,
          date: DateTime(2026),
          method: SplitMethod.equal,
          payerId: payer,
          portions: {'self': total ~/ 2, 'p': total ~/ 2},
        ),
        [const Person(id: 'p', name: 'Pat')],
      );
    }
    expect(s.personNet('p'), 300);
    await s.settleAll('p', 300, DateTime(2026));
    expect(s.personNet('p'), 0);
    expect(s.data.payments.length, 2);
  });
  test('offline branded statement PDF generates for every pack', () async {
    final s = GardenStore(MemoryRepository());
    const p = Person(id: 'p', name: 'Pat');
    await s.change((d) => d.people.add(p));
    for (final pack in themePacks) {
      await s.change((d) => d.themePack = pack.id);
      final bytes = await statementPdf(s, person: p);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    }
  });
}
