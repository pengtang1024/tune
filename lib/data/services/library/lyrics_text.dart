import 'dart:convert';

import 'package:charset/charset.dart';

/// Reads the text of a lyrics file.
///
/// The files of the readers are often written in the encoding of their own
/// system, so a file that is not valid UTF-8 is read as GBK, which is what
/// the Chinese lyrics files are usually written in.
String? decodeLyricsText(List<int> bytes) {
  if (bytes.isEmpty) return null;

  final data = _withoutBom(bytes);
  final text = utf8.decode(data, allowMalformed: true);
  if (!text.contains('�')) return text;

  try {
    return gbk.decode(data);
  } catch (error) {
    return text;
  }
}

/// The bytes of a file without the mark a text file may begin with.
List<int> _withoutBom(List<int> bytes) {
  if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
    return bytes.sublist(3);
  }
  return bytes;
}
