import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_updates.dart';

abstract class UpdateStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class LocalUpdateStorage implements UpdateStorage {
  SharedPreferencesAsync get _prefs => SharedPreferencesAsync();
  @override
  Future<String?> read(String key) =>
      _prefs.getString('money_plant.updates.$key');
  @override
  Future<void> write(String key, String value) =>
      _prefs.setString('money_plant.updates.$key', value);
  @override
  Future<void> remove(String key) => _prefs.remove('money_plant.updates.$key');
}

class UpdateService {
  final UpdateStorage storage;
  final http.Client Function() clientFactory;
  final Duration timeout;
  UpdateService(
    this.storage, {
    http.Client Function()? clientFactory,
    this.timeout = const Duration(seconds: 8),
  }) : clientFactory = clientFactory ?? http.Client.new;

  Future<AppRelease?> cached(String installed) async {
    try {
      final raw = await storage.read('release');
      return raw == null ? null : newerRelease([jsonDecode(raw)], installed);
    } catch (_) {
      return null;
    }
  }

  Future<AppRelease?> check(
    String installed, {
    bool notificationTap = false,
  }) async {
    final client = clientFactory();
    try {
      final response = await client
          .get(
            Uri.parse(releasesApi),
            headers: {
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28',
            },
          )
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw const FormatException('Unavailable');
      }
      final json = jsonDecode(response.body);
      if (json is! List) throw const FormatException('Invalid releases');
      final release = newerRelease(json, installed);
      if (release != null) {
        await storage.write('release', jsonEncode(release.toJson()));
      } else {
        await storage.remove('release');
      }
      return release;
    } catch (_) {
      // Opening a previously delivered notification also works offline.
      return notificationTap ? cached(installed) : null;
    } finally {
      client.close();
    }
  }

  Future<void> notifyIfNew(
    String installed,
    Future<bool> Function(AppRelease) deliver,
  ) async {
    final release = await check(installed);
    if (release == null || await storage.read('notified') == release.version) {
      return;
    }
    if (await deliver(release)) {
      await storage.write('notified', release.version);
    }
  }
}
