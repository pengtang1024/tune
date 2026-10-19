import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/domain/lyrics_document.dart';

final lyricsControllerProvider =
    NotifierProvider<LyricsController, LyricsState>(LyricsController.new);

/// Lyrics of the track the user is looking at.
class LyricsState {
  /// Track the lyrics belong to.
  final int? songId;

  /// Parsed lyric sheet, `null` while the lyrics are still unknown.
  final LyricsDocument? document;

  /// Whether the lyrics are being fetched right now.
  final bool loading;

  /// Whether the source knows lyrics for this track.
  final bool missing;

  /// Message of a failed request.
  final String? error;

  const LyricsState({
    this.songId,
    this.document,
    this.loading = false,
    this.missing = false,
    this.error,
  });

  /// Whether there is something to show.
  bool get hasLyrics => document != null && document!.lines.isNotEmpty;
}

/// Loads the lyrics of a track on demand.
///
/// Lyrics are fetched only when the user opens them, so a scan never pays
/// for them. The text of a track is kept for the session, because a plugin
/// answers the same question with the same sheet.
class LyricsController extends Notifier<LyricsState> {
  final Map<int, LyricsDocument> _cache = {};

  @override
  LyricsState build() => const LyricsState();

  /// Fetches the lyrics of [song] unless they are already known.
  Future<void> load(Song song) async {
    if (state.songId == song.id && (state.loading || state.hasLyrics)) return;

    final cached = _cache[song.id];
    if (cached != null) {
      state = LyricsState(songId: song.id, document: cached);
      return;
    }

    state = LyricsState(songId: song.id, loading: true);
    try {
      final raw = await ref.read(musicSourceServiceProvider).fetchLyrics(song);
      if (raw == null || raw.trim().isEmpty) {
        state = LyricsState(songId: song.id, missing: true);
        return;
      }

      final document = LyricsDocument.parse(raw);
      _cache[song.id] = document;
      state = LyricsState(songId: song.id, document: document);
    } catch (error) {
      state = LyricsState(songId: song.id, error: '$error');
    }
  }
}
