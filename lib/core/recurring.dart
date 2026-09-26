import 'models.dart';

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
Iterable<DateTime> occurrences(RecurringRule r, DateTime until) sync* {
  if (r.paused) return;
  final start = DateTime(r.startDate.year, r.startDate.month, r.startDate.day);
  final end = DateTime(until.year, until.month, until.day);
  if (r.frequency == 'weekly') {
    var d = start;
    final weekday = r.weekday ?? start.weekday;
    d = DateTime(d.year, d.month, d.day + (weekday - d.weekday + 7) % 7);
    while (!d.isAfter(end) && (r.endDate == null || !d.isAfter(r.endDate!))) {
      yield d;
      d = DateTime(d.year, d.month, d.day + 7);
    }
  } else {
    var year = start.year, month = start.month;
    while (true) {
      final last = DateTime(year, month + 1, 0).day;
      final wanted = r.dayOfMonth ?? start.day;
      final d = DateTime(year, month, wanted > last ? last : wanted);
      if (d.isAfter(end) || r.endDate != null && d.isAfter(r.endDate!)) break;
      if (!d.isBefore(start)) yield d;
      if (r.frequency == 'yearly') {
        year++;
      } else {
        month++;
        if (month > 12) {
          month = 1;
          year++;
        }
      }
    }
  }
}
