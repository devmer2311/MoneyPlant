import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_plant/core/design.dart';
import 'package:money_plant/core/models.dart';
import 'package:money_plant/core/reminders.dart';
import 'package:money_plant/data/garden_store.dart';
import 'package:money_plant/data/reminder_gateway.dart';
import 'package:money_plant/data/reminder_store.dart';
import 'package:money_plant/features/reminder_settings.dart';
import 'package:money_plant/shared/launch_experience.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'garden_store_test.dart' show MemoryRepository;

class FakeGateway implements ReminderGateway {
  @override
  bool supported = true;
  bool granted = true, fail = false;
  final planned = <int, PlannedReminder>{};
  final shown = <ReminderCopy>[];
  int prompts = 0;
  @override
  Future<void> initialize(void Function(String) onTap) async {}
  @override
  Future<void> refreshTimezone() async {}
  @override
  Future<bool> permission({bool request = false}) async {
    if (request) prompts++;
    return granted;
  }

  @override
  Future<void> schedule(PlannedReminder reminder) async {
    if (fail) throw StateError('Scheduling unavailable');
    planned[reminder.id] = reminder;
  }

  @override
  Future<void> cancel(int id) async {
    planned.remove(id);
  }

  @override
  Future<void> show(int id, ReminderCopy copy) async {
    shown.add(copy);
  }
}

