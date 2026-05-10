class LrcLine {
  final Duration timestamp;
  final String text;

  LrcLine(this.timestamp, this.text);

  factory LrcLine.parse(String line) {
    final match = RegExp(r'\[(\d{2}):(\d{2}(?:\.\d{2,3})?)\](.*)').firstMatch(line);
    if (match == null) return LrcLine(Duration.zero, line);

    final min = int.parse(match.group(1)!);
    final secStr = match.group(2)!;
    final sec = double.parse(secStr);
    final ms = (min * 60 + sec) * 1000;
    final text = (match.group(3) ?? '').trim();

    return LrcLine(Duration(milliseconds: ms.toInt()), text);
  }
}

class LrcParser {
  final String content;
  String _title = '';
  String _artist = '';
  String _album = '';
  String _by = '';
  int _offset = 0;
  final List<LrcLine> _lines = [];

  LrcParser(this.content) {
    _parse();
  }

  String get title => _title;
  String get artist => _artist;
  String get album => _album;
  String get by => _by;
  int get offset => _offset;
  List<LrcLine> get lines => _lines;

  void _parse() {
    for (var line in content.split('\n')) {
      line = line.trim();
      if (line.isEmpty) continue;

      final tagMatch = RegExp(r'\[(ti|ar|al|by|offset):(.+)\]', caseSensitive: false).firstMatch(line);
      if (tagMatch != null) {
        final key = tagMatch.group(1)!.toLowerCase();
        final value = tagMatch.group(2)!.trim();
        switch (key) {
          case 'ti': _title = value; break;
          case 'ar': _artist = value; break;
          case 'al': _album = value; break;
          case 'by': _by = value; break;
          case 'offset': _offset = int.tryParse(value) ?? 0; break;
        }
        continue;
      }

      final timeMatch = RegExp(r'\[(\d{2}):(\d{2}(?:\.\d{2,3})?)\]');
      if (timeMatch.hasMatch(line)) {
        final parts = line.split(timeMatch);
        final matches = timeMatch.allMatches(line).toList();
        final text = parts.last.trim();

        for (var i = 0; i < matches.length; i++) {
          final m = matches[i];
          final min = int.parse(m.group(1)!);
          final sec = double.parse(m.group(2)!);
          final ms = ((min * 60 + sec) * 1000).toInt() + _offset;
          if (text.isNotEmpty) {
            _lines.add(LrcLine(Duration(milliseconds: ms), text));
          }
        }
      }
    }

    _lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  int findCurrentLineIndex(Duration position) {
    if (_lines.isEmpty) return -1;
    for (var i = _lines.length - 1; i >= 0; i--) {
      if (position >= _lines[i].timestamp) return i;
    }
    return -1;
  }
}
