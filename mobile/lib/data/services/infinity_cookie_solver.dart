// File: infinity_cookie_solver.dart
// Deskripsi: Helper pemecah tantangan keamanan AES-128 CBC dari server hosting InfinityFree.
// Fungsi: Mengekstrak parameter a, b, c dari halaman HTML aes.js, mendekripsi cookie __test, dan menyimpannya untuk header HTTP request.

import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;

class InfinityCookieSolver {
  static String? _cachedCookie;

  static String? get cachedCookie => _cachedCookie;

  static List<int> _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }

  static String? solveFromHtml(String html) {
    try {
      final regExp = RegExp(r'toNumbers\("([0-9a-fA-F]+)"\)');
      final matches = regExp.allMatches(html).toList();
      if (matches.length < 3) return null;

      final keyBytes = _hexToBytes(matches[0].group(1)!);
      final ivBytes = _hexToBytes(matches[1].group(1)!);
      final cipherBytes = _hexToBytes(matches[2].group(1)!);

      final key = enc.Key(Uint8List.fromList(keyBytes));
      final iv = enc.IV(Uint8List.fromList(ivBytes));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc, padding: null));

      final decrypted = encrypter.decryptBytes(
        enc.Encrypted(Uint8List.fromList(cipherBytes)),
        iv: iv,
      );

      final sb = StringBuffer();
      for (var b in decrypted) {
        sb.write(b.toRadixString(16).padLeft(2, '0'));
      }
      _cachedCookie = sb.toString();
      return _cachedCookie;
    } catch (_) {
      return null;
    }
  }
}
