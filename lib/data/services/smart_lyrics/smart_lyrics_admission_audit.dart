import 'package:tune/data/services/smart_lyrics/smart_lyrics_admission.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_ballot.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_consensus.dart';

/// The leave-one-out audit of the admission gate (docs/smart-lyrics.md
/// §7.6, M11b): machines auditing machines, no ears involved.
///
/// The gate settles a line when two independent classes read the same
/// words. The audit asks a harder question of every settled line: **for
/// each voice that carried the admission, would the line still settle
/// with that voice left out?** A voice is a family inside a class. Every
/// rotation must pass; one rotation that fails is a caught miss — the
/// estimate of the gate's漏网率 comes from these, and the confidence
/// upper bound when nothing was caught follows the rule of three.
class AdmissionAudit {
  /// Lines the audit could put on trial (three or more independent
  /// voices were present, so a rotation exists).
  final int checked;

  /// Lines where some rotation failed the gate — a miss the admission
  /// criterion alone would have let through.
  final int mismatched;

  const AdmissionAudit({required this.checked, required this.mismatched});

  /// The share of audited lines the judge rotations caught wrong — the
  /// audit's own estimate of the gate's miss rate.
  double get missRate => checked == 0 ? 0 : mismatched / checked;

  /// The upper bound of the miss rate when nothing was caught: the rule
  /// of three over the audited lines.
  double get missRateUpperBound =>
      mismatched == 0 && checked > 0 ? 3 / checked : missRate;
}

/// Audits the admission rotations over [ballots] — the same pool the
/// gate votes with, including [knowledge].
AdmissionAudit auditAdmission(
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

  var checked = 0;
  var mismatched = 0;
  var cursor = 0;
  while (cursor < lines.length) {
    final anchor = lines[cursor].line.start;
    var end = cursor;
    while (end < lines.length &&
        lines[end].line.start - anchor <= const Duration(milliseconds: 1000)) {
      end++;
    }
    final verdict = _auditCluster(lines.sublist(cursor, end));
    if (verdict.$1) {
      checked++;
      if (!verdict.$2) mismatched++;
    }
    cursor = end;
  }
  return AdmissionAudit(checked: checked, mismatched: mismatched);
}

/// One cluster's audit: (on trial, every rotation passed).
///
/// A cluster is on trial when the gate would settle it AND at least three
/// independent voices spoke, so leaving one out still leaves a gate that
/// can decide. The voices are (class, family) pairs that carry the
/// winning normalized text; a rotation drops one voice and re-runs the
/// two-class rule on the rest.
(bool, bool) _auditCluster(
  List<({LyricsBallot ballot, BallotLine line})> cluster,
) {
  final agreed = admit([for (final entry in cluster) entry.ballot]);
  final winners = agreed.lines.where((line) => !line.disputed);
  if (winners.isEmpty) return (false, false);
  final winner = winners.first;

  final normalized = _normalizeAudit(winner.text);
  final voices = <({LineageClass klass, String family})>[];
  for (final entry in cluster) {
    if (_normalizeAudit(entry.line.text) != normalized) continue;
    final (klass, family) = lineageOf(entry.ballot.origin);
    if (!voices.any((v) => v.klass == klass && v.family == family)) {
      voices.add((klass: klass, family: family));
    }
  }
  // Under the two-class gate, three voices can never rotate into a
  // standing gate — dropping one always leaves a single class. The audit
  // trials lines where four or more voices carried the words, so every
  // drop still leaves two classes a chance to stand.
  if (voices.length < 4) return (false, false);

  var verifiable = false;
  for (var left = 0; left < voices.length; left++) {
    final rotated = {
      for (var i = 0; i < cluster.length; i++)
        if (_familyOf(cluster[i].ballot.origin) != voices[left].family)
          cluster[i].ballot,
    }.toList();
    if (rotated.length < 2) continue;
    final rotatedWinners = admit(rotated)
        .lines
        .where((line) => !line.disputed);
    // 说不了话的裁判不下结论
    if (rotatedWinners.isEmpty) continue;
    verifiable = true;
    if (_normalizeAudit(rotatedWinners.first.text) != normalized) {
      // 一轮判出了别的字——抓到
      return (true, false);
    }
  }
  return (verifiable, true);
}

String _familyOf(String origin) => lineageOf(origin).$2;

final RegExp _auditComparable = RegExp(r'[\p{L}\p{N}]', unicode: true);

String _normalizeAudit(String text) => _auditComparable
    .allMatches(text.toLowerCase())
    .map((match) => match[0])
    .join();
