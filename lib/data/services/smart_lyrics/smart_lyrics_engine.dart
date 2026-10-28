import 'dart:io';

/// One span of the song a transcription engine read off the audio.
class TranscribedSegment {
  final Duration start;
  final Duration end;
  final String text;

  /// How sure the engine was, when it says so at all; the vote does not
  /// weight on it, the pool does the weighing.
  final double? confidence;

  const TranscribedSegment({
    required this.start,
    required this.end,
    required this.text,
    this.confidence,
  });
}

/// The answer of one transcription pass.
class TranscriptionResult {
  final List<TranscribedSegment> segments;

  /// The language the engine heard, when it says so.
  final String? language;

  const TranscriptionResult({required this.segments, this.language});

  /// Whether the segments carry places in time.
  ///
  /// An endpoint that answered plain text (no `verbose_json`) hands back a
  /// sheet without a timeline: it counts as a reference vote only, and the
  /// pool never lets it settle a line (docs/smart-lyrics.md §6.1).
  bool get hasTimeline => segments.any(
    (segment) => segment.start > Duration.zero || segment.end > segment.start,
  );
}

/// What one transcription pass consumes.
class SmartAudioInput {
  /// The audio on this machine: the local file, the fetched copy, or the
  /// temporary file a stream was pulled into (docs/smart-lyrics.md §7.1).
  final File audio;

  /// The name of the track, for the prompts that ask the text model.
  final String title;
  final String artist;

  const SmartAudioInput({
    required this.audio,
    required this.title,
    required this.artist,
  });
}

/// One machine channel of the pool: one engine, one vote.
///
/// A channel is an endpoint with a model name, or the local whisper binary
/// with a model file. The same key with two model names is two channels —
/// the votes of one family lean on each other, but they still count apart.
abstract class SmartLyricsEngine {
  /// The channel this engine votes under, as the ledger and the logs read
  /// it — `cloud:whisper-1`, `local:base`.
  String get id;

  bool _disposed = false;

  /// Reads the words off the audio of one track.
  ///
  /// A channel that was closed has no vote left: asking it again throws.
  Future<TranscriptionResult> transcribe(
    SmartAudioInput input, {
    void Function(double progress)? onProgress,
  }) {
    if (_disposed) throw StateError('engine $id was disposed');
    return runTranscription(input, onProgress: onProgress);
  }

  /// The pass itself, as the engine family runs it: an upload for the cloud,
  /// a subprocess for the local binary.
  Future<TranscriptionResult> runTranscription(
    SmartAudioInput input, {
    void Function(double progress)? onProgress,
  });

  /// Closes the channel. Calling [transcribe] after this throws.
  void dispose() => _disposed = true;

  /// Stops the run that is on its way, when the engine has something to
  /// stop. An engine with nothing running lets the run finish; the caller
  /// discards the answer when the run was cancelled.
  void requestCancel() {}
}
