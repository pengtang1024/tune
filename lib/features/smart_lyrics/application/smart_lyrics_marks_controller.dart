import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_batch_controller.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_mark.dart';

/// The flags one track's open marks give the panel: the lines to fly a
/// flag on, and the names the whole-track buttons wear.
final songMarksProvider = FutureProvider.family<SmartLyricsSongFlags, int>((
  ref,
  songId,
) {
  return ref.watch(smartLyricsTaskStoreProvider).flagsOf(songId);
});

/// The presses the panel makes (docs/smart-lyrics.md §7.4, M6): mark a
/// line, mark the whole track, name it not-sung — each press writes one
/// mark and puts the track back in the pool. Pressing again takes the
/// mark back; the panel never writes a word.
final smartLyricsMarksControllerProvider = Provider<SmartLyricsMarksController>(
  (ref) => SmartLyricsMarksController(ref),
);

class SmartLyricsMarksController {
  final Ref _ref;

  SmartLyricsMarksController(this._ref);

  /// Marks one line wrong, or takes the mark back.
  Future<void> toggleLine(int songId, int line) async {
    final store = _ref.read(smartLyricsTaskStoreProvider);
    final flags = await store.flagsOf(songId);
    if (flags.lines.contains(line)) {
      await store.unmarkLine(songId, line);
    } else {
      await store.markLine(songId, line);
    }
    await _refresh(songId);
  }

  /// Marks the whole track wrong, or takes the mark back.
  Future<void> toggleSong(int songId) async {
    final store = _ref.read(smartLyricsTaskStoreProvider);
    final flags = await store.flagsOf(songId);
    if (flags.song) {
      await store.unmarkSong(songId);
    } else {
      await store.markSong(songId);
    }
    await _refresh(songId);
  }

  /// Names the track not-sung, or takes the name back — it leaves the gap
  /// either way it went.
  Future<void> toggleNotSung(int songId) async {
    final store = _ref.read(smartLyricsTaskStoreProvider);
    final flags = await store.flagsOf(songId);
    if (flags.instrumental) {
      await store.unmarkSong(songId);
    } else {
      await store.markNotSung(songId);
    }
    await _refresh(songId);
  }

  Future<void> _refresh(int songId) async {
    _ref.invalidate(songMarksProvider(songId));
    _ref.invalidate(smartLyricsBatchCountsProvider);
    _ref.invalidate(smartLyricsNewMissingProvider);
  }
}
