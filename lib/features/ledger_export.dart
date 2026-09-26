import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../core/design.dart';
import '../data/garden_store.dart';
import 'reports.dart';
import 'statements/statement_pdf.dart' show pdfText;

const ledgerExportRanges = [
  'Last 30 days',
  'Last 7 days',
  'This month',
  'Last month',
  'Last 3 months',
  'Custom range',
];

DateTimeRange ledgerExportRange(String choice, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final start = switch (choice) {
    'Last 7 days' => DateTime(now.year, now.month, now.day - 6),
    'Last 30 days' => DateTime(now.year, now.month, now.day - 29),
    'This month' => DateTime(now.year, now.month),
    'Last month' => DateTime(now.year, now.month - 1),
    'Last 3 months' => DateTime(now.year, now.month - 2),
    _ => throw ArgumentError.value(choice, 'choice'),
  };
  return DateTimeRange(
    start: start,
    end: choice == 'Last month' ? DateTime(now.year, now.month, 0) : today,
  );
}

Future<Uint8List> ledgerPdf(GardenStore store, DateTimeRange range) async {
  final start = DateUtils.dateOnly(range.start);
  final end = DateTime(range.end.year, range.end.month, range.end.day + 1);
  final entries =
      store.data.entries
          .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  final income = entries
      .where((e) => e.incoming)
      .fold<int>(0, (sum, e) => sum + e.amount);
  final expense = entries
      .where((e) => !e.incoming)
      .fold<int>(0, (sum, e) => sum + e.amount);
  final tokens = themePack(store.data.themePack).light;
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(
      base: pw.Font.ttf(
        await rootBundle.load('assets/fonts/Manrope-Regular.ttf'),
      ),
      bold: pw.Font.ttf(await rootBundle.load('assets/fonts/Manrope-Bold.ttf')),
      fontFallback: [
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans.ttf')),
      ],
    ),
  );
  String amount(int value) => pdfText(money(value, store.data.currency));
  final dates =
      '${DateFormat.yMMMd().format(start)} – ${DateFormat.yMMMd().format(range.end)}';
  doc.addPage(
    pw.MultiPage(
      maxPages: 1000,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 16),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Money Plant · Ledger',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(dates),
          ],
        ),
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}'),
      ),
      build: (_) => [
        pw.Text('Income: ${amount(income)}    Expenses: ${amount(expense)}'),
        pw.Text(
          'Net: ${amount(income - expense)}    Transactions: ${entries.length}',
        ),
        pw.SizedBox(height: 18),
        if (entries.isEmpty)
          pw.Text('No transactions in this date range.')
        else
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Transaction', 'Category', 'Type', 'Amount'],
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromInt(tokens.navigation.toARGB32()),
            ),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(tokens.navigationInk.toARGB32()),
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            columnWidths: {
              0: const pw.FixedColumnWidth(65),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(),
              3: const pw.FixedColumnWidth(48),
              4: const pw.FixedColumnWidth(78),
            },
            cellAlignments: {4: pw.Alignment.centerRight},
            data: entries
                .map(
                  (e) => [
                    DateFormat('yyyy-MM-dd').format(e.date),
                    pdfText(e.title),
                    pdfText(e.category),
                    e.incoming ? 'Income' : 'Expense',
                    amount(e.amount),
                  ],
                )
                .toList(),
          ),
      ],
    ),
  );
  return doc.save();
}

Future<void> exportLedgerPdf(BuildContext context, GardenStore store) async {
  final choice = await showDialog<String>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('Export ledger PDF'),
      children: ledgerExportRanges
          .map(
            (label) => SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, label),
              child: Text(label),
            ),
          )
          .toList(),
    ),
  );
  if (choice == null || !context.mounted) return;
  final range = choice == 'Custom range'
      ? await showDateRangePicker(
          context: context,
          firstDate: DateTime(1970),
          lastDate: DateTime(2100),
        )
      : ledgerExportRange(choice, DateTime.now());
  if (range == null || !context.mounted) return;
  final origin = shareOrigin(context);
  final bytes = await ledgerPdf(store, range);
  if (!context.mounted) return;
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
      fileNameOverrides: [
        'MoneyPlant-Ledger-${DateFormat('yyyy-MM-dd').format(range.start)}-${DateFormat('yyyy-MM-dd').format(range.end)}.pdf',
      ],
      sharePositionOrigin: origin,
    ),
  );
}
