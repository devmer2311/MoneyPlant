import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/upi.dart';
import '../../core/import/statement_parser.dart';

class ImportSplitOptions extends StatefulWidget {
  final StatementRow row;
  final List<Person> people;
  const ImportSplitOptions({
    super.key,
    required this.row,
    required this.people,
  });
  @override
  State<ImportSplitOptions> createState() => _ImportSplitOptionsState();
}

class _ImportSplitOptionsState extends State<ImportSplitOptions> {
  late SplitMethod method = widget.row.method;
  late String payer = widget.row.people.contains(widget.row.payerId)
      ? widget.row.payerId
      : 'self';
  late final ids = ['self', ...widget.row.people];
  final weights = <String, TextEditingController>{};
  String error = '';
  @override
  void initState() {
    super.initState();
    reset();
  }

  void reset() {
    for (final c in weights.values) {
      c.dispose();
    }
    weights.clear();
    final initial = allocateSplit(
      method == SplitMethod.percentage ? 10000 : widget.row.amount,
      SplitMethod.equal,
      List.filled(ids.length, 1),
    );
    for (var i = 0; i < ids.length; i++) {
      weights[ids[i]] = TextEditingController(
        text: method == SplitMethod.custom || method == SplitMethod.percentage
            ? minorDecimal(initial[i])
            : '1',
      );
    }
  }

  @override
  void dispose() {
    for (final c in weights.values) {
      c.dispose();
    }
    super.dispose();
  }

  String name(String id) =>
      id == 'self' ? 'You' : widget.people.firstWhere((p) => p.id == id).name;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      DropdownButtonFormField<String>(
        initialValue: payer,
        decoration: const InputDecoration(labelText: 'Who paid?'),
        items: ids
            .map((id) => DropdownMenuItem(value: id, child: Text(name(id))))
            .toList(),
        onChanged: (v) => setState(() => payer = v!),
      ),
      DropdownButtonFormField<SplitMethod>(
        initialValue: method,
        decoration: const InputDecoration(labelText: 'Method'),
        items: SplitMethod.values
            .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
            .toList(),
        onChanged: (m) => setState(() {
          method = m!;
          reset();
        }),
      ),
      if (method != SplitMethod.equal)
        ...ids.map(
          (id) => TextField(
            key: ValueKey('$id:${method.name}'),
            controller: weights[id],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '${name(id)} · ${method.name}',
            ),
          ),
        ),
      if (error.isNotEmpty) Text(error),
      FilledButton(
        onPressed: () {
          try {
            final values = ids.map((id) {
              final raw = weights[id]!.text;
              return method == SplitMethod.equal
                  ? 1
                  : raw == '0'
                  ? 0
                  : method == SplitMethod.shares
                  ? int.parse(raw)
                  : parseMoney(raw);
            }).toList();
            allocateSplit(widget.row.amount, method, values);
            widget.row.method = method;
            widget.row.payerId = payer;
            widget.row.weights = Map.fromIterables(ids, values);
            Navigator.pop(context);
          } catch (e) {
            setState(() => error = e.toString());
          }
        },
        child: const Text('Use this split'),
      ),
    ],
  );
}
