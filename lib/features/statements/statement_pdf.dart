import '../../core/settle.dart';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/design.dart';
import '../../core/upi.dart';
import '../../core/models.dart';
import '../../data/garden_store.dart';

final _statementCounters = <String, int>{};
String pdfText(String text) => String.fromCharCodes(
  text.runes.where((r) => r < 0x10000 && !(r >= 0x2600 && r <= 0x27ff)),
);
Future<Uint8List> statementPdf(
  GardenStore store, {
  Person? person,
  BillSplit? split,
  Group? group,
  DateTime? start,
  DateTime? end,
}) async {
  final pack = themePack(store.data.themePack), d = store.data;
  final t = pack.light;
  PdfColor color(dynamic c) => PdfColor.fromInt(c.toARGB32());
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Manrope-Regular.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Manrope-Bold.ttf'),
  );
  final display = pw.Font.ttf(
    await rootBundle.load('assets/fonts/${t.displayFont}-Bold.ttf'),
  );
  final fallback = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans.ttf'),
  );
  final leaf = await rootBundle.loadString('assets/pdf/leaf.svg');
  final logo = await rootBundle.loadString('assets/pdf/logo.svg');
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      fontFallback: [fallback],
    ),
  );
  final rows = split != null
      ? [split]
      : d.splits
            .where(
              (s) => person != null
                  ? s.portions.containsKey(person.id)
                  : s.groupId == group?.id,
            )
            .where(
              (s) =>
                  (start == null || !s.date.isBefore(start)) &&
                  (end == null ||
                      s.date.isBefore(end.add(const Duration(days: 1)))),
            )
            .toList();
  final title = person?.name ?? split?.title ?? group?.name ?? 'Statement';
  final now = DateTime.now();
  final identifier = person?.id ?? split?.id ?? group?.id ?? 'statement';
  final counter = _statementCounters.update(
    identifier,
    (n) => n + 1,
    ifAbsent: () => 1,
  );
  final code =
      'MP-${(now.year % 100).toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}-${title.replaceAll(RegExp('[^a-zA-Z]'), '').toUpperCase().padRight(3, 'X').substring(0, 3)}-${counter.toString().padLeft(2, '0')}';

  final net = person != null
      ? store.personNet(person.id)
      : split != null
      ? (split.payerId == 'self'
            ? split.portions.keys.fold(
                0,
                (a, p) => a + store.remaining(split, p),
              )
            : -store.remaining(split, 'self'))
      : store.groupBalances(group!.id)['self'] ?? 0;
  final link = paymentLink(d, net, pdf: true);
  final totalShared = rows.fold<int>(
    0,
    (sum, s) => sum + (person == null ? s.total : s.portions[person.id] ?? 0),
  );
  final received = d.payments
      .where(
        (p) =>
            rows.any((s) => s.id == p.splitId && s.payerId == 'self') &&
            (person == null || p.personId == person.id),
      )
      .fold<int>(0, (sum, p) => sum + p.amount);
  final pending = rows
      .where((s) => s.payerId == 'self')
      .fold<int>(
        0,
        (sum, s) =>
            sum +
            (person == null
                ? s.portions.keys.fold<int>(
                    0,
                    (n, id) => n + store.remaining(s, id),
                  )
                : store.remaining(s, person.id)),
      );
  pw.Widget metric(String label, int value, {bool filled = false}) =>
      pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 6),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: color(filled ? t.brand : t.surfaceAlt),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: 8,
                  color: color(filled ? t.onBrand : t.inkMuted),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                money(value, d.currency),
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 11,
                  color: color(filled ? t.onBrand : t.ink),
                ),
              ),
            ],
          ),
        ),
      );
  final table = <List<String>>[];
  if (split != null) {
    for (final p in split.portions.entries) {
      table.add([
        store.personName(p.key),
        money(p.value, d.currency),
        money(
          p.key == split.payerId ? p.value : store.paid(split, p.key),
          d.currency,
        ),
        money(store.remaining(split, p.key), d.currency),
      ]);
    }
  } else {
    for (final s in rows) {
      final due = person != null
          ? (s.payerId == 'self'
                ? store.remaining(s, person.id)
                : s.payerId == person.id
                ? -store.remaining(s, 'self')
                : 0)
          : s.total;
      table.add([
        s.date.toIso8601String().split('T').first,
        pdfText(s.title),
        store.personName(s.payerId),
        if (person != null) money(s.portions[person.id] ?? 0, d.currency),
        if (person != null)
          money(
            s.payerId == 'self'
                ? store.paid(s, person.id)
                : store.paid(s, 'self'),
            d.currency,
          ),
        money(due, d.currency),
        if (person != null)
          due == 0
              ? 'Paid'
              : due < 0
              ? 'You owe'
              : store.paid(s, person.id) > 0
              ? 'Partial'
              : 'Pending',
      ]);
    }
  }
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      maxPages: 100,
      header: (c) => pw.Container(
        padding: const pw.EdgeInsets.all(18),
        color: color(t.hero),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.SvgImage(svg: logo, width: 25, height: 25),
            pw.Text(
              'money plant.',
              style: pw.TextStyle(
                font: display,
                fontSize: 23,
                color: color(t.heroInk),
              ),
            ),
            pw.Text(
              'STATEMENT $code\n${DateTime.now().toIso8601String().split('T').first}',
              style: pw.TextStyle(fontSize: 9, color: color(t.heroInk)),
            ),
          ],
        ),
      ),
      footer: (c) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 16),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Money Plant | Private by nature | Made on-device',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'Page ${c.pageNumber}/${c.pagesCount}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      ),
      build: (c) => [
        pw.SizedBox(height: 20),
        pw.Text(
          pdfText(title),
          style: pw.TextStyle(font: display, fontSize: 26),
        ),
        pw.Text(
          'From ${pdfText(d.profile.displayName)}${d.currency == 'INR' ? ' | ${d.profile.upiId}' : ''}',
        ),
        pw.SizedBox(height: 18),
        pw.Row(
          children: [
            metric('Total shared', totalShared),
            metric('Received', received),
            metric('Pending', pending),
            metric('Current net', net, filled: true),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(18),
          decoration: pw.BoxDecoration(
            color: color(net >= 0 ? t.receive : t.owe),
            borderRadius: pw.BorderRadius.circular(14),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      net == 0
                          ? 'ALL SQUARE'
                          : net > 0
                          ? 'AMOUNT DUE'
                          : 'YOU OWE',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: color(net >= 0 ? t.onReceive : t.onOwe),
                      ),
                    ),
                    pw.Text(
                      money(net.abs(), d.currency),
                      style: pw.TextStyle(
                        font: display,
                        fontSize: 28,
                        color: color(net >= 0 ? t.onReceive : t.onOwe),
                      ),
                    ),
                    pw.Text(
                      '${rows.length} shared bills | Friendship: 100%',
                      style: pw.TextStyle(
                        color: color(net >= 0 ? t.onReceive : t.onOwe),
                      ),
                    ),
                  ],
                ),
              ),
              if (link != null)
                pw.Container(
                  color: color(t.highlight),
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: link,
                    width: 90,
                    height: 90,
                  ),
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headers: split != null
              ? ['Person', 'Share', 'Paid', 'Due']
              : person != null
              ? ['Date', 'Split', 'Paid by', 'Share', 'Paid', 'Due', 'Status']
              : ['Date', 'Split', 'Paid by', 'Total'],
          data: table,
          headerDecoration: pw.BoxDecoration(color: color(t.brand)),
          headerStyle: pw.TextStyle(
            color: color(t.onBrand),
            font: bold,
            fontSize: 8,
          ),
          oddRowDecoration: pw.BoxDecoration(color: color(t.surfaceAlt)),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellPadding: const pw.EdgeInsets.all(8),
        ),
        if (split != null && split.items.isNotEmpty) ...[
          pw.SizedBox(height: 18),
          pw.Text('ITEMS'),
          ...split.items.map(
            (i) => pw.Text(
              '${pdfText(i.name)} | ${i.kind} | ${money(i.amount, d.currency)}',
            ),
          ),
        ],
        if (group != null) ...[
          pw.SizedBox(height: 18),
          pw.Text('MEMBER BALANCES'),
          ...simplifyDebts(store.groupBalances(group.id)).map((transfer) {
            final transferLink = transfer.toId == 'self'
                ? paymentLink(d, transfer.amount, pdf: true)
                : null;
            return pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      '${store.personName(transfer.fromId)} to ${store.personName(transfer.toId)}: ${money(transfer.amount, d.currency)}',
                    ),
                  ),
                  if (transferLink != null)
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: transferLink,
                      width: 65,
                      height: 65,
                    ),
                ],
              ),
            );
          }),
          ...store
              .groupBalances(group.id)
              .entries
              .map(
                (e) => pw.Text(
                  '${store.personName(e.key)}: ${money(e.value, d.currency)}',
                ),
              ),
        ],
        pw.SizedBox(height: 18),
        pw.Text(
          'PAYMENT TIMELINE',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        ...d.payments
            .where(
              (p) =>
                  rows.any((s) => s.id == p.splitId) &&
                  (person == null ||
                      p.personId == person.id ||
                      p.personId == 'self'),
            )
            .map(
              (p) => pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6),
                child: pw.Text(
                  '${p.date.toIso8601String().split('T').first} | ${store.personName(p.personId)} | ${money(p.amount, d.currency)}',
                ),
              ),
            ),
        if (person != null) ...[
          pw.SizedBox(height: 18),
          pw.Text('OPEN MONEY TASKS'),
          ...d.tasks
              .where((t) => !t.completed && t.personId == person.id)
              .map(
                (t) => pw.Text(
                  '${pdfText(t.title)} | ${t.direction} | ${money(t.amount, d.currency)}',
                ),
              ),
        ],
        pw.SizedBox(height: 24),
        pw.Row(
          children: [
            pw.SvgImage(svg: leaf, width: 24, height: 24),
            pw.SizedBox(width: 12),
            pw.Text('Thank you for keeping it fair and friendly.'),
          ],
        ),
      ],
    ),
  );
  return doc.save();
}
