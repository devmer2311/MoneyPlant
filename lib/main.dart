import 'dart:async';

import 'data/update_store.dart';
import 'data/update_service.dart';
import 'data/recurring_operations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/garden_store.dart';
import 'data/reminder_store.dart';
import 'data/reminder_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = GardenStore(LocalGardenRepository());
  try {
    await store.load();
    await store.runRecurring();
    final reminders = ReminderStore(
      store,
      ReminderRepository(),
      AndroidReminderGateway(),
    );
    await reminders.initialize();
    final updates = UpdateStore(UpdateService(LocalUpdateStorage()));
    runApp(
      ProviderScope(
        overrides: [
          updateProvider.overrideWith((ref) => updates),
          gardenProvider.overrideWith((ref) => store),
          reminderProvider.overrideWith((ref) => reminders),
        ],
        child: const MoneyPlantApp(),
      ),
    );
    unawaited(updates.start());
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 40),
                  const SizedBox(height: 20),
                  const Text(
                    'Your garden could not be opened. Your saved data has not been changed.',
                  ),
                  const SizedBox(height: 20),
                  FilledButton(onPressed: main, child: const Text('Try again')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
