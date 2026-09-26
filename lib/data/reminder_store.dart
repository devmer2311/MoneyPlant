import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/reminders.dart';
import 'garden_store.dart';
import 'reminder_gateway.dart';

class ReminderRepository implements GardenRepository {
  SharedPreferencesAsync get preferences => SharedPreferencesAsync();
  @override
  Future<String?> read() => preferences.getString('money_plant.reminders.v1');
  @override
  Future<void> write(String value) =>
      preferences.setString('money_plant.reminders.v1', value);
}

// The default stays inert for widget previews. main initializes the device instance.
final reminderProvider = ChangeNotifierProvider<ReminderStore>(
  (ref) => ReminderStore(
    ref.read(gardenProvider),
    ReminderRepository(),
    AndroidReminderGateway(),
  ),
);

class ReminderStore extends ChangeNotifier {
  final GardenStore garden;
  final GardenRepository repository;
  final ReminderGateway gateway;
  final DateTime Function() clock;
  ReminderStore(
    this.garden,
    this.repository,
    this.gateway, {
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;
  ReminderPreferences preferences = const ReminderPreferences();
  Map<String, int> delivered = {};
  bool ready = false, allowed = false, busy = false;
  String? error, destination;
  bool _disposed = false, _listening = false;
  Future<void> _queue = Future.value();
  bool get supported => gateway.supported;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _persist(ReminderPreferences value, Map<String, int> history) =>
      repository.write(
        jsonEncode({'preferences': value.toJson(), 'delivered': history}),
      );

  Future<void> initialize() async {
    try {
      final raw = await repository.read();
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        preferences = ReminderPreferences.fromJson(
          json['preferences'] as Map<String, dynamic>,
        );
        delivered = Map<String, int>.from(json['delivered'] ?? {});
      }
      await gateway.initialize((value) {
        destination = value;
        _notify();
      });
      ready = true;
      if (!_listening) {
        garden.addListener(_changed);
        _listening = true;
      }
      await refresh();
    } catch (_) {
      error = 'Reminders could not start. Reopen the app to try again. Your money data is safe.';
      _notify();
    }
  }

  void _changed() {
    refresh();
  }

  String? takeDestination() {
    final value = destination;
    destination = null;
    return value;
  }

  Future<void> _run(Future<void> Function() work) {
    _queue = _queue.then((_) async {
      if (_disposed) return;
      busy = true;
      error = null;
      _notify();
      try {
        await work();
      } catch (_) {
        error = 'Could not update reminders. Check Android notification settings, then retry.';
      } finally {
        busy = false;
        _notify();
      }
    });
    return _queue;
  }

  Future<void> update(ReminderPreferences value) => _run(() async {
    if (!ready) {
      error = 'Reminders are still starting. Reopen the app if this continues.';
      return;
    }
    if (value.enabled && !preferences.enabled) {
      if (!supported) {
        error = 'Scheduled notifications are available in the Android app.';
        return;
      }
      allowed = await gateway.permission(request: true);
      if (!allowed) {
        error = 'Notifications are off in Android. Allow them in Settings → Apps → Money Plant → Notifications, then try again.';
        return;
      }
    }
    await _persist(value, delivered);
    preferences = value;
    await _sync();
  });
  Future<void> refresh() => _run(() async {
    if (!ready) return;
    await _sync();
  });
  Future<void> _sync() async {
    if (!supported) return;
    allowed = await gateway.permission();
    await gateway.refreshTimezone();
    final now = tz.TZDateTime.from(clock(), tz.local);
    final plan = allowed
        ? planReminders(
            preferences,
            now,
            hasSplits: garden.receivable > 0 || garden.owed > 0,
          )
        : <PlannedReminder>[];
    final activeIds = plan.map((p) => p.id).toSet();
    for (final id in scheduledReminderIds) {
      if (!activeIds.contains(id)) await gateway.cancel(id);
    }
    // Android replaces an existing alarm with the same ID, so edits cannot stack reminders.
    for (final reminder in plan) {
      await gateway.schedule(reminder);
    }
    if (!preferences.enabled || !allowed) {
      await gateway.cancel(1500);
      await gateway.cancel(1501);
      return;
    }
    if (!preferences.budgetWarnings) return;
    final month = '${now.year}-${now.month}';
    for (final category in garden.data.budgets.entries) {
      final key = '$month:${category.key}';
      final spend = monthlySpending(
        garden.data.entries.where((e) => e.category == category.key),
        now,
      );
      final level = nextBudgetWarning(
        spend,
        category.value,
        delivered[key] ?? 0,
      );
      if (level > 0) {
        await gateway.show(
          1600 + garden.data.budgets.keys.toList().indexOf(category.key),
          ReminderCopy(
            '${category.key} budget',
            '${category.key} budget ka $level% ho gaya. A little check-in 🌱',
            'insights',
          ),
        );
        delivered = {...delivered, key: level};
        await _persist(preferences, delivered);
      }
    }

    final threshold = nextBudgetWarning(
      monthlySpending(garden.data.entries, now),
      preferences.budget,
      delivered[month] ?? 0,
    );
    if (threshold == 0) return;
    await gateway.show(1500, budgetMessage(threshold));
    // Retain recent delivery history across edits, restores, restarts and disabling reminders.
    final history = {...delivered, month: threshold};
    delivered = history;
    await _persist(preferences, history);
  }

  Future<void> sendTest() => _run(() async {
    if (!supported ||
        !ready ||
        !preferences.enabled ||
        !await gateway.permission()) {
      error = 'Enable Android notifications first to send a test.';
      return;
    }
    await gateway.show(1501, dailyMessages[clock().weekday - 1]);
  });
  @override
  void dispose() {
    _disposed = true;
    if (_listening) garden.removeListener(_changed);
    super.dispose();
  }
}
