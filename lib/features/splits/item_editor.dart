import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/upi.dart';

class ItemEditor extends StatefulWidget {
  final List<SplitItem> items;
  final List<Person> people;
  const ItemEditor({super.key, required this.items, required this.people});
  @override
  State<ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<ItemEditor> {
  late final items = List<SplitItem>.of(widget.items);
  final name = TextEditingController(), amount = TextEditingController();
  late Set<String> selected = widget.people.map((p) => p.id).toSet();
  String kind = 'item', error = '';
  bool percent = false;
  @override
  void dispose() {
    name.dispose();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Who had what?'),
      ...items.asMap().entries.map(
        (e) => ListTile(
          title: Text(e.value.name),
          subtitle: Text('${e.value.kind} · ${minorDecimal(e.value.amount)}'),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => items.removeAt(e.key)),
          ),
        ),
      ),
      TextField(
        controller: name,
        decoration: const InputDecoration(labelText: 'Item name'),
      ),
      TextField(
        controller: amount,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Amount'),
      ),
      DropdownButton<String>(
        value: kind,
        items: [
          'item',
          'tax',
          'tip',
          'discount',
        ].map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
        onChanged: (v) => setState(() => kind = v!),
      ),
      if (kind == 'tax')
        SwitchListTile(
          title: const Text('Enter tax as percentage'),
          value: percent,
          onChanged: (v) => setState(() => percent = v),
        ),
      if (kind == 'item')
        Wrap(
          children: widget.people
              .map(
                (p) => FilterChip(
                  label: Text(p.name),
                  selected: selected.contains(p.id),
                  onSelected: (v) => setState(
                    () => v ? selected.add(p.id) : selected.remove(p.id),
                  ),
                ),
              )
              .toList(),
        ),
      if (error.isNotEmpty) Text(error),
      TextButton(
        onPressed: () {
          try {
            var value = parseMoney(amount.text);
            if (kind == 'tax' && percent) {
              final base = items
                  .where((i) => i.kind == 'item')
                  .fold(0, (a, i) => a + i.amount);
              value = (base * value + 5000) ~/ 10000;
              if (value <= 0) {
                throw const FormatException('Add item amounts before tax.');
              }
            }
            if (name.text.trim().isEmpty ||
                kind == 'item' && selected.isEmpty) {
              throw const FormatException(
                'Add a name and choose who shares it.',
              );
            }
            setState(() {
              items.add(
                SplitItem(
                  name: name.text.trim(),
                  amount: value,
                  personIds: kind == 'item' ? selected.toList() : [],
                  kind: kind,
                ),
              );
              name.clear();
              amount.clear();
              error = '';
            });
          } catch (e) {
            setState(() => error = e.toString());
          }
        },
        child: const Text('Add item / charge'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, items),
        child: const Text('Use these items'),
      ),
    ],
  );
}
