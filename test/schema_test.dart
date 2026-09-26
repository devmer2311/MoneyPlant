import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_plant/core/models.dart';
import 'package:money_plant/data/garden_store.dart';

import 'garden_store_test.dart' show MemoryRepository;

void main() {
  final fixture = File('test/fixtures/backup_v1.json').readAsStringSync();
  test('real v1 serializer fixture migrates losslessly to v2', () {
    final original = jsonDecode(fixture) as Map<String, dynamic>;
    expect(original['schemaVersion'], 1);
    final data = GardenData.decode(fixture);
    data.validate();
    expect(data.toJson()['schemaVersion'], 2);
    expect(data.themePack, 'garden');
    expect(data.profile.upiId, isEmpty);
    expect(data.groups, isEmpty);
    expect(data.appLock, isFalse);
    for (final key in [
      'entries',
      'tasks',
      'goals',
      'contributions',
      'people',
      'splits',
      'payments',
    ]) {
      final migrated = data.toJson()[key] as List;
      final old = original[key] as List;
      for (var i = 0; i < old.length; i++) {
        for (final field in (old[i] as Map).entries) {
          expect(migrated[i][field.key], field.value);
        }
      }
    }
    expect(GardenData.decode(data.encode()).encode(), data.encode());
  });
  test('v2 models preserve every new field', () {
    final data = GardenData.decode(fixture);
    data.themePack = 'ocean';
    data.profile = const Profile(
      displayName: 'Dev',
      payeeName: 'Dev',
      upiId: 'dev@okaxis',
      includeQr: false,
    );
    data.appLock = true;
    data.groups.add(
      Group(
        id: 'trip',
        name: 'Goa',
        memberIds: ['self', 'rahul'],
        createdAt: DateTime(2026),
      ),
    );
    data.groupSettlements.add(
      GroupSettlement(
        id: 'gs',
        groupId: 'trip',
        fromId: 'rahul',
        toId: 'self',
        amount: 100,
        date: DateTime(2026),
      ),
    );
    data.recurring.add(
      RecurringRule(
        id: 'rent',
        title: 'Rent',
        amount: 10000,
        category: 'Home',
        dayOfMonth: 31,
        startDate: DateTime(2026),
      ),
    );
    data.budgets['Food'] = 10000;
    data.importMappings['bank'] = const ColumnMapping(
      date: 0,
      description: 1,
      debit: 2,
      credit: 3,
      categoryRules: {'coffee': 'Food'},
    );
    data.splits[0] = BillSplit.fromJson({
      ...data.splits[0].toJson(),
      'groupId': 'trip',
      'notes': 'Dinner notes',
      'items': [
        const SplitItem(
          name: 'Dinner',
          amount: 10001,
          personIds: ['self', 'rahul'],
        ).toJson(),
      ],
    });
    data.entries[0] = Entry.fromJson({
      ...data.entries[0].toJson(),
      'importRef': 'bank-ref',
      'recurringId': 'deleted-rule',
    });
    data.payments[0] = Payment.fromJson({
      ...data.payments[0].toJson(),
      'note': 'UPI',
    });
    data.validate();
    expect(GardenData.decode(data.encode()).encode(), data.encode());
  });
  test('unknown pack falls back but invalid in-memory pack is rejected', () {
    final json = GardenData().toJson()..['themePack'] = 'future';
    expect(GardenData.decode(jsonEncode(json)).themePack, 'garden');
    expect(
      () => (GardenData()..themePack = 'future').validate(),
      throwsFormatException,
    );
  });
  test('malformed structure and unsupported versions are friendly errors', () {
    for (final raw in [
      '[]',
      '{}',
      '{"schemaVersion":3}',
      '{"schemaVersion":2,"entries":"bad"}',
    ]) {
      expect(() => GardenData.decode(raw), throwsFormatException);
    }
  });
  test('invalid new fields are rejected on decode', () {
    for (final mutation in <void Function(Map<String, dynamic>)>[
      (j) => j['profile'] = {'upiId': 'bad'},
      (j) => j['budgets'] = {'Food': -1},
      (j) => j['appLock'] = 'true',
      (j) => j['groups'] = [
        {
          'id': 'g',
          'name': 'Trip',
          'createdAt': '2026-01-01',
          'memberIds': ['self', 'missing'],
        },
      ],
      (j) => j['importMappings'] = {
        'bank': {'date': 0, 'description': 0, 'debit': 2},
      },
      (j) => j['entries'][0]['paymentId'] = 'missing',
    ]) {
      final json = GardenData.decode(fixture).toJson();
      mutation(json);
      expect(() => GardenData.decode(jsonEncode(json)), throwsFormatException);
    }
  });
  test(
    'invalid atomic changes neither write nor publish and next save works',
    () async {
      final repository = MemoryRepository();
      final store = GardenStore(repository);
      await store.restore(fixture);
      final before = store.data.encode();
      var notifications = 0;
      store.addListener(() => notifications++);
      await expectLater(
        store.change((d) => d.budgets['Food'] = -1),
        throwsFormatException,
      );
      expect(store.data.encode(), before);
      expect(repository.value, before);
      expect(notifications, 0);
      await store.change((d) => d.budgets['Food'] = 1000);
      expect(notifications, 1);
    },
  );
}
