import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_plant/core/models.dart';
import 'package:money_plant/data/garden_store.dart';
import 'package:money_plant/data/sqlite_garden_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'garden_store_test.dart' show MemoryRepository;

void main() {
  late SqliteGardenRepository repository;
  late Directory directory;
  late String path;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('money_plant_sqlite_');
    path = '${directory.path}/garden.sqlite';
    repository = await SqliteGardenRepository.open(databaseFactoryFfi, path);
  });
  tearDown(() async {
    await repository.close();
    await directory.delete(recursive: true);
  });

  test('SQLite survives close/reopen and v1 backup restore', () async {
    final store = GardenStore(repository);
    await store.load();
    expect(store.data.entries, isEmpty);
    await store.restore(
      File('test/fixtures/backup_v1.json').readAsStringSync(),
    );
    final backup = store.data.encode();
    await repository.close();
    repository = await SqliteGardenRepository.open(databaseFactoryFfi, path);
    expect(await repository.read(), backup);
    expect(
      (await repository.database.query('entries')).length,
      store.data.entries.length,
    );
  });

  test('failed SQL write rolls back all tables and published state', () async {
    final store = GardenStore(repository);
    await store.load();
    await store.restore(
      File('test/fixtures/backup_v1.json').readAsStringSync(),
    );
    final before = store.data.encode();
    await repository.database.execute(
      "CREATE TRIGGER fail_write BEFORE INSERT ON settings BEGIN SELECT RAISE(ABORT, 'disk failure'); END",
    );
    await expectLater(
      store.change((d) => d.people.add(const Person(id: 'new', name: 'New'))),
      throwsA(isA<Exception>()),
    );
    expect(store.data.encode(), before);
    expect(await repository.read(), before);
    await repository.database.execute('DROP TRIGGER fail_write');
    await store.change((d) => d.theme = 'dark');
    expect(GardenData.decode((await repository.read())!).theme, 'dark');
  });

  test('stale snapshot cannot overwrite another session', () async {
    await repository.read();
    final second = await SqliteGardenRepository.open(databaseFactoryFfi, path);
    await second.read();
    await repository.write(GardenData(theme: 'dark').encode());
    await expectLater(second.write(GardenData().encode()), throwsStateError);
    expect(GardenData.decode((await repository.read())!).theme, 'dark');
  });

  test(
    'one-time migration preserves every v2 entity and never rereads old JSON',
    () async {
      final data = GardenData.decode(
        File('test/fixtures/backup_v1.json').readAsStringSync(),
      );
      data.groups.add(
        Group(
          id: 'g',
          name: 'Trip',
          memberIds: ['self', 'rahul'],
          createdAt: DateTime(2026),
        ),
      );
      data.groupSettlements.add(
        GroupSettlement(
          id: 'gs',
          groupId: 'g',
          fromId: 'rahul',
          toId: 'self',
          amount: 25,
          date: DateTime(2026),
        ),
      );
      data.recurring.add(
        RecurringRule(
          id: 'rec',
          title: 'Rent',
          amount: 300,
          category: 'Home',
          startDate: DateTime(2026),
          paused: true,
        ),
      );
      data.budgets['Food'] = 20000;
      data.importMappings['bank'] = const ColumnMapping(
        date: 0,
        description: 1,
        debit: 2,
      );
      data.profile = const Profile(
        displayName: 'Dev',
        upiId: 'dev@bank',
        includeQr: false,
      );
      data.appLock = true;
      data.splits[0] = BillSplit.fromJson({
        ...data.splits[0].toJson(),
        'groupId': 'g',
        'items': [
          const SplitItem(
            name: 'Dinner',
            amount: 10001,
            personIds: ['self', 'rahul'],
          ).toJson(),
        ],
      });
      final legacy = MemoryRepository()..value = data.encode();
      final original = legacy.value;
      await repository.initializeFromLegacy(legacy);
      expect(await repository.read(), data.encode());
      expect(legacy.value, original);
      final store = GardenStore(repository);
      await store.load();
      await store.change((d) => d.theme = 'dark');
      await repository.close();
      repository = await SqliteGardenRepository.open(databaseFactoryFfi, path);
      legacy.value = 'corrupted old fallback';
      await repository.initializeFromLegacy(legacy);
      expect(GardenData.decode((await repository.read())!).theme, 'dark');
    },
  );

  test(
    'corrupt JSON and interrupted migration remain retryable without a marker',
    () async {
      final legacy = MemoryRepository()..value = '{broken';
      await expectLater(
        repository.initializeFromLegacy(legacy),
        throwsFormatException,
      );
      expect(legacy.value, '{broken');
      expect(await repository.database.query('storage_metadata'), isEmpty);
      legacy.value = File('test/fixtures/backup_v1.json').readAsStringSync();
      await repository.database.execute(
        "CREATE TRIGGER migration_failure BEFORE INSERT ON storage_metadata WHEN NEW.key = 'jsonMigrationVersion' BEGIN SELECT RAISE(ABORT, 'interrupted'); END",
      );
      await expectLater(
        repository.initializeFromLegacy(legacy),
        throwsA(isA<Exception>()),
      );
      expect(await repository.database.query('entries'), isEmpty);
      expect(await repository.database.query('storage_metadata'), isEmpty);
      await repository.database.execute('DROP TRIGGER migration_failure');
      await repository.initializeFromLegacy(legacy);
      expect(
        await repository.read(),
        GardenData.decode(legacy.value!).encode(),
      );
    },
  );

  test(
    'fresh install remains empty after restart even if stale JSON appears',
    () async {
      final legacy = MemoryRepository();
      await repository.initializeFromLegacy(legacy);
      expect(await repository.read(), GardenData().encode());
      legacy.value = File('test/fixtures/backup_v1.json').readAsStringSync();
      await repository.initializeFromLegacy(legacy);
      expect(await repository.read(), GardenData().encode());
    },
  );
}
