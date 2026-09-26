import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/app_updates.dart';
import 'update_background.dart';
import 'update_service.dart';

// Inert until main starts it; previews and widget tests do not use the network.
final updateProvider = ChangeNotifierProvider(
  (ref) => UpdateStore(UpdateService(LocalUpdateStorage())),
);

class UpdateStore extends ChangeNotifier {
  final UpdateService service;
  UpdateStore(this.service);
  String? installed;
  bool daily = true, ready = false, _disposed = false;
  AppRelease? pending;
  int promptId = 0;
  String? _presented;
  DateTime? _lastCheck;
  Future<void>? _checking;

  Future<void> start() async {
    try {
      installed = (await PackageInfo.fromPlatform()).version;
      daily = await service.storage.read('enabled') != 'false';
      ready = true;
      _notify();
      await check();
      await scheduleUpdateChecks(daily);
    } catch (_) {
      /* Updates must never block app launch. */
    }
  }

  Future<void> check({
    bool notificationTap = false,
    bool resume = false,
  }) async {
    if (installed == null) {
      try {
        installed = (await PackageInfo.fromPlatform()).version;
      } catch (_) {
        return;
      }
    }
    if (_checking != null) {
      await _checking;
      if (!notificationTap) return;
    }
    if (resume &&
        _lastCheck != null &&
        DateTime.now().difference(_lastCheck!) < const Duration(minutes: 1)) {
      return;
    }
    _lastCheck = DateTime.now();
    _checking = () async {
      final release = await service.check(
        installed!,
        notificationTap: notificationTap,
      );
      if (release != null &&
          (notificationTap || release.version != _presented)) {
        pending = release;
        _presented = release.version;
        promptId++;
        _notify();
      }
    }();
    try {
      await _checking;
    } finally {
      _checking = null;
    }
  }

  Future<void> setDaily(bool enabled) async {
    await service.storage.write('enabled', enabled.toString());
    daily = enabled;
    _notify();
    await scheduleUpdateChecks(enabled);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
