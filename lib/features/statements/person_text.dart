import '../../core/design.dart';
import '../../core/models.dart';
import '../../core/upi.dart';
import '../../data/garden_store.dart';

String personMessage(
  GardenStore store,
  Person person, {
  DateTime? start,
  DateTime? end,
}) {
  final rows = store.data.splits.where(
    (s) =>
        s.portions.containsKey(person.id) &&
        (start == null || !s.date.isBefore(start)) &&
        (end == null || s.date.isBefore(end.add(const Duration(days: 1)))),
  );
  final lines = rows.map((s) {
    final due = s.payerId == 'self'
        ? store.remaining(s, person.id)
        : s.payerId == person.id
        ? -store.remaining(s, 'self')
        : 0;
    return '*${s.title}* · ${s.date.toIso8601String().split('T').first}\nShare ${money(s.portions[person.id]!, store.data.currency)} · ${due == 0
        ? '✓ Paid'
        : due > 0
        ? 'Due ${money(due, store.data.currency)}'
        : 'I owe ${money(-due, store.data.currency)}'}';
  });
  final net = store.personNet(person.id);
  final link = paymentLink(store.data, net);
  return '🌱 *Money Plant · Statement for ${person.name}*\n\n${lines.join('\n\n')}\n\nOpen money tasks: ${money(store.taskNet(person.id), store.data.currency)}\n*Current net: ${net == 0
      ? 'All square'
      : net > 0
      ? 'You owe ${money(net, store.data.currency)}'
      : 'I owe ${money(-net, store.data.currency)}'}*${link == null ? '' : '\n\nUPI: ${store.data.profile.upiId}\n$link'}\nThank you! A little clearer. All together. 💚';
}
