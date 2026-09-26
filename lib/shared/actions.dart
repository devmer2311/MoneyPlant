import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/garden_store.dart';
import 'widgets.dart';

Future<String?> askText(
  BuildContext context,
  String title, {
  String initial = '',
  bool secret = false,
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        obscureText: secret,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

Future<void> changeWithUndo(
  BuildContext context,
  GardenStore store,
  Future<void> Function() action,
  String message,
) async {
  final before = store.data.encode();
  final ok = await perform(context, action);
  if (!context.mounted || !ok) return;
  final after = store.data.encode();
  HapticFeedback.lightImpact();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => perform(context, () async {
          if (store.data.encode() != after) {
            throw const FormatException(
              'Your garden changed since then. Restore a backup to undo safely.',
            );
          }
          await store.restore(before);
        }),
      ),
    ),
  );
}
