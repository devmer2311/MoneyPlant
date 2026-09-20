import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_plant/app.dart';
import 'package:money_plant/core/models.dart';
import 'package:money_plant/data/garden_store.dart';

import 'garden_store_test.dart' show MemoryRepository;

void main() {
  Future<GardenStore> launch(
    WidgetTester tester,
    Size size, {
    bool dark = false,
    double textScale = 1,
    bool populated = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = GardenStore(MemoryRepository());
    await store.change((d) => d.theme = dark ? 'dark' : 'light');
    if (populated) {
      final now = DateTime.now();
      await store.saveEntry(
        Entry(
          id: 'salary',
          title: 'Payday, hey!',
          amount: 5800000,
          kind: 'income',
          category: 'Salary',
          date: now,
          createdAt: now,
        ),
      );
      await store.saveEntry(
        Entry(
          id: 'coffee',
          title: 'The daily coffee',
          amount: 28000,
          category: 'Food',
          date: now,
          createdAt: now,
        ),
      );
      await store.saveEntry(
        Entry(
          id: 'groceries',
          title: 'A fridge full of good',
          amount: 164000,
          category: 'Shopping',
          date: now,
          createdAt: now,
        ),
      );
      await store.saveGoal(
        Goal(
          id: 'goal',
          title: 'A little getaway',
          target: 3000000,
          date: now.add(const Duration(days: 90)),
        ),
      );
      await store.contribute('goal', 1250000);
      await store.saveTask(
        GardenTask(
          id: 'task',
          title: 'Pay the electricity bill',
          date: now.add(const Duration(days: 1)),
        ),
      );
    }
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final family in ['Outfit', 'Manrope', 'NotoSans']) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$family.ttf'));
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gardenProvider.overrideWith((ref) => store)],
        child: const MoneyPlantApp(),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  for (final size in [
    const Size(320, 800),
    const Size(390, 844),
    const Size(1440, 1080),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('All tabs render at $size, dark=$dark', (tester) async {
        await launch(tester, size, dark: dark);
        expect(tester.takeException(), isNull);
        for (final label in ['Insights', 'Tasks', 'Splits', 'Ledger']) {
          await tester.tap(find.text(label).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: label);
        }
      });
    }
  }
  testWidgets('Create transaction, edit amount, delete and undo through UI', (
    tester,
  ) async {
    final store = await launch(tester, const Size(390, 844));
    await tester.ensureVisible(find.text('Income').first);
    await tester.tap(find.text('Income').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '50000');
    await tester.enterText(find.byType(TextFormField).at(1), 'Salary');
    await tester.ensureVisible(find.text('Save income  ↗'));
    await tester.tap(find.text('Save income  ↗'));
    await tester.pumpAndSettle();
    expect(store.balance, 5000000);
    await tester.tap(find.text('Ledger').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salary').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit entry'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '52000');
    await tester.ensureVisible(find.text('Save income  ↗'));
    await tester.tap(find.text('Save income  ↗'));
    await tester.pumpAndSettle();
    expect(store.balance, 5200000);
    expect(store.data.entries.length, 1);
    await tester.tap(find.text('Salary').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(store.balance, 0);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(store.balance, 5200000);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Theme toggle persists', (tester) async {
    final store = await launch(tester, const Size(390, 844));
    await tester.tap(find.byTooltip('Switch to dark theme'));
    await tester.pumpAndSettle();
    expect(store.data.theme, 'dark');
    final reopened = GardenStore(store.repository);
    await reopened.load();
    expect(reopened.data.theme, 'dark');
  });
  testWidgets(
    'Backup notice is above the settings sheet and About shows credit',
    (tester) async {
      var copied = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') copied = true;
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await launch(tester, const Size(390, 844));
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Copy backup JSON'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy backup JSON'));
      await tester.pumpAndSettle();
      expect(copied, isTrue);
      expect(
        find.text('Backup copied. Store it somewhere safe.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dismiss_notice')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('dismiss_notice')));
      await tester.pumpAndSettle();
      expect(
        find.text('Backup copied. Store it somewhere safe.'),
        findsNothing,
      );
      await tester.ensureVisible(
        find.text('Built with 💖 in India by DJ Khatri'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Built with 💖 in India by DJ Khatri').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Create and partially settle a split through the UI', (
    tester,
  ) async {
    final store = await launch(tester, const Size(390, 844));
    await tester.tap(find.text('Splits').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Split a bill').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '100');
    await tester.enterText(find.byType(TextFormField).at(1), 'Dinner');
    final personField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == 'Add a person',
    );
    await tester.ensureVisible(personField);
    await tester.enterText(personField, 'Alex');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Add person'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add person'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save split  ↗'));
    await tester.tap(find.text('Save split  ↗'));
    await tester.pumpAndSettle();
    expect(store.receivable, 5000);
    expect(store.balance, -10000);
    await tester.ensureVisible(find.text('Settle ↗'));
    await tester.tap(find.text('Settle ↗'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '10');
    await tester.tap(find.text('Confirm  ↗'));
    await tester.pumpAndSettle();
    expect(store.receivable, 4000);
    expect(store.balance, -9000);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Populated home and goals fit a small phone', (tester) async {
    await launch(tester, const Size(320, 800), populated: true);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Add savings ↗'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  for (final dark in [false, true]) {
    testWidgets(
      'Capture ${dark ? 'dark' : 'light'} layout with test fixtures',
      (tester) async {
        await launch(
          tester,
          const Size(1440, 1180),
          dark: dark,
          populated: true,
        );
        expect(tester.takeException(), isNull);
        final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).first,
        );
        boundary.markNeedsPaint();
        await tester.pump();
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('artifacts').create(recursive: true);
          await File('artifacts/${dark ? 'dark' : 'light'}-desktop.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
        });
      },
    );
  }
}
