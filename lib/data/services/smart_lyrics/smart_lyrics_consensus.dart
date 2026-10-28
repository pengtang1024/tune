/// The pool that votes on the words of one song.
///
/// The votes are aligned on the timeline and the lines vote; a line the pool
/// cannot agree on leaves marked, it does not leave the song. This file is
/// pure logic with no I/O, so it can run in an isolate
/// (docs/smart-lyrics.md §6.3).
library;

import 'package:tune/data/services/smart_lyrics/smart_lyrics_ballot.dart';

/// The weight of one vote: a sheet a person wrote counts double, the doc's
///「1 张人写票顶 2 张机器票」.
int _weightOf(BallotKind kind) => switch (kind) {
  BallotKind.human => 2,
  BallotKind.machine => 1,
  BallotKind.knowledge => 1,
};

/// The rank a kind holds when two weights tie: a person's sheet outranks a
/// machine's, which outranks a model's memory of the song.
int _rankOf(BallotKind kind) => switch (kind) {
  BallotKind.human => 0,
  BallotKind.machine => 1,
  BallotKind.knowledge => 2,
};

/// What a line reads like once case, spaces and punctuation are out of the
/// way: two lines compare equal when this is equal.
final RegExp _comparable = RegExp(r'[\p{L}\p{N}]', unicode: true);

String _normalize(String text) => _comparable
    .allMatches(text.toLowerCase())
    .map((match) => match[0])
    .join();

/// Votes on the words of one song.
///
/// The knowledge vote has no timeline of its own, so it is aligned to the
/// first machine sheet first ([alignKnowledgeVote]); a reconstruction that
/// does not match that sheet does not vote at all. Fewer than three votes
/// is not a pool: every line stays disputed, because two sources can be
/// wrong together.
SmartConsensus voteOn(List<LyricsBallot> ballots, {LyricsBallot? knowledge}) {
  final pool = [...ballots];
  if (knowledge != null && pool.isNotEmpty) {
    final anchor = pool.firstWhere(
      (sheet) => sheet.kind == BallotKind.machine,
      orElse: () => pool.first,
    );
    final aligned = alignKnowledgeVote(knowledge, anchor);
    if (aligned != null) pool.add(aligned);
  }

  // Fewer than three votes: the pool cannot settle anything by itself.
  final settled = pool.length >= 3;

  final lines = [
    for (var index = 0; index < pool.length; index++)
      for (final line in pool[index].lines) (ballot: pool[index], line: line),
  ]..sort((a, b) => a.line.start.compareTo(b.line.start));

  final agreed = <ConsensusLine>[];
  var cursor = 0;
  while (cursor < lines.length) {
    final anchor = lines[cursor].line.start;
    var end = cursor;
    while (end < lines.length &&
        lines[end].line.start - anchor <= const Duration(milliseconds: 1000)) {
      end++;
    }
    agreed.add(_voteCluster(lines.sublist(cursor, end), settled));
    cursor = end;
  }

  return SmartConsensus(lines: agreed, votesCounted: pool.length);
}

/// One cluster votes: the lines that landed within a second of each other.
ConsensusLine _voteCluster(
  List<({LyricsBallot ballot, BallotLine line})> cluster,
  bool settled,
) {
  // The words grouped by what they read like; the first sheet to write them
  // this way keeps the wording the reader sees.
  final groups = <String, List<({LyricsBallot ballot, BallotLine line})>>{};
  for (final entry in cluster) {
    groups.putIfAbsent(_normalize(entry.line.text), () => []).add(entry);
  }

  String? best;
  BallotKind? bestKind;
  var bestWeight = 0;
  var totalWeight = 0;
  List<({LyricsBallot ballot, BallotLine line})>? bestGroup;
  for (final group in groups.values) {
    var weight = 0;
    for (final entry in group) {
      weight += _weightOf(entry.ballot.kind);
    }
    totalWeight += weight;
    final champion = group.first.ballot.kind;
    final beats =
        best == null ||
        weight > bestWeight ||
        (weight == bestWeight && _rankOf(champion) < _rankOf(bestKind!));
    if (beats) {
      bestWeight = weight;
      bestKind = champion;
      best = group.first.line.text;
      bestGroup = group;
    }
  }

  // A strict minority is a dispute: half the pool or more must have sung
  // these words. (Two against two settles through the tie-break above.)
  // The group votes with its text, so `best` and `bestGroup` settle together.
  final disputed = !settled || bestWeight * 2 < totalWeight;
  // The line starts where the winning words started, not where the loudest
  // cluster began: a stray line a second early must not pull the highlight.
  final start = bestGroup!
      .map((entry) => entry.line.start)
      .reduce((a, b) => a < b ? a : b);
  return ConsensusLine(start: start, text: best!, disputed: disputed);
}

/// Lines up a sheet that has no timeline of its own against the [anchor]'s.
///
/// The longest common subsequence of the comparable words decides which
/// anchor line each knowledge line belongs to; a matched line takes the
/// anchor's time. When fewer than 60% of the lines match, the model was
/// not singing this song — the vote is dropped ([null]), so a hallucinated
/// reconstruction never joins the pool.
LyricsBallot? alignKnowledgeVote(LyricsBallot knowledge, LyricsBallot anchor) {
  final words = [
    for (final line in knowledge.lines) _normalize(line.text),
  ];
  final timeline = [
    for (final line in anchor.lines) _normalize(line.text),
  ];
  if (words.isEmpty || timeline.isEmpty) return null;

  // The usual LCS table; a song has tens of lines, the square cost is fine.
  final table = List.generate(
    words.length + 1,
    (_) => List.filled(timeline.length + 1, 0),
  );
  for (var i = words.length - 1; i >= 0; i--) {
    for (var j = timeline.length - 1; j >= 0; j--) {
      table[i][j] = words[i] == timeline[j]
          ? table[i + 1][j + 1] + 1
          : (table[i + 1][j] >= table[i][j + 1]
                ? table[i + 1][j]
                : table[i][j + 1]);
    }
  }

  final matched = <BallotLine>[];
  var i = 0;
  var j = 0;
  while (i < words.length && j < timeline.length) {
    if (words[i] == timeline[j]) {
      matched.add(
        BallotLine(start: anchor.lines[j].start, text: knowledge.lines[i].text),
      );
      i++;
      j++;
    } else if (table[i + 1][j] >= table[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }

  // Six of every ten lines the model offered must sit in the anchor sheet.
  final rate = matched.length / words.length;
  if (rate < 0.6) return null;

  return LyricsBallot(
    origin: knowledge.origin,
    kind: BallotKind.knowledge,
    lines: matched,
  );
}
