import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/providers/library_paths_provider.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/domain/lyrics_document.dart';
import 'package:tune/utils/logger.dart';

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

  /// Whether the request failed.
  ///
  /// The state carries the fact and not the wording, so the interface writes
  /// the reason of the failure in the language the app renders in.
  final bool failed;

  const LyricsState({
    this.songId,
    this.document,
    this.loading = false,
    this.missing = false,
    this.failed = false,
  });

  /// Whether there is something to show.
  bool get hasLyrics => document != null && document!.lines.isNotEmpty;
}

/// Loads the lyrics of a track on demand.
///
/// Lyrics are fetched only when the user opens them, so a scan never pays
/// for them. The text of a track is kept for the session, because a source
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
      final raw = await _lyricsFor(song);
      if (raw == null || raw.trim().isEmpty) {
        state = LyricsState(songId: song.id, missing: true);
        return;
      }

      final document = LyricsDocument.parse(raw);
      _cache[song.id] = document;
      state = LyricsState(songId: song.id, document: document);
    } catch (error, stackTrace) {
      Log.error('歌词加载失败: $error', stackTrace);
      state = LyricsState(songId: song.id, failed: true);
    }
  }

  /// The lyrics of [song], from the file next to it or from the source.
  ///
  /// The file next to the track is read first, so a sheet that was matched
  /// once is used without asking the network again. A sheet that came from
  /// the source is written next to the track, so the next run finds it there.
  Future<String?> _lyricsFor(Song song) async {
    final paths = ref.read(libraryPathsProvider);

    final stored = await paths.readLyrics(song);
    if (stored != null && stored.trim().isNotEmpty) return stored;

    final raw = await ref.read(musicSourceServiceProvider).fetchLyrics(song);
    if (raw == null || raw.trim().isEmpty) return raw;

    unawaited(paths.saveLyrics(song, raw));
    return raw;
  }
}
