import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_plant/app.dart';
import 'package:money_plant/core/design.dart';
import 'package:money_plant/data/garden_store.dart';

import 'garden_store_test.dart' show MemoryRepository;

void main() {
  test('all color literals live in theme definitions', () {
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll('\\', '/');
      if (!path.endsWith('.dart') || path.contains('/core/theme/')) continue;
      expect(
        RegExp(r'Color\s*\(\s*0x|Palette\.|Colors\.')
            .hasMatch(file.readAsStringSync()),
        isFalse,
        reason: path,
      );
    }
  });
  for (final brightness in Brightness.values) {
    test('Garden semantic pairs have readable contrast at $brightness', () {
      final t = gardenPack.tokens(brightness);
      for (final pair in [
        (t.ink, t.canvas),
        (t.ink, t.surface),
        (t.inkMuted, t.surface),
        (t.onBrand, t.brand),
        (t.onReceive, t.receive),
        (t.onOwe, t.owe),
      ]) {
        final a = pair.$1.computeLuminance();
        final b = pair.$2.computeLuminance();
        expect(
          ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05),
          greaterThanOrEqualTo(4.5),
        );
      }
      expect(
        buildTheme(gardenPack, brightness).extension<GardenTokens>(),
        same(t),
      );
    });
  }
  test('theme extensions interpolate and copy semantic colors', () {
    final a = gardenPack.light;
    final b = gardenPack.dark;
    expect(a.copyWith(brand: b.brand).brand, b.brand);
    expect(a.lerp(b, 0).canvas, a.canvas);
    expect(a.lerp(b, 1).canvas, b.canvas);
    expect(a.lerp(b, .5).canvas, Color.lerp(a.canvas, b.canvas, .5));
  });
  testWidgets('v1 backup opens the extracted ledger and splits screens', (
    tester,
  ) async {
    for (final family in ['Outfit', 'Manrope', 'NotoSans']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
    final repository = MemoryRepository()
      ..value = File('test/fixtures/backup_v1.json').readAsStringSync();
    final store = GardenStore(repository);
    await store.load();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gardenProvider.overrideWith((ref) => store)],
        child: const MoneyPlantApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ledger').last);
    await tester.pumpAndSettle();
    expect(find.text('Coffee'), findsOneWidget);
    await tester.tap(find.text('Splits').last);
    await tester.pumpAndSettle();
    expect(find.text('Dinner'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
