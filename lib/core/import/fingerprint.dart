import 'dart:convert';

// Stable SHA-1 fingerprint for duplicate detection, never used for authentication.
String statementFingerprint(String value) {
  final bytes = utf8.encode(value).toList();
  final length = bytes.length * 8;
  bytes.add(0x80);
  while (bytes.length % 64 != 56) {
    bytes.add(0);
  }
  bytes.addAll(List.filled(8, 0));
  var remainingLength = length;
  for (var i = 0; i < 8; i++) {
    bytes[bytes.length - 1 - i] = remainingLength % 256;
    remainingLength ~/= 256;
  }
  var h0 = 0x67452301,
      h1 = 0xefcdab89,
      h2 = 0x98badcfe,
      h3 = 0x10325476,
      h4 = 0xc3d2e1f0;
  int rotate(int v, int n) => ((v << n) | (v >>> (32 - n))) & 0xffffffff;
  for (var offset = 0; offset < bytes.length; offset += 64) {
    final words = List.filled(80, 0);
    for (var i = 0; i < 16; i++) {
      final n = offset + i * 4;
      words[i] =
          (bytes[n] << 24) |
          (bytes[n + 1] << 16) |
          (bytes[n + 2] << 8) |
          bytes[n + 3];
    }
    for (var i = 16; i < 80; i++) {
      words[i] = rotate(
        words[i - 3] ^ words[i - 8] ^ words[i - 14] ^ words[i - 16],
        1,
      );
    }
    var a = h0, b = h1, c = h2, d = h3, e = h4;
    for (var i = 0; i < 80; i++) {
      final f = i < 20
          ? (b & c) | ((~b) & d)
          : i < 40
          ? b ^ c ^ d
          : i < 60
          ? (b & c) | (b & d) | (c & d)
          : b ^ c ^ d;
      final k = i < 20
          ? 0x5a827999
          : i < 40
          ? 0x6ed9eba1
          : i < 60
          ? 0x8f1bbcdc
          : 0xca62c1d6;
      final temp = (rotate(a, 5) + f + e + k + words[i]) & 0xffffffff;
      e = d;
      d = c;
      c = rotate(b, 30);
      b = a;
      a = temp;
    }
    h0 = (h0 + a) & 0xffffffff;
    h1 = (h1 + b) & 0xffffffff;
    h2 = (h2 + c) & 0xffffffff;
    h3 = (h3 + d) & 0xffffffff;
    h4 = (h4 + e) & 0xffffffff;
  }
  return [
    h0,
    h1,
    h2,
    h3,
    h4,
  ].map((v) => v.toRadixString(16).padLeft(8, '0')).join();
}
