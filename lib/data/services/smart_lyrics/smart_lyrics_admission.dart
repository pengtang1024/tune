/// The admission gate of §7.6 (M10): a line is admitted to the sheet only
/// when **two independent lineage classes** carry the same normalized text
/// — the correctness of the resolved set follows from the criterion, not
/// from an audit. Any doubt discards the line; it stays a gap.
library;

import 'package:tune/data/services/smart_lyrics/smart_lyrics_ballot.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_consensus.dart';

/// The class a ballot's words come from — the independence the product of
/// error rates rides on. Same-class sources never count twice.
enum LineageClass { human, llm, asr }

/// The family inside a class: whisper-1 and tiny are both whisper, two
/// gpt revisions are both gpt — same family cannot cross-prove.
String asrFamilyOf(String model) {
  final m = model.toLowerCase();
  for (final root in const ['whisper', 'wav2vec', 'paraformer', 'sensevoice']) {
    if (m.contains(root)) return root;
  }
  // The whisper.cpp bare names are whisper: tiny, base, small, medium,
  // large — same algorithm as cloud whisper, same blind spots.
  for (final root in const ['tiny', 'base', 'small', 'medium', 'large']) {
    if (m.contains(root)) return 'whisper';
  }
  return m.split(RegExp(r'[-.]')).first;
}

String llmFamilyOf(String model) {
  final m = model.toLowerCase();
  for (final root in const [
    'gpt', 'deepseek', 'mimo', 'qwen', 'gemini', 'llama', 'mistral', 'grok',
    'glm', 'yi', 'phi',
  ]) {
    if (m.startsWith(root) || m.contains(root)) return root;
  }
  return m.split(RegExp(r'[-.]')).first;
}

/// Which class and family a ballot's origin speaks for — `lrclib` the
/// human library, `knowledge:<model>` the rebuilds, `cloud:<model>` and
/// `local:<model>` the transcriptions.
(LineageClass, String) lineageOf(String origin) {
  final o = origin.toLowerCase();
  if (o.startsWith('knowledge')) {
    final model = o == 'knowledge' ? '' : o.substring('knowledge'.length + 1);
    return (LineageClass.llm, llmFamilyOf(model.isEmpty ? 'unknown' : model));
  }
  if (o.startsWith('cloud:')) {
    return (LineageClass.asr, asrFamilyOf(o.substring('cloud:'.length)));
  }
  if (o.startsWith('local:')) {
    // A local whisper is still whisper: the same algorithm, the same
    // blind spots — it cannot cross-prove a cloud whisper.
    return (LineageClass.asr, asrFamilyOf(o.substring('local:'.length)));
  }
  return (LineageClass.human, o);
}

final RegExp _comparable = RegExp(r'[\p{L}\p{N}]', unicode: true);

String _normalize(String text) => _comparable
    .allMatches(text.toLowerCase())
    .map((match) => match[0])
    .join();

/// Admits the lines the pool can cross-prove (docs/smart-lyrics.md §7.6).
///
/// Clusters the lines a second apart the way [voteOn] does, then replaces
/// its majority rule with the admission criterion: a cluster is settled
/// only when two independent classes read the same words — a human sheet
/// agreeing with a second ASR family, two LLM families rebuilding the
/// same line, and so on. Anything else is recorded disputed and stays out
/// of the sheet's body: 宁缺勿错.
SmartConsensus admit(
  List<LyricsBallot> ballots, {
  List<LyricsBallot> knowledge = const [],
}) {
  final pool = [...ballots];
  if (knowledge.isNotEmpty && pool.isNotEmpty) {
    final anchor = pool.firstWhere(
      (sheet) => sheet.kind == BallotKind.machine,
      orElse: () => pool.first,
    );
    for (final extra in knowledge) {
      final aligned = alignKnowledgeVote(extra, anchor);
      if (aligned != null) pool.add(aligned);
    }
  }

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
    agreed.add(_admitCluster(lines.sublist(cursor, end)));
    cursor = end;
  }

  return SmartConsensus(lines: agreed, votesCounted: pool.length);
}

/// One cluster's verdict: two independent classes must read the same words.
ConsensusLine _admitCluster(
  List<({LyricsBallot ballot, BallotLine line})> cluster,
) {
  // class → normalized text → family → the wording that family wrote.
  final texts = <LineageClass, Map<String, Map<String, String>>>{};
  for (final entry in cluster) {
    final (klass, family) = lineageOf(entry.ballot.origin);
    final normalized = _normalize(entry.line.text);
    texts
        .putIfAbsent(klass, () => {})
        .putIfAbsent(normalized, () => {})
        .putIfAbsent(family, () => entry.line.text);
  }

  // A class speaks only with its required voices: one human voice (its
  // sheets are one library's), two distinct machine families for the
  // rebuilds and the transcriptions — one voice cannot cross-prove.
  final agreed = <LineageClass, Map<String, String>>{}; // class → norm → text
  texts.forEach((klass, byNorm) {
    final required = klass == LineageClass.human ? 1 : 2;
    for (final entry in byNorm.entries) {
      if (entry.value.length >= required) {
        agreed.putIfAbsent(klass, () => {})[entry.key] = entry.value.values.first;
      }
    }
  });

  // Admission: two classes, the same normalized words.
  final perNorm = <String, List<LineageClass>>{};
  agreed.forEach((klass, byNorm) {
    for (final normalized in byNorm.keys) {
      perNorm.putIfAbsent(normalized, () => []).add(klass);
    }
  });

  String? admitted;
  for (final entry in perNorm.entries) {
    if (entry.value.length >= 2 &&
        (admitted == null || entry.value.length > perNorm[admitted]!.length)) {
      admitted = entry.key;
    }
  }

  if (admitted == null) {
    return ConsensusLine(
      start: cluster.first.line.start,
      text: '',
      disputed: true,
    );
  }
  // The wording the reader sees: the human sheet among the admitting
  // classes wins the wording; otherwise the first machine text.
  final wording = agreed[LineageClass.human]?[admitted] ??
      agreed[LineageClass.asr]?[admitted] ??
      agreed[LineageClass.llm]![admitted]!;

  // Timing cross-check (§7.6): the admitting classes are the independent
  // measurements — their line times must agree within 0.5s, or the
  // seconds are as unproven as the words and the line stays a gap. A
  // class without a real time of its own (the rebuilds carry no
  // timeline) cannot measure; the forced-alignment measurement joins
  // here when it lands.
  Duration? startOf(LineageClass klass) {
    for (final entry in cluster) {
      final (k, _) = lineageOf(entry.ballot.origin);
      if (k == klass && _normalize(entry.line.text) == admitted) {
        return entry.line.start;
      }
    }
    return null;
  }

  final starts = <Duration>[
    for (final klass in perNorm[admitted]!) ?startOf(klass),
  ];
  final minStart = starts.reduce((a, b) => a < b ? a : b);
  if (starts.length < 2 ||
      starts.reduce((a, b) => a > b ? a : b) - minStart >
          const Duration(milliseconds: 500)) {
    return ConsensusLine(start: minStart, text: '', disputed: true);
  }
  return ConsensusLine(
    start: minStart,
    text: wording,
    disputed: false,
  );
}
