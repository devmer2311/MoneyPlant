import 'models.dart';

String minorDecimal(int amount) =>
    '${amount ~/ 100}.${(amount.abs() % 100).toString().padLeft(2, '0')}';
String upiLink({
  required String upiId,
  required String payeeName,
  int? amountMinor,
  String? note,
}) {
  if (!RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z][a-zA-Z0-9]{1,63}$')
      .hasMatch(upiId)) {
    throw const FormatException('Enter a valid UPI ID, like name@bank.');
  }
  if (amountMinor != null && amountMinor < 0) {
    throw const FormatException('Enter a positive amount.');
  }
  final params = {
    'pa': upiId,
    'pn': payeeName,
    if (amountMinor != null && amountMinor > 0) 'am': minorDecimal(amountMinor),
    'cu': 'INR',
    if (note != null) 'tn': String.fromCharCodes(note.runes.take(50)),
  };
  return 'upi://pay?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
}

String? paymentLink(GardenData d, int net, {bool pdf = false}) =>
    d.currency != 'INR' ||
        net <= 0 ||
        d.profile.upiId.isEmpty ||
        !(pdf ? d.profile.includeQr : d.profile.includeUpiLink)
    ? null
    : upiLink(
        upiId: d.profile.upiId,
        payeeName: d.profile.payeeName.isEmpty
            ? d.profile.displayName
            : d.profile.payeeName,
        amountMinor: net,
        note: 'Money Plant',
      );
