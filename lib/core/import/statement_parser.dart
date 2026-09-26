import 'fingerprint.dart';

import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models.dart';

class StatementRow {
  final DateTime date;
  final int amount;
  final bool credit;
  final String narration, ref;
  String title, category;
  String payerId = 'self';
  SplitMethod method = SplitMethod.equal;
  Map<String, int> weights = {};
  bool selected = true;
  String? splitId, personId;
  final Set<String> people = {};
  bool duplicate = false, possibleDuplicate = false;
  StatementRow({
    required this.date,
    required this.amount,
    required this.credit,
    required this.narration,
    required this.ref,
    required this.title,
    required this.category,
  });
}

String cleanNarration(String raw) {
  var text = raw.trim();
  final upi = RegExp(
    r'UPI[/\-](?:DR|CR)[/\-][^/\-]+[/\-]([^/\-]+)',
    caseSensitive: false,
  ).firstMatch(text);
  final bank = RegExp(
    r'(?:NEFT|IMPS)[/\-][^/\-]+[/\-]([^/\-]+)',
    caseSensitive: false,
  ).firstMatch(text);
  text = upi?.group(1) ?? bank?.group(1) ?? text;
  text = text.replaceAll(RegExp(r'[_]+'), ' ');
  return text
      .split(RegExp(r'\s+'))
      .map(
        (w) =>
            w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase(),
      )
      .join(' ');
}

String suggestCategory(String text, bool credit) {
  final value = text.toLowerCase();
  for (final e in {
    'Food': ['swiggy', 'zomato', 'restaurant', 'cafe'],
    'Transport': ['uber', 'ola', 'rapido', 'irctc', 'fuel'],
    'Shopping': ['amazon', 'flipkart', 'myntra'],
    'Bills': ['airtel', 'jio', 'electricity', 'bescom'],
    'Entertainment': ['netflix', 'spotify'],
    'Salary': ['salary', 'payroll'],
  }.entries) {
    if (e.value.any(value.contains)) return e.key;
  }
  return credit ? 'Other income' : 'Other';
}

DateTime? statementDate(String raw) {
  for (final pattern in [
    'dd/MM/yyyy',
    'dd-MM-yyyy',
    'dd/MM/yy',
    'dd MMM yyyy',
    'yyyy-MM-dd',
  ]) {
    try {
      return DateFormat(pattern).parseStrict(raw.trim());
    } catch (_) {}
  }
  return null;
}

int bankAmount(String raw) {
  final value = raw.replaceAll(RegExp(r'dr|cr', caseSensitive: false), '');
  return parseMoney(value.replaceAll(RegExp(r'[₹,()\s+-]'), '').trim());
}

Future<List<List<String>>> statementCells(
  Uint8List bytes,
  String extension, {
  String? password,
}) async {
  if (bytes.length > 25 * 1024 * 1024) {
    throw const FormatException('Choose a statement smaller than 25 MB.');
  }
  if (extension == 'csv') {
    return Csv(dynamicTyping: false)
        .decode(utf8.decode(bytes).replaceFirst('\uFEFF', ''))
        .map((r) => r.map((c) => c.toString()).toList())
        .toList();
  }
  if (extension == 'xlsx') {
    final book = xlsx.Excel.decodeBytes(bytes);
    return book.tables.values
        .expand(
          (t) => t.rows.map(
            (row) => row.map((c) {
              final v = c?.value;
              if (v is xlsx.DateCellValue) {
                return '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
              }
              return v?.toString() ?? '';
            }).toList(),
          ),
        )
        .toList();
  }
  if (extension == 'pdf') {
    final doc = PdfDocument(inputBytes: bytes, password: password);
    try {
      final lines = PdfTextExtractor(doc).extractTextLines();
      if (lines.isEmpty) {
        throw const FormatException(
          'This PDF looks scanned. Please download the text statement or CSV from your bank app.',
        );
      }
      // Keep the x positions so an empty debit cell never shifts a credit into it.
      final physical = <List<TextWord>>[];
      for (var page = 0; page < doc.pages.count; page++) {
        final words =
            lines
                .where((l) => l.pageIndex == page)
                .expand((l) => l.wordCollection)
                .toList()
              ..sort((a, b) => a.bounds.top.compareTo(b.bounds.top));
        final pageRows = <List<TextWord>>[];
        for (final word in words) {
          final row = pageRows
              .where((r) => (r.first.bounds.top - word.bounds.top).abs() < 3)
              .firstOrNull;
          if (row == null) {
            pageRows.add([word]);
          } else {
            row.add(word);
          }
        }
        for (final row in pageRows) {
          row.sort((a, b) => a.bounds.left.compareTo(b.bounds.left));
          physical.add(row);
        }
      }
      List<(String, double)> columns(List<TextWord> words) {
        final result = <(String, double)>[];
        double? right;
        for (final w in words) {
          if (right == null || w.bounds.left - right > 12) {
            result.add((w.text, w.bounds.left));
          } else {
            final last = result.removeLast();
            result.add(('${last.$1} ${w.text}', last.$2));
          }
          right = w.bounds.right;
        }
        return result;
      }

      var best = -1;
      List<(String, double)> headings = [];
      for (var i = 0; i < physical.length; i++) {
        final candidate = columns(physical[i]);
        final detected = detectMapping([candidate.map((v) => v.$1).toList()]);
        if (detected.$2 != null) {
          best = i;
          headings = candidate;
          break;
        }
      }
      if (best < 0) {
        throw const FormatException(
          'The PDF table columns could not be identified safely. Please use CSV or XLSX.',
        );
      }
      final result = <List<String>>[headings.map((h) => h.$1).toList()];
      for (final words in physical.skip(best + 1)) {
        final row = List.filled(headings.length, '');
        for (final word in words) {
          var index = 0;
          for (var i = 1; i < headings.length; i++) {
            if (word.bounds.left >= headings[i].$2 - 8) index = i;
          }
          row[index] += '${row[index].isEmpty ? '' : ' '}${word.text}';
        }
        result.add(row);
      }
      return result;
    } finally {
      doc.dispose();
    }
  }
  throw const FormatException(
    'Please export as CSV, XLSX or a text PDF from your bank app.',
  );
}

