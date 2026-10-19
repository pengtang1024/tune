/// One line of a lyric sheet.
class LyricsLine {
  /// Time the line is sung at.
  final Duration time;

  /// Text of the line.
  final String text;

  const LyricsLine({required this.time, required this.text});
}

/// A parsed lyric sheet.
///
/// The player uses the time stamps to highlight the line that is sung right
/// now. Sheets without time stamps are shown as plain text.
class LyricsDocument {
  final List<LyricsLine> lines;

  const LyricsDocument(this.lines);

  /// Whether the sheet carries time stamps.
  bool get isTimed => lines.any((line) => line.time > Duration.zero);

  /// Parses an LRC sheet.
  ///
  /// Lines without a time stamp are kept at the start so the text of a plain
  /// sheet is not lost.
  factory LyricsDocument.parse(String raw) {
    final lines = <LyricsLine>[];
    final untimed = <String>[];

    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final stamps = _timeStamps(line);
      if (stamps.isEmpty) {
        untimed.add(line);
        continue;
      }

      final text = _textOf(line);
      for (final stamp in stamps) {
        lines.add(LyricsLine(time: stamp, text: text));
      }
    }

    lines.sort((a, b) => a.time.compareTo(b.time));
    return LyricsDocument([
      ...untimed.map((text) => LyricsLine(time: Duration.zero, text: text)),
      ...lines,
    ]);
  }

  /// Index of the line that is sung at [position].
  ///
  /// Returns `-1` when the sheet has no time stamps.
  int indexAt(Duration position) {
    if (!isTimed) return -1;

    var index = 0;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].time <= position) {
        index = i;
        continue;
      }
      break;
    }
    return index;
  }

  static final _stampPattern = RegExp(
    r'^\[[0-9]{1,3}:[0-9]{1,2}(?:[.:][0-9]{1,3})?\]',
  );

  /// Reads the text of a line without its time stamps.
  static String _textOf(String line) {
    var rest = line;
    while (true) {
      final match = _stampPattern.firstMatch(rest);
      if (match == null) break;
      rest = rest.substring(match.end);
    }
    return rest.trim();
  }

  /// Reads every time stamp of a line.
  static List<Duration> _timeStamps(String line) {
    final stamps = <Duration>[];
    var rest = line;
    while (true) {
      final match = _stampPattern.firstMatch(rest);
      if (match == null) break;
      stamps.add(_parseStamp(match.group(0)!));
      rest = rest.substring(match.end);
    }
    return stamps;
  }

  /// Reads `[mm:ss.xx]` into a duration.
  static Duration _parseStamp(String stamp) {
    final body = stamp.replaceAll('[', '').replaceAll(']', '');
    final parts = body.split(RegExp('[:.]'));
    final minutes = int.tryParse(parts.first) ?? 0;
    final seconds = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    // The fraction is written with one, two or three digits, so its scale
    // follows the number of digits and not its value.
    var millis = 0;
    if (parts.length > 2) {
      final digits = parts[2].length;
      final value = int.tryParse(parts[2]) ?? 0;
      millis = value * (digits == 1 ? 100 : (digits == 2 ? 10 : 1));
    }

    return Duration(minutes: minutes, seconds: seconds, milliseconds: millis);
  }
}
