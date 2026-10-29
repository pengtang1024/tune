import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The identity of the words in a sheet: a short sha1 over its timed body.
///
/// A date is a day-granular key — two regenerations on one day would let
/// the old contrasts sit under shifted lines. The content key moves
/// whenever a line moves and stays put when only the header's account
/// (votes, sources, date) changes.
String sheetContentKey(String sheet) {
  final body = const LineSplitter()
      .convert(sheet)
      .where(_timedLine.hasMatch)
      .join('\n');
  return sha1.convert(utf8.encode(body)).toString().substring(0, 12);
}

final RegExp _timedLine = RegExp(r'^\[\d+:\d{2}\.\d{2}\]');