const aliases = {
  'date': ['date', 'txn date', 'transaction date', 'value date'],
  'description': [
    'narration',
    'description',
    'particulars',
    'remarks',
    'details',
  ],
  'debit': ['withdrawal', 'debit', 'dr', 'withdrawal amt', 'withdrawal amt.'],
  'credit': ['deposit', 'credit', 'cr', 'deposit amt', 'deposit amt.'],
  'amount': ['amount'],
  'type': ['dr/cr', 'type'],
  'reference': ['ref', 'chq', 'cheque', 'utr', 'reference'],
};
String headerKey(List<String> row) =>
    statementFingerprint(row.join('|').toLowerCase());
(int, ColumnMapping?) detectMapping(List<List<String>> cells) {
  var best = -1, score = 0;
  Map<String, int> found = {};
  for (var i = 0; i < cells.length && i < 40; i++) {
    final map = <String, int>{};
    for (var c = 0; c < cells[i].length; c++) {
      final value = cells[i][c].trim().toLowerCase();
      for (final e in aliases.entries) {
        if (e.value.contains(value)) map[e.key] = c;
      }
    }
    if (map.length > score) {
      score = map.length;
      best = i;
      found = map;
    }
  }
  if (!found.containsKey('date') ||
      !found.containsKey('description') ||
      !(found.containsKey('debit') ||
          found.containsKey('credit') ||
          found.containsKey('amount') && found.containsKey('type'))) {
    return (best < 0 ? 0 : best, null);
  }
  return (best, ColumnMapping.fromJson(found));
}

List<StatementRow> parseStatement(
  List<List<String>> cells,
  int header,
  ColumnMapping mapping,
) {
  final rows = <StatementRow>[];
  final seen = <String>{};
  for (final row in cells.skip(header + 1)) {
    String at(int? index) =>
        index == null || index >= row.length ? '' : row[index].trim();
    final date = statementDate(at(mapping.date));
    if (date == null) continue;
    final narration = at(mapping.description);
    if (RegExp(
      r'opening balance|closing balance|brought forward',
      caseSensitive: false,
    ).hasMatch(narration)) {
      continue;
    }
    var credit = false;
    String amount = '';
    if (mapping.amount != null) {
      amount = at(mapping.amount);
      credit = RegExp(
        r'cr|credit',
        caseSensitive: false,
      ).hasMatch(at(mapping.type));
    } else {
      final incoming = at(mapping.credit);
      if (incoming.isNotEmpty &&
          !RegExp(r'^0([.,]0+)?$|^-$').hasMatch(incoming)) {
        amount = incoming;
        credit = true;
      } else {
        amount = at(mapping.debit);
      }
    }
    if (amount.isEmpty || amount == '-') continue;
    final minor = bankAmount(amount);
    final normalized = narration
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final ref = statementFingerprint(
      '${date.toIso8601String()}|$minor|$credit|$normalized|${at(mapping.reference)}',
    );
    if (!seen.add(ref)) continue;
    final title = cleanNarration(narration);
    var category = suggestCategory(narration, credit);
    for (final rule in mapping.categoryRules.entries) {
      if (normalized.contains(rule.key.toLowerCase())) category = rule.value;
    }
    rows.add(
      StatementRow(
        date: date,
        amount: minor,
        credit: credit,
        narration: narration,
        ref: ref,
        title: title,
        category: category,
      ),
    );
  }
  if (rows.isEmpty) {
    throw const FormatException(
      'No transactions found. Check your column mapping.',
    );
  }
  return rows;
}
