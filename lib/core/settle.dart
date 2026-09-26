import 'models.dart';

class Due {
  final String id;
  final int amount;
  final DateTime date;
  const Due(this.id, this.amount, this.date);
}

Map<String, int> allocateSettlement(List<Due> dues, int amount) {
  if (amount < 0 || amount > dues.fold(0, (a, d) => a + d.amount)) {
    throw const FormatException('Amount exceeds the outstanding balance.');
  }
  final sorted = List<Due>.of(dues)
    ..sort((a, b) {
      final c = a.date.compareTo(b.date);
      return c == 0 ? a.id.compareTo(b.id) : c;
    });
  final out = <String, int>{};
  for (final d in sorted) {
    final pay = amount < d.amount ? amount : d.amount;
    if (pay > 0) out[d.id] = pay;
    amount -= pay;
  }
  return out;
}

class Transfer {
  final String fromId, toId;
  final int amount;
  const Transfer(this.fromId, this.toId, this.amount);
}

// Greedy cash flow preserves every paise; it does not promise the NP-hard global minimum transfer count.
List<Transfer> simplifyDebts(Map<String, int> net) {
  if (net.values.fold(0, (a, b) => a + b) != 0) {
    throw const FormatException('Balances must add up to zero.');
  }
  final balances = Map<String, int>.of(net);
  final result = <Transfer>[];
  while (balances.values.any((v) => v > 0)) {
    final ids = balances.keys.toList()
      ..sort((a, b) {
        final c = balances[a]!.compareTo(balances[b]!);
        return c == 0 ? a.compareTo(b) : c;
      });
    final from = ids.first, to = ids.last;
    final amount = (-balances[from]!) < balances[to]!
        ? -balances[from]!
        : balances[to]!;
    result.add(Transfer(from, to, amount));
    balances[from] = balances[from]! + amount;
    balances[to] = balances[to]! - amount;
  }
  return result;
}

Map<String, int> itemPortions(List<SplitItem> items, List<String> people) {
  final values = {for (final p in people) p: 0};
  for (final item in items.where((i) => i.kind == 'item')) {
    if (item.personIds.isEmpty) {
      throw const FormatException('Choose people for each item.');
    }
    final shares = item.personIds.length == 1
        ? [item.amount]
        : allocateSplit(
            item.amount,
            SplitMethod.equal,
            List.filled(item.personIds.length, 1),
          );
    for (var i = 0; i < shares.length; i++) {
      if (!values.containsKey(item.personIds[i])) {
        throw const FormatException('Unknown item participant.');
      }
      values[item.personIds[i]] = values[item.personIds[i]]! + shares[i];
    }
  }
  final base = values.values.toList();
  for (final item in items.where((i) => i.kind != 'item')) {
    final shares = allocateSplit(item.amount, SplitMethod.shares, base);
    for (var i = 0; i < people.length; i++) {
      values[people[i]] =
          values[people[i]]! +
          (item.kind == 'discount' ? -shares[i] : shares[i]);
    }
  }
  if (values.values.any((v) => v < 0)) {
    throw const FormatException('Discount exceeds the item subtotal.');
  }
  return values;
}