void main() {
  Future<void> fonts() async {
    for (final family in ['Outfit', 'Manrope', 'NotoSans']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary).first,
    );
    boundary.markNeedsPaint();
    await tester.pump();
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('artifacts').create(recursive: true);
      await File('artifacts/$name.png')
          .writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  });
  final now = DateTime(2026, 9, 20, 12);
  Entry entry(int amount, {String kind = 'expense', DateTime? date}) => Entry(
    id: newId(),
    title: 'Test',
    amount: amount,
    date: date ?? now,
    createdAt: now,
    kind: kind,
  );

  test(
    'Repeating daily messages cover every weekday with stable unique IDs',
    () {
      final date = tz.TZDateTime(tz.local, 2026, 9, 20, 12);
      final plan = planReminders(
        const ReminderPreferences(enabled: true),
        date,
        hasSplits: true,
      );
      expect(plan.length, 16);
      expect(plan.map((e) => e.id).toSet().length, 16);
      expect(
        plan
            .where((e) => e.id < 1200)
            .map((e) => e.date.weekday)
            .toSet()
            .length,
        7,
      );
      expect(plan.every((e) => e.date.isAfter(date)), isTrue);
      expect(
        plan.firstWhere((e) => e.id == 1300).date,
        tz.TZDateTime(tz.local, 2026, 10, 1, 10),
      );
    },
  );
  test('Disabled reminders and settled splits are omitted', () {
    final date = tz.TZDateTime(tz.local, 2026, 9, 20);
    expect(
      planReminders(const ReminderPreferences(), date, hasSplits: true),
      isEmpty,
    );
    final plan = planReminders(
      const ReminderPreferences(
        enabled: true,
        daily: false,
        evening: false,
        monthly: false,
      ),
      date,
      hasSplits: false,
    );
    expect(plan, isEmpty);
  });
  test('Calendar schedules handle year rollover and DST local wall time', () {
    final december = tz.TZDateTime(tz.local, 2026, 12, 31, 23);
    final monthly = planReminders(
      const ReminderPreferences(enabled: true),
      december,
      hasSplits: false,
    ).firstWhere((e) => e.id == 1300);
    expect(monthly.date, tz.TZDateTime(tz.local, 2027, 1, 1, 10));
    final ny = tz.getLocation('America/New_York');
    final saturday = tz.TZDateTime(ny, 2026, 3, 7, 20);
    final sunday = planReminders(
      const ReminderPreferences(enabled: true),
      saturday,
      hasSplits: false,
    ).firstWhere((e) => e.id == 1107);
    expect(sunday.date.hour, 18);
    expect(sunday.date.minute, 30);
    expect(sunday.date.timeZoneOffset, const Duration(hours: -4));
  });
  test('Budget thresholds suppress repeats and jump straight to exceeded', () {
    expect(nextBudgetWarning(799, 1000, 0), 0);
    expect(nextBudgetWarning(800, 1000, 0), 80);
    expect(nextBudgetWarning(900, 1000, 80), 0);
    expect(nextBudgetWarning(1100, 1000, 0), 100);
    expect(nextBudgetWarning(1100, 1000, 100), 0);
    expect(nextBudgetWarning(1100, 0, 0), 0);
  });
  test('Budget spending excludes settlements, income, reimbursements, future and other months', () {
    expect(
      monthlySpending([
        entry(100),
        entry(200, kind: 'settlement'),
        entry(500, kind: 'income'),
        entry(400, kind: 'reimbursement'),
        entry(999, date: DateTime(2026, 9, 21)),
        entry(999, date: DateTime(2026, 8, 20)),
      ], now),
      100,
    );
  });
  test('Preferences reject invalid times and stay off by default', () {
    final p = ReminderPreferences.fromJson({
      'dailyMinute': -5,
      'weekday': 9,
      'budget': -1,
    });
    expect(p.enabled, isFalse);
    expect(p.dailyMinute, 1110);
    expect(p.weekday, 7);
    expect(p.budget, 0);
  });
  test('Permission denial schedules nothing; enable, edit and disable reconcile alarms', () async {
    final garden = GardenStore(MemoryRepository());
    final gateway = FakeGateway()..granted = false;
    final reminders = ReminderStore(
      garden,
      MemoryRepository(),
      gateway,
      clock: () => now,
    );
    addTearDown(reminders.dispose);
    await reminders.initialize();
    expect(gateway.prompts, 0);
    await reminders.update(const ReminderPreferences(enabled: true));
    expect(reminders.preferences.enabled, isFalse);
    expect(gateway.planned, isEmpty);
    gateway.granted = true;
    await reminders.update(const ReminderPreferences(enabled: true));
    expect(gateway.planned.length, 15);
    await reminders.update(reminders.preferences.update('daily', false));
    expect(gateway.planned.length, 8);
    await reminders.update(reminders.preferences.update('enabled', false));
    expect(gateway.planned, isEmpty);
  });
  test(
    'Budget history survives restarts and resets for the next month',
    () async {
      final garden = GardenStore(MemoryRepository());
      final repository = MemoryRepository();
      final gateway = FakeGateway();
      var date = now;
      var reminders = ReminderStore(
        garden,
        repository,
        gateway,
        clock: () => date,
      );
      await reminders.initialize();
      await reminders.update(
        const ReminderPreferences(enabled: true, budget: 1000),
      );
      await garden.saveEntry(entry(800));
      await reminders.refresh();
      expect(gateway.shown.length, 1);
      await reminders.refresh();
      expect(gateway.shown.length, 1);
      reminders.dispose();
      reminders = ReminderStore(garden, repository, gateway, clock: () => date);
      addTearDown(() => reminders.dispose());
      await reminders.initialize();
      expect(gateway.shown.length, 1);
      await garden.saveEntry(entry(200));
      await reminders.refresh();
      expect(gateway.shown.length, 2);
      date = DateTime(2026, 10, 20);
      await garden.saveEntry(entry(1000, date: date));
      await reminders.refresh();
      expect(gateway.shown.length, 3);
    },
  );
  test(
    'Scheduling failure is surfaced and does not block expense saves',
    () async {
      final garden = GardenStore(MemoryRepository());
      final gateway = FakeGateway()..fail = true;
      final reminders = ReminderStore(
        garden,
        MemoryRepository(),
        gateway,
        clock: () => now,
      );
      addTearDown(reminders.dispose);
      await reminders.initialize();
      await reminders.update(const ReminderPreferences(enabled: true));
      expect(reminders.error, isNotNull);
      await garden.saveEntry(entry(100));
      await reminders.refresh();
      expect(garden.data.entries.length, 1);
      gateway.fail = false;
      await reminders.refresh();
      expect(reminders.error, isNull);
      expect(gateway.planned.length, 15);
    },
  );
  for (final dark in [false, true]) {
    testWidgets(
      'Reminder preview fits a narrow ${dark ? 'dark' : 'light'} screen',
      (tester) async {
        await fonts();
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final garden = GardenStore(MemoryRepository());
        final reminders = ReminderStore(
          garden,
          MemoryRepository(),
          FakeGateway()..supported = false,
        );
        await reminders.initialize();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gardenProvider.overrideWith((ref) => garden),
              reminderProvider.overrideWith((ref) => reminders),
            ],
            child: MaterialApp(
              theme: gardenTheme(dark ? Brightness.dark : Brightness.light),
              home: const ReminderSettingsPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Kuchu puchu 🌱'), findsOneWidget);
        await capture(tester, 'reminders-${dark ? 'dark' : 'light'}');
        await tester.ensureVisible(find.text('Show another little nudge'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Show another little nudge'));
        await tester.pumpAndSettle();
        expect(find.text('Din khatm hone ko aaya 🌙'), findsOneWidget);
        await tester.drag(find.byType(ListView), const Offset(0, -1400));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('Capture opening scene ${dark ? 'dark' : 'light'}', (
      tester,
    ) async {
      await fonts();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: gardenTheme(dark ? Brightness.dark : Brightness.light),
          home: const LaunchExperience(child: Text('Ready')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));
      expect(tester.takeException(), isNull);
      await capture(tester, 'launch-${dark ? 'dark' : 'light'}');
      await tester.pumpAndSettle();
    });
  }
  testWidgets(
    'Launch animation ends within 1.5 seconds and does not replay on rebuild',
    (tester) async {
      Widget app() => MaterialApp(
        theme: gardenTheme(Brightness.light),
        home: const LaunchExperience(child: Text('Garden ready')),
      );
      await tester.pumpWidget(app());
      expect(find.text('Skip intro'), findsNothing);
      await tester.pump(const Duration(milliseconds: 1300));
      expect(
        find.text('Garden ready'),
        findsOneWidget,
      ); // Shell is built underneath the intro.
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Garden ready'), findsOneWidget);
      await tester.pumpWidget(app());
      expect(find.text('Skip intro'), findsNothing);
    },
  );
  testWidgets('Launch can be skipped and respects reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: const LaunchExperience(child: Text('Garden ready'))),
    );
    await tester.tapAt(const Offset(200, 200));
    await tester.pump();
    expect(find.text('Garden ready'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const LaunchExperience(child: Text('Reduced motion ready')),
        ),
      ),
    );
    expect(find.text('Reduced motion ready'), findsOneWidget);
    expect(find.text('Skip intro'), findsNothing);
  });
}
