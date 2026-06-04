import 'dart:typed_data';

/// Piped Windows processes often emit LF-only newlines. VT emulators need CRLF
/// so the cursor returns to column 0; otherwise each line starts where the
/// previous line ended (stair-step output).
Uint8List normalizePipedOutputForVt(List<int> bytes) {
  if (bytes.isEmpty) {
    return Uint8List(0);
  }

  final out = BytesBuilder(copy: false);
  for (var i = 0; i < bytes.length; i++) {
    final byte = bytes[i];
    if (byte == 0x0A) {
      if (i == 0 || bytes[i - 1] != 0x0D) {
        out.addByte(0x0D);
      }
      out.addByte(0x0A);
    } else {
      out.addByte(byte);
    }
  }
  return out.toBytes();
}
