/// One line of a lyric sheet.
class LyricsLine {
  /// Time the line is sung at.
  ///
  /// `null` when the line carries no time stamp: a sheet that is plain text
  /// has no time at all, and such a line is never the one being sung.
  final Duration? time;

  /// Text of the line.
  final String text;

  const LyricsLine({required this.time, required this.text});
}

/// A parsed lyric sheet.
///
/// The player uses the time stamps to highlight the line that is sung right
/// now. Sheets without time stamps are shown as plain text.
class LyricsDocument {
  /// The lines of the sheet, in the order they are shown.
  ///
  /// The lines that carry a time stamp come first, sorted by their time. The
  /// lines without a time stamp keep the order of the sheet and follow them.
  final List<LyricsLine> lines;

  /// The places of the lines that carry a time stamp, sorted by their time.
  final List<int> _timed;

  LyricsDocument(List<LyricsLine> lines)
    : lines = List.unmodifiable(lines),
      _timed = _timedPlaces(lines);

  /// Whether the sheet carries time stamps.
  bool get isTimed => _timed.isNotEmpty;

  /// Index of the line that is sung at [position].
  ///
  /// Returns `-1` when the sheet has no time stamps, or when no line has
  /// started yet: the reader is not singing the first line before it begins.
  int indexAt(Duration position) {
    var low = 0;
    var high = _timed.length - 1;
    var found = -1;
    while (low <= high) {
      final middle = (low + high) >> 1;
      if (lines[_timed[middle]].time! <= position) {
        found = middle;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    return found < 0 ? -1 : _timed[found];
  }

  /// The places of the lines that carry a time stamp, sorted by their time.
  static List<int> _timedPlaces(List<LyricsLine> lines) {
    final timed = <int>[
      for (var i = 0; i < lines.length; i++)
        if (lines[i].time != null) i,
    ];
    timed.sort((a, b) {
      final byTime = lines[a].time!.compareTo(lines[b].time!);
      // The lines that share a time keep the order of the sheet.
      return byTime != 0 ? byTime : a.compareTo(b);
    });
    return timed;
  }

  /// Parses an LRC sheet.
  ///
  /// The header of the sheet is not shown to the reader, and the offset it
  /// declares moves the whole sheet. Lines without a time stamp are kept, so
  /// the text of a plain sheet is not lost.
  factory LyricsDocument.parse(String raw) {
    final timed = <LyricsLine>[];
    final untimed = <String>[];
    var offset = Duration.zero;

    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final header = _headerTag(line);
      if (header != null) {
        if (header.name == 'offset') offset = _offsetOf(header.value);
        continue;
      }

      final stamps = _timeStamps(line);
      if (stamps.isEmpty) {
        untimed.add(_text(line));
        continue;
      }

      final text = _text(_textOf(line));
      for (final stamp in stamps) {
        timed.add(LyricsLine(time: stamp, text: text));
      }
    }

    final moved = [
      for (final line in timed)
        LyricsLine(time: line.time! - offset, text: line.text),
    ];
    final order = List.generate(moved.length, (index) => index)
      ..sort((a, b) {
        final byTime = moved[a].time!.compareTo(moved[b].time!);
        return byTime != 0 ? byTime : a.compareTo(b);
      });

    return LyricsDocument([
      for (final index in order) moved[index],
      for (final text in untimed) LyricsLine(time: null, text: text),
    ]);
  }

  static final _stampPattern = RegExp(
    r'^\[[0-9]{1,3}:[0-9]{1,2}(?:[.:][0-9]{1,3})?\]',
  );

  static final _headerPattern = RegExp(r'^\[([a-zA-Z]+):([^\]]*)\]$');

  static final _wordPattern = RegExp(r'<\d{1,3}:\d{1,2}(?:[.:]\d{1,3})?>');

  /// The name and the value of a header tag, when the line is one.
  static ({String name, String value})? _headerTag(String line) {
    final match = _headerPattern.firstMatch(line);
    if (match == null) return null;
    return (name: match.group(1)!.toLowerCase(), value: match.group(2)!.trim());
  }

  /// Reads the offset the header declares.
  static Duration _offsetOf(String value) {
    final millis = int.tryParse(value);
    if (millis == null) return Duration.zero;
    return Duration(milliseconds: millis);
  }

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

  /// Reads the text of a line without the tags of an enhanced sheet.
  static String _text(String line) =>
      line.replaceAll(_wordPattern, '').trim();

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
