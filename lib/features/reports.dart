import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../core/design.dart';
import '../core/models.dart';
import '../data/garden_store.dart';

String splitMessage(GardenStore store, BillSplit split) {
  final lines = split.portions.entries.map(
    (p) =>
        '${store.personName(p.key)} — ${money(p.value, store.data.currency)} · ${store.remaining(split, p.key) == 0 ? 'Paid' : '${money(store.remaining(split, p.key), store.data.currency)} pending'}',
  );
  return '🌱 Money Plant · Split summary\n\n${split.title}\n${DateFormat.yMMMMd().format(split.date)}\n'
      'Total: ${money(split.total, store.data.currency)}\nPaid by: ${store.personName(split.payerId)}\n\n${lines.join('\n')}\n\nA little clearer. All together.';
}

Rect shareOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  return box == null
      ? const Rect.fromLTWH(0, 0, 1, 1)
      : box.localToGlobal(Offset.zero) & box.size;
}

Future<void> shareSplit(
  BuildContext context,
  GardenStore store,
  BillSplit split,
) async {
  await SharePlus.instance.share(
    ShareParams(
      text: splitMessage(store, split),
      subject: '${split.title} · Money Plant',
      sharePositionOrigin: shareOrigin(context),
    ),
  );
}

Future<Uint8List> splitPdf(GardenStore store, BillSplit split) async {
  final font = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans.ttf'));
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: font),
  );
  final pending = split.portions.keys.fold(
    0,
    (a, p) => a + store.remaining(split, p),
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      footer: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Money Plant · Private by nature.',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text('${context.pageNumber} / ${context.pagesCount}'),
          ],
        ),
      ),
      build: (_) => [
        pw.Text(
          'MONEY PLANT',
          style: pw.TextStyle(
            fontSize: 12,
            letterSpacing: 3,
            color: PdfColor.fromHex('#173D31'),
          ),
        ),
        pw.SizedBox(height: 24),
        pw.Text('A clear split.', style: const pw.TextStyle(fontSize: 34)),
        pw.SizedBox(height: 12),
        pw.Text(split.title, style: const pw.TextStyle(fontSize: 20)),
        pw.Text(DateFormat.yMMMMd().format(split.date)),
        pw.SizedBox(height: 26),
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          color: PdfColor.fromHex('#EDF1DF'),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Total bill  ${money(split.total, store.data.currency)}',
                style: const pw.TextStyle(fontSize: 22),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Paid by ${store.personName(split.payerId)}'),
              pw.Text(
                'Outstanding shares  ${money(pending, store.data.currency)}',
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 24),
        pw.TableHelper.fromTextArray(
          headers: ['Person', 'Share', 'Received', 'Remaining'],
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
          ),
          cellStyle: const pw.TextStyle(fontSize: 10),
          headerDecoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#E7DDF8'),
          ),
          cellPadding: const pw.EdgeInsets.all(10),
          data: split.portions.entries
              .map(
                (p) => [
                  store.personName(p.key),
                  money(p.value, store.data.currency),
                  p.key == split.payerId
                      ? 'Bill payer'
                      : money(store.paid(split, p.key), store.data.currency),
                  money(store.remaining(split, p.key), store.data.currency),
                ],
              )
              .toList(),
        ),
        pw.SizedBox(height: 24),
        pw.Text('Payment history', style: const pw.TextStyle(fontSize: 16)),
        pw.SizedBox(height: 12),
        ...store.data.payments
            .where((p) => p.splitId == split.id)
            .map(
              (p) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  '${DateFormat.yMMMd().format(p.date)} · ${store.personName(p.personId)} · ${money(p.amount, store.data.currency)}',
                ),
              ),
            ),
      ],
    ),
  );
  return doc.save();
}

class SplitReportPage extends StatelessWidget {
  final GardenStore store;
  final BillSplit split;
  const SplitReportPage({super.key, required this.store, required this.split});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${split.title} · Report')),
    body: PdfPreview(
      build: (_) => splitPdf(store, split),
      pdfFileName: 'money-plant-split-${split.id}.pdf',
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
    ),
  );
}
