import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf;
import 'package:money_plant/core/design.dart';
import 'package:money_plant/core/models.dart';
import 'package:money_plant/core/theme/depth_colors.dart';
import 'package:money_plant/data/garden_store.dart';
import 'package:money_plant/features/ledger_export.dart';
import 'package:money_plant/features/people/person_page.dart';

import 'garden_store_test.dart' show MemoryRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('ledger periods cross years and leap days with inclusive ends', () {
    final now = DateTime(2024, 3, 1, 15);
    expect(ledgerExportRange('Last 7 days', now).start, DateTime(2024, 2, 24));
    expect(ledgerExportRange('Last 30 days', now).start, DateTime(2024, 2, 1));
    expect(ledgerExportRange('Last month', now).end, DateTime(2024, 2, 29));
    expect(ledgerExportRange('This month', now).start, DateTime(2024, 3));
    expect(
      ledgerExportRange('Last 3 months', DateTime(2024, 1, 8)).start,
      DateTime(2023, 11),
    );
  });
  test(
    'ledger PDF includes both date boundaries and excludes outside entries',
    () async {
      final store = GardenStore(MemoryRepository());
      for (final row in [
        ('Before', DateTime(2024, 2, 28, 23, 59)),
        ('First boundary', DateTime(2024, 2, 29)),
        ('Last boundary', DateTime(2024, 3, 1, 23, 59)),
        ('After', DateTime(2024, 3, 2)),
      ]) {
        await store.saveEntry(
          Entry(
            id: row.$1,
            title: row.$1,
            amount: 12500,
            date: row.$2,
            createdAt: row.$2,
          ),
        );
      }
      final document = pdf.PdfDocument(
        inputBytes: await ledgerPdf(
          store,
          DateTimeRange(
            start: DateTime(2024, 2, 29),
            end: DateTime(2024, 3, 1),
          ),
        ),
      );
      final text = pdf.PdfTextExtractor(document)
          .extractText()
          .replaceAll(RegExp(r'\s+'), ' ');
      expect(text, contains('First boundary'));
      expect(text, contains('Last boundary'));
      expect(text, isNot(contains('Before')));
      expect(text, isNot(contains('After')));
      expect(text, contains('Transactions: 2'));
      document.dispose();
      final empty = pdf.PdfDocument(
        inputBytes: await ledgerPdf(
          store,
          DateTimeRange(start: DateTime(2020), end: DateTime(2020)),
        ),
      );
      expect(
        pdf.PdfTextExtractor(empty)
            .extractText()
            .replaceAll(RegExp(r'\s+'), ' '),
        contains('No transactions'),
      );
      empty.dispose();
    },
  );
  for (final pack in themePacks) {
    for (final brightness in Brightness.values) {
      test(
        '${pack.id} $brightness navigation and highlights stay readable',
        () {
          final t = pack.tokens(brightness);
          for (final pair in [
            (t.navigationInk, t.navigation),
            (t.ink, t.selectedSurface),
            (t.ink, t.oweSurface),
          ]) {
            expect(contrastRatio(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
          }
          for (final tint in [
            t.navigation,
            t.receive,
            t.owe,
            t.brand,
            t.surfaceAlt,
          ]) {
            final shades = DepthShades.forTint(tint, t);
            for (final stop in shades.stops) {
              expect(
                contrastRatio(shades.foreground, stop),
                greaterThanOrEqualTo(4.5),
              );
            }
          }
        },
      );
    }
  }
  testWidgets(
    'PDF nudge offers unchanged message separately without attachment',
    (tester) async {
      final store = GardenStore(MemoryRepository());
      final shares = <ShareParams>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gardenProvider.overrideWith((ref) => store),
            nudgeShareProvider.overrideWithValue((params) async {
              shares.add(params);
              return const ShareResult('test', ShareResultStatus.success);
            }),
          ],
          child: MaterialApp(
            theme: buildTheme(gardenPack, Brightness.light),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: NudgeSheet(
                  person: Person(id: 'p', name: 'Pat'),
                  amount: 12000,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextField),
        'Please send the balance today.',
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.text('Share nudge'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 700));
      });
      await tester.pumpAndSettle();
      expect(shares, hasLength(1));
      expect(shares.first.files, hasLength(1));
      expect(shares.first.text, 'Please send the balance today.');
      await tester.enterText(find.byType(TextField), 'Changed draft');
      await tester.tap(find.text('Share message separately'));
      await tester.pumpAndSettle();
      expect(shares, hasLength(2));
      expect(shares.last.files, isNull);
      expect(shares.last.text, 'Please send the balance today.');
    },
  );
}
