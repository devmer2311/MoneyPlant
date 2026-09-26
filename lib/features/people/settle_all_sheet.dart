import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/design.dart';
import '../../core/upi.dart';
import '../../data/garden_store.dart';
import '../../shared/actions.dart';
import '../../shared/confetti.dart';

class SettleAllSheet extends ConsumerStatefulWidget {
  final Person person;
  const SettleAllSheet({super.key, required this.person});
  @override
  ConsumerState<SettleAllSheet> createState() => _SettleAllSheetState();
}

class _SettleAllSheetState extends ConsumerState<SettleAllSheet> {
  late final amount = TextEditingController(
    text: minorDecimal(
      ref.read(gardenProvider).personNet(widget.person.id).abs(),
    ),
  );
  DateTime date = DateTime.now();
  bool saving = false;
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(gardenProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Settle with ${widget.person.name}',
          style: context.type.headlineMedium,
        ),
        Text(
          'Current net ${money(store.personNet(widget.person.id).abs(), store.data.currency)}',
        ),
        TextField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        TextButton.icon(
          onPressed: () async {
            final next = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (next != null) setState(() => date = next);
          },
          icon: const Icon(Icons.calendar_today),
          label: Text(date.toIso8601String().split('T').first),
        ),
        FilledButton(
          onPressed: saving
              ? null
              : () async {
                  setState(() => saving = true);
                  await changeWithUndo(
                    context,
                    store,
                    () => store.settleAll(
                      widget.person.id,
                      parseMoney(amount.text),
                      date,
                    ),
                    'Settlement saved',
                  );
                  if (!context.mounted) return;
                  if (store.personNet(widget.person.id) == 0) {
                    celebrate(context);
                  }
                  setState(() => saving = false);
                },
          child: const Text('Record settlement'),
        ),
      ],
    );
  }
}
