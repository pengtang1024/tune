import 'dart:convert';

import 'package:tune/data/services/smart_lyrics/smart_lyrics_engine.dart';

/// One word the model heard, with the second it began.
class SherpaWord {
  final String text;
  final double start;

  const SherpaWord(this.text, this.start);

  /// The same word, [offset] later — how the pieces of a long track become
  /// one timeline.
  SherpaWord shifted(Duration offset) =>
      SherpaWord(text, start + offset.inMicroseconds / 1000000);
}

/// What one pass of `sherpa-onnx-offline` printed.
class SherpaAnswer {
  final List<SherpaWord> words;
  final String? language;

  const SherpaAnswer(this.words, this.language);
}

/// Reads the JSON line the binary prints, or `null` when it printed none.
///
/// Silence is an answer — a file with no words still prints an object, just
/// with no tokens — so an absent object is the only thing that counts as a
/// broken answer.
SherpaAnswer? decodeSherpaAnswer(String stdoutText) {
  final line = stdoutText
      .split('\n')
      .map((row) => row.trim())
      .firstWhere((row) => row.startsWith('{'), orElse: () => '');
  if (line.isEmpty) return null;
  final decoded = _decodeObject(line);
  if (decoded == null) return null;
  final tokens = decoded['tokens'];
  final timestamps = decoded['timestamps'];
  final raw = decoded['language'] ?? decoded['lang'];
  final language = raw is String ? raw : null;
  if (tokens is! List || timestamps is! List) {
    return SherpaAnswer(const [], language);
  }
  // SenseVoice prints no durations, only starts; a token without a time has
  // nowhere to go, so the shorter of the two lists bounds the words.
  final count = tokens.length < timestamps.length
      ? tokens.length
      : timestamps.length;
  final words = <SherpaWord>[];
  for (var i = 0; i < count; i++) {
    final rawToken = '${tokens[i]}';
    // Language, emotion and event tags are not words.
    if (rawToken.startsWith('<|') || rawToken == '</s>') continue;
    final start = timestamps[i];
    words.add(
      SherpaWord(
        rawToken.replaceAll('▁', ' '),
        start is num ? start.toDouble() : 0,
      ),
    );
  }
  return SherpaAnswer(words, language);
}

Map<String, dynamic>? _decodeObject(String line) {
  try {
    final decoded = jsonDecode(line);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

/// The lines of the answer, cut at the silences between words.
///
/// A gap of 0.6 seconds closes a line; a line also closes after forty
/// characters so no monster line swallows the screen. The start of a line is
/// its first word's time — a measurement that owes nothing to whisper's
/// segment model.
List<TranscribedSegment> linesOf(List<SherpaWord> words) {
  final segments = <TranscribedSegment>[];
  final current = <String>[];
  var start = Duration.zero;
  var end = Duration.zero;
  var lastStart = Duration.zero;
  var written = 0;

  void close() {
    if (current.isEmpty) return;
    segments.add(
      TranscribedSegment(
        start: start,
        end: end,
        text: _cleanText(current.join()),
      ),
    );
    current.clear();
    written = 0;
  }

  for (final word in words) {
    final begin = Duration(milliseconds: (word.start * 1000).round());
    if (current.isNotEmpty) {
      final gap = begin - lastStart;
      if (gap > const Duration(milliseconds: 600) || written >= 40) close();
    }
    if (current.isEmpty) start = begin;
    current.add(word.text);
    written += word.text.length;
    // The line ends a beat past its last word — no durations to read.
    end = begin + const Duration(milliseconds: 500);
    lastStart = begin;
  }
  close();
  return segments;
}

String _cleanText(String text) => text
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll(RegExp(r'^[.\s]+'), '')
    .trim();
