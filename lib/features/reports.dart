import '../shared/pdf_skeleton.dart';
import 'statements/statement_pdf.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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

Future<Uint8List> splitPdf(GardenStore store, BillSplit split) =>
    statementPdf(store, split: split);

class SplitReportPage extends StatelessWidget {
  final GardenStore store;
  final BillSplit split;
  const SplitReportPage({super.key, required this.store, required this.split});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${split.title} · Report')),
    body: PdfPreview(
      loadingWidget: const PdfSkeleton(),
      build: (_) => splitPdf(store, split),
      pdfFileName: 'money-plant-split-${split.id}.pdf',
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
    ),
  );
}
