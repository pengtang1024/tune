import 'package:tune/features/player/domain/lyrics_document.dart';

/// The sheet after one line was rewritten by hand (docs/smart-lyrics.md
/// §7.4, M6): the reader's words replace the line, everything else stays —
/// the stamps of the lines that carry one, the plain text of the ones that
/// do not.
///
/// The sheet is rebuilt from the parsed lines, so a line several stamps
/// share comes back as one line per stamp: the rewrite trades the packed
/// form for a sheet where every line is one markable row. A line number
/// that no longer exists leaves the sheet untouched — the sheet changed
/// under the mark, and the reader is shown what is there now.
String rewordSheet(String sheet, {required int line, required String text}) {
  final document = LyricsDocument.parse(sheet);
  if (line < 0 || line >= document.lines.length) return sheet;

  return [
    for (var index = 0; index < document.lines.length; index++)
      _lineOf(
        document.lines[index].time,
        index == line ? text : document.lines[index].text,
      ),
  ].join('\n');
}

/// The line as the sheet writes it: a stamp when it carries one, the bare
/// words when it does not.
String _lineOf(Duration? time, String text) {
  if (time == null) return text;
  final minutes = time.inMinutes.toString().padLeft(2, '0');
  final seconds = (time.inSeconds % 60).toString().padLeft(2, '0');
  final centis = ((time.inMilliseconds % 1000) ~/ 10).toString().padLeft(
    2,
    '0',
  );
  return '[$minutes:$seconds.$centis]$text';
}
