import 'package:flutter/material.dart';

import '../core/design.dart';
import '../data/garden_store.dart';
import 'actions.dart';

class PaymentRow extends StatelessWidget {
  final GardenStore store;
  final String paymentId;
  final Widget child;
  const PaymentRow({
    super.key,
    required this.store,
    required this.paymentId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey('payment:$paymentId'),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.all(16),
      color: context.colors.errorContainer,
      child: Icon(Icons.undo, color: context.colors.onErrorContainer),
    ),
    confirmDismiss: (_) async {
      await changeWithUndo(
        context,
        store,
        () => store.removePayment(paymentId),
        'Payment removed',
      );
      // The store rebuild removes the row only after a successful save.
      return false;
    },
    child: child,
  );
}
