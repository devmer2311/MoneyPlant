import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../core/models.dart';
import 'garden_repository.dart';
import 'sqlite_schema.dart';

/// SQLite holds individual records, while the store retains its atomic snapshot
/// API. Normal backups use GardenData only; internal metadata is never exported.
class SqliteGardenRepository implements GardenRepository {
  final Database database;
  int? _revision;

  SqliteGardenRepository._(this.database);

  static Future<SqliteGardenRepository> open(
    DatabaseFactory factory,
    String path,
  ) async {
    final database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: storageSchemaVersion,
        onCreate: (db, version) => _createSchema(db),
        // Unknown/newer versions must fail closed, never erase user data.
        onUpgrade: (db, oldVersion, newVersion) async {
          throw StateError(
            'Unsupported local database upgrade: $oldVersion to $newVersion.',
          );
        },
        onDowngrade: (db, oldVersion, newVersion) async {
          throw StateError(
            'This database needs a newer version of Money Plant.',
          );
        },
      ),
    );
    return SqliteGardenRepository._(database);
  }

  static Future<void> _createSchema(Database db) async {
    for (final table in entityColumns.entries) {
      final fields = table.value.entries
          .map((field) {
            final type = field.value == 'JSON'
                ? 'TEXT'
                : field.value == 'BOOLEAN'
                ? 'INTEGER'
                : field.value;
            return '"${field.key}" $type';
          })
          .join(', ');
      await db.execute(
        'CREATE TABLE "${table.key}" (id TEXT PRIMARY KEY NOT NULL, position INTEGER NOT NULL, $fields)',
      );
    }
    for (final table in [...mapTables, 'settings']) {
      await db.execute(
        'CREATE TABLE "$table" (key TEXT PRIMARY KEY NOT NULL, value TEXT NOT NULL, position INTEGER NOT NULL)',
      );
    }
    await db.execute(
      'CREATE TABLE storage_metadata (key TEXT PRIMARY KEY NOT NULL, value TEXT NOT NULL)',
    );
    await db.execute('CREATE INDEX entries_split ON entries(splitId)');
    await db.execute(
      'CREATE INDEX payments_split_person ON payments(splitId, personId)',
    );
    await db.execute('CREATE INDEX splits_group ON splits(groupId)');
  }

  Future<String?> _metadata(DatabaseExecutor db, String key) async {
    final rows = await db.query(
      'storage_metadata',
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.single['value'] as String;
  }

  Future<void> _setMetadata(DatabaseExecutor db, String key, String value) => db
      .insert('storage_metadata', {
        'key': key,
        'value': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace)
      .then((_) {});

  @override
  Future<String?> read() => database.transaction((txn) async {
    final revision = await _metadata(txn, 'revision');
    _revision = int.parse(revision ?? '0');
    if (revision == null) return null;
    return (await _readSnapshot(txn)).encode();
  });

  Future<GardenData> _readSnapshot(DatabaseExecutor db) async {
    final result = <String, dynamic>{};
    for (final table in entityColumns.entries) {
      result[table.key] = [
        for (final row in await db.query('"${table.key}"', orderBy: 'position'))
          {
            'id': row['id'],
            for (final field in table.value.entries)
              field.key: field.value == 'JSON'
                  ? jsonDecode(row[field.key] as String)
                  : field.value == 'BOOLEAN'
                  ? row[field.key] == 1
                  : row[field.key],
          },
      ];
    }
    for (final table in mapTables) {
      result[table] = {
        for (final row in await db.query(table, orderBy: 'position'))
          row['key'] as String: jsonDecode(row['value'] as String),
      };
    }
    for (final row in await db.query('settings', orderBy: 'position')) {
      result[row['key'] as String] = jsonDecode(row['value'] as String);
    }
    return GardenData.decode(jsonEncode(result));
  }

  Future<void> _writeSnapshot(Transaction txn, GardenData data) async {
    final json = data.toJson();
    final batch = txn.batch();
    for (final table in entityColumns.entries) {
      batch.delete('"${table.key}"');
      final rows = json[table.key] as List;
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i] as Json;
        batch.insert('"${table.key}"', {
          'id': row['id'],
          'position': i,
          for (final field in table.value.entries)
            field.key: field.value == 'JSON'
                ? jsonEncode(row[field.key])
                : field.value == 'BOOLEAN'
                ? (row[field.key] == true ? 1 : 0)
                : row[field.key],
        });
      }
    }
    for (final table in [...mapTables, 'settings']) {
      batch.delete(table);
      final values = table == 'settings'
          ? {for (final key in settingKeys) key: json[key]}
          : json[table] as Map;
      var position = 0;
      for (final entry in values.entries) {
        batch.insert(table, {
          'key': entry.key,
          'value': jsonEncode(entry.value),
          'position': position++,
        });
      }
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> write(String value) async {
    final data = GardenData.decode(value);
    final nextRevision = await database.transaction((txn) async {
      final revision = int.parse(await _metadata(txn, 'revision') ?? '0');
      if (_revision != revision) {
        throw StateError(
          'Your data changed in another session. Reopen Money Plant before saving.',
        );
      }
      await _writeSnapshot(txn, data);
      final verified = await _readSnapshot(txn);
      if (!mapEquals(
        data.toJson().map((k, v) => MapEntry(k, jsonEncode(v))),
        verified.toJson().map((k, v) => MapEntry(k, jsonEncode(v))),
      )) {
        throw StateError(
          'Local database verification failed. Your previous data is safe.',
        );
      }
      await _setMetadata(txn, 'revision', '${revision + 1}');
      return revision + 1;
    });
    _revision = nextRevision;
  }

  Future<void> close() => database.close();

  /// Import the old local record once. The schema may already exist after an
  /// interrupted launch, so completion is determined by a committed marker.
  Future<void> initializeFromLegacy(GardenRepository legacy) async {
    final revision = await database.transaction((txn) async {
      final marker = await _metadata(txn, 'jsonMigrationVersion');
      if (marker != null) {
        if (marker != '1') {
          throw StateError('Unsupported local data migration version.');
        }
        // Verify the destination on every open; do not silently fall back to
        // stale JSON when an already-migrated database is damaged.
        await _readSnapshot(txn);
        return int.parse((await _metadata(txn, 'revision'))!);
      }
      if (await _metadata(txn, 'revision') != null) {
        throw StateError(
          'An unrecognized database already contains data. Export it before attempting recovery.',
        );
      }
      final raw = await legacy.read();
      final data = raw == null ? GardenData() : GardenData.decode(raw);
      await _writeSnapshot(txn, data);
      final verified = await _readSnapshot(txn);
      if (data.encode() != verified.encode()) {
        throw StateError(
          'Migration verification failed. The original local data is unchanged.',
        );
      }
      await _setMetadata(txn, 'revision', '1');
      await _setMetadata(txn, 'jsonMigrationVersion', '1');
      await _setMetadata(
        txn,
        'migrationSource',
        raw == null ? 'fresh' : 'legacyJson',
      );
      await _setMetadata(
        txn,
        'migrationCompletedAt',
        DateTime.now().toUtc().toIso8601String(),
      );
      return 1;
    });
    _revision = revision;
  }
}
