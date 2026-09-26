import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/upi.dart';
import '../../data/garden_store.dart';
import '../reports.dart';

Future<void> exportCsv(BuildContext context, GardenStore store) async {
  final choice = await showDialog<String>(
    context: context,
    builder: (c) => SimpleDialog(
      title: const Text('Export range'),
      children: ['This month', 'Last month', 'Custom', 'All']
          .map(
            (v) => SimpleDialogOption(
              onPressed: () => Navigator.pop(c, v),
              child: Text(v),
            ),
          )
          .toList(),
    ),
  );
  if (choice == null || !context.mounted) return;
  DateTime? start, end;
  final now = DateTime.now();
  if (choice == 'This month') {
    start = DateTime(now.year, now.month);
    end = DateTime(now.year, now.month + 1);
  }
  if (choice == 'Last month') {
    start = DateTime(now.year, now.month - 1);
    end = DateTime(now.year, now.month);
  }
  if (choice == 'Custom') {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (range == null) return;
    start = range.start;
    end = range.end.add(const Duration(days: 1));
  }
  String safe(String text) =>
      RegExp(r'^[=+@\-\t\r]').hasMatch(text) ? "'$text" : text;
  final rows = [
    ['Date', 'Title', 'Category', 'Type', 'Amount', 'Notes', 'Split', 'Goal'],
    ...store.data.entries
        .where(
          (e) =>
              (start == null || !e.date.isBefore(start)) &&
              (end == null || e.date.isBefore(end)),
        )
        .map(
          (e) => [
            e.date.toIso8601String().split('T').first,
            safe(e.title),
            safe(e.category),
            e.kind,
            minorDecimal(e.amount),
            safe(e.notes),
            e.splitId ?? '',
            e.goalId ?? '',
          ],
        ),
  ];
  if (!context.mounted) return;
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          utf8.encode(Csv(addBom: true).encode(rows)),
          mimeType: 'text/csv',
        ),
      ],
      fileNameOverrides: [
        'money-plant-${choice.toLowerCase().replaceAll(' ', '-')}.csv',
      ],
      sharePositionOrigin: shareOrigin(context),
    ),
  );
}
