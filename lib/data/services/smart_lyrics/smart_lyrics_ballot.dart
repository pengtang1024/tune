/// The words the lyrics vote passes around (docs/smart-lyrics.md §6.3).
///
/// Every source that can hand in a sheet for the same track is a vote: a
/// human-written sheet from a shared library, a machine transcription, or a
/// reconstruction the text model offered from its own knowledge of the song.
/// The algorithms that weigh the votes live in `smart_lyrics_consensus.dart`.
library;

/// The kind of a vote: who wrote the sheet down.
enum BallotKind {
  /// A sheet a person wrote; a shared library keeps it.
  human,

  /// A sheet a transcription engine read off the audio.
  machine,

  /// A sheet a text model rebuilt from what it knows of the song.
  knowledge,
}

/// One vote: a whole sheet of one song, lines with their places in time.
class LyricsBallot {
  final String origin;

  /// Who wrote the sheet down; the weight of the vote follows from it.
  final BallotKind kind;
  final List<BallotLine> lines;

  const LyricsBallot({
    required this.origin,
    required this.kind,
    required this.lines,
  });
}

/// One line of one sheet.
class BallotLine {
  final Duration start;
  final String text;

  const BallotLine({required this.start, required this.text});
}

/// One line the pool agreed on, or failed to.
class ConsensusLine {
  final Duration start;
  final String text;

  /// Whether the pool could not agree: the line needs a better vote or the
  /// reader's ear before it counts as resolved.
  final bool disputed;

  const ConsensusLine({
    required this.start,
    required this.text,
    required this.disputed,
  });
}

/// The outcome of one vote: the lines, and how many sheets took part.
class SmartConsensus {
  final List<ConsensusLine> lines;
  final int votesCounted;

  const SmartConsensus({required this.lines, required this.votesCounted});
}
