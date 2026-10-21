/// The address of a thing, written the way a reader reads it.
///
/// An address is written by a program, and a program writes two things that
/// a reader has to translate: the scheme in front of a file, which says
/// nothing the reader does not know already, and the escapes inside an
/// address, which spell out characters the eye reads better directly.
String readableAddress(String address) {
  final trimmed = address.trim();

  return _withoutEscapes(_withoutFileScheme(trimmed));
}

/// Drops the scheme in front of a file address.
///
/// A file address is a path with `file://` in front of it, and the path is
/// what the reader can use.
String _withoutFileScheme(String address) {
  const scheme = 'file://';
  if (!address.startsWith(scheme)) return address;

  return address.substring(scheme.length);
}

/// Writes the characters an address escapes as the characters themselves.
///
/// An address escapes a space as `%20` and a slash as `%2F`. A reader reads
/// the character, not the way the program spelled it.
String _withoutEscapes(String address) {
  final buffer = StringBuffer();

  for (var index = 0; index < address.length; index++) {
    final char = address[index];
    if (char == '%' && index + 2 < address.length) {
      final code = int.tryParse(
        address.substring(index + 1, index + 3),
        radix: 16,
      );
      if (code != null) {
        buffer.writeCharCode(code);
        index += 2;
        continue;
      }
    }
    buffer.write(char);
  }

  return buffer.toString();
}
