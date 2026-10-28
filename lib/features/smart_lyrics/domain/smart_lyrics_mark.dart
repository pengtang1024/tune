/// The marks a track carries (docs/smart-lyrics.md §7.4, M6): a reader
/// hears the words are wrong and presses once — never types. Every mark
/// has a place to go: the re-solve clears it, an explicit reword settles
/// it, the reader takes it back, or the track is named「不是唱的」.
library;

/// What a mark is about.
enum SmartLyricsMarkKind {
  /// One line of the sheet, by its number in the order it is shown.
  line,

  /// The whole track.
  song,

  /// The track is not sung at all — the name for the instrumental.
  instrumental;

  /// The name the tables store.
  String get id => name;
}

/// Where a mark stands.
enum SmartLyricsMarkState {
  /// The mark was made and nothing has answered it yet.
  uncleared,

  /// The re-solve worked: the new sheet settled the line or the track.
  resolved,

  /// The reader wrote the words themselves; the mark is answered that way.
  reworded,

  /// The reader took the mark back.
  revoked;

  /// The name the tables store.
  String get id => name;
}

/// One mark as the management reads it.
class SmartLyricsMark {
  final int id;
  final int songId;

  /// The line the mark is about, `null` when it is about the track.
  final int? line;
  final SmartLyricsMarkKind kind;

  /// Who made it: the consensus (`system`) or the reader.
  final String source;
  final SmartLyricsMarkState state;
  final DateTime createdAt;

  const SmartLyricsMark({
    required this.id,
    required this.songId,
    this.line,
    required this.kind,
    required this.source,
    required this.state,
    required this.createdAt,
  });
}

/// What the panel shows of a track's open marks: the lines to fly a flag
/// on, and the names the whole-track buttons wear.
class SmartLyricsSongFlags {
  /// The line numbers with an open mark.
  final Set<int> lines;

  /// Whether the whole track is marked wrong.
  final bool song;

  /// Whether the track was named not-sung.
  final bool instrumental;

  const SmartLyricsSongFlags({
    this.lines = const {},
    this.song = false,
    this.instrumental = false,
  });

  static const SmartLyricsSongFlags empty = SmartLyricsSongFlags();

  bool get isEmpty => lines.isEmpty && !song && !instrumental;
}
