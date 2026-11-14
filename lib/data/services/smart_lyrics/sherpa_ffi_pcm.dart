import 'dart:typed_data';

import 'package:tune/data/services/smart_lyrics/sherpa_transcript.dart';

/// Turns the 16-bit little-endian PCM in a speech-ready WAV into the float
/// samples `sherpa_onnx.acceptWaveform` wants (range −1…1).
Float32List pcm16ToFloat32(Uint8List bytes) {
  final count = bytes.length ~/ 2;
  final samples = Float32List(count);
  final view = ByteData.sublistView(bytes);
  for (var i = 0; i < count; i++) {
    samples[i] = view.getInt16(i * 2, Endian.little) / 32768.0;
  }
  return samples;
}

/// The words of one answer, dropping what is not a word.
///
/// Language, emotion and event tags (`<|zh|>`, `<|NEUTRAL|>`, …) and the
/// end-of-sentence mark carry no text; a token without a time has nowhere to
/// go, so the shorter of the two lists bounds the words. Shared by the JSON
/// answer of the desktop binary and the structured answer of the FFI
/// runtime, so the two backends cannot drift apart.
List<SherpaWord> wordsFromTokens(
  List<String> tokens,
  List<double> timestamps,
) {
  final count = tokens.length < timestamps.length
      ? tokens.length
      : timestamps.length;
  final words = <SherpaWord>[];
  for (var i = 0; i < count; i++) {
    final rawToken = tokens[i];
    if (rawToken.startsWith('<|') || rawToken == '</s>') continue;
    words.add(SherpaWord(rawToken.replaceAll('▁', ' '), timestamps[i]));
  }
  return words;
}

/// The words of an answer whose model gives no token times.
///
/// The whisper models sherpa-onnx publishes have no cross-attention outputs,
/// so `enableTokenTimestamps` comes back empty while the tokens themselves are
/// there. The text still counts as a vote; the times are spread evenly over
/// the audio, the same approximation the Fun-ASR-Nano family already ships
/// with (docs/smart-lyrics.md M13). A caller that needs real alignment treats
/// these times as weak evidence, never as a second measurement.
List<SherpaWord> wordsFromTokensEvenly(
  List<String> tokens,
  Duration duration,
) {
  final words = <String>[];
  for (final rawToken in tokens) {
    if (rawToken.startsWith('<|') || rawToken == '</s>') continue;
    words.add(rawToken.replaceAll('▁', ' '));
  }
  if (words.isEmpty) return const [];
  final step = duration.inMicroseconds / words.length;
  return [
    for (var i = 0; i < words.length; i++)
      SherpaWord(words[i], i * step / 1000000),
  ];
}
