import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barcode_widget/barcode_widget.dart';

import '../../core/design.dart';
import '../../core/models.dart';
import '../../core/upi.dart';
import '../../data/garden_store.dart';
import '../../shared/widgets.dart';

class GetPaid extends ConsumerStatefulWidget {
  const GetPaid({super.key});
  @override
  ConsumerState<GetPaid> createState() => _GetPaidState();
}

class _GetPaidState extends ConsumerState<GetPaid> {
  late final name = TextEditingController(
        text: ref.read(gardenProvider).data.profile.displayName,
      ),
      upi = TextEditingController(
        text: ref.read(gardenProvider).data.profile.upiId,
      );
  late bool qr = ref.read(gardenProvider).data.profile.includeQr,
      link = ref.read(gardenProvider).data.profile.includeUpiLink;
  @override
  void dispose() {
    name.dispose();
    upi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? preview;
    try {
      preview = upiLink(
        upiId: upi.text.trim(),
        payeeName: name.text.trim(),
        amountMinor: 100,
      );
    } catch (_) {}
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('GET PAID', style: context.type.labelSmall),
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Your name'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: upi,
          decoration: const InputDecoration(
            labelText: 'UPI ID',
            hintText: 'name@bank',
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (preview != null) ...[
          const SizedBox(height: 16),
          PayQr(link: preview, amount: 100),
          TextButton.icon(
            onPressed: () => Clipboard.setData(ClipboardData(text: preview!)),
            icon: const Icon(Icons.copy),
            label: const Text('Copy test link · ₹1'),
          ),
        ],
        SwitchListTile(
          title: const Text('Include QR in PDFs'),
          value: qr,
          onChanged: (v) => setState(() => qr = v),
        ),
        SwitchListTile(
          title: const Text('Include UPI link in text shares'),
          value: link,
          onChanged: (v) => setState(() => link = v),
        ),
        FilledButton(
          onPressed: () => perform(
            context,
            () => ref
                .read(gardenProvider)
                .change(
                  (d) => d.profile = Profile(
                    displayName: name.text.trim(),
                    payeeName: name.text.trim(),
                    upiId: upi.text.trim(),
                    includeQr: qr,
                    includeUpiLink: link,
                  ),
                ),
            success: 'Payment details saved.',
          ),
          child: const Text('Save payment details'),
        ),
      ],
    );
  }
}

class PayQr extends StatelessWidget {
  final String link;
  final int amount;
  const PayQr({super.key, required this.link, required this.amount});
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(18),
        color: gardenPack.light.surface,
        child: BarcodeWidget(
          barcode: Barcode.qrCode(),
          data: link,
          width: 200,
          height: 200,
          color: gardenPack.light.ink,
        ),
      ),
      Text(money(amount)),
      const Text('Turn up your brightness'),
    ],
  );
}
