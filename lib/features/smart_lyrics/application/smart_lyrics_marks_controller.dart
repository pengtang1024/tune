import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/providers/library_paths_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/player/application/lyrics_controller.dart';
import 'package:tune/features/player/domain/lyrics_document.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_batch_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_contrast_controller.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_mark.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_reword.dart';

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

/// The marks of the library as the management lists them: grouped by
/// track, the tracks with something open first. One window over the rows,
/// the same way the ledger counts.
final smartLyricsMarksProvider = FutureProvider<List<SmartLyricsMarkGroup>>((
  ref,
) async {
  ref.watch(
    libraryControllerProvider.select((state) => state.valueOrNull?.songs),
  );
  return ref.watch(smartLyricsTaskStoreProvider).markGroups();
});

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
      await store.unmarkNotSung(songId);
    } else {
      await store.markNotSung(songId);
    }
    await _refresh(songId);
  }

  /// Takes one mark of the management back the way it was made — the line,
  /// the track, or the not-sung name — and nothing next to it.
  Future<void> revokeMark(SmartLyricsMark mark) async {
    final store = _ref.read(smartLyricsTaskStoreProvider);
    switch (mark.kind) {
      case SmartLyricsMarkKind.line:
        await store.unmarkLine(mark.songId, mark.line ?? 0);
      case SmartLyricsMarkKind.song:
        await store.unmarkSong(mark.songId);
      case SmartLyricsMarkKind.instrumental:
        await store.unmarkNotSung(mark.songId);
    }
    await _refresh(mark.songId);
  }

  /// The words of [line] as the sheet the reader hears holds them — what
  /// the reword dialog opens with.
  Future<String> currentLineText(Song song, int line) async {
    final paths = _ref.read(libraryPathsProvider);
    final sheet =
        await paths.readLyrics(song) ?? await paths.readSmartLyrics(song);
    if (sheet == null || sheet.trim().isEmpty) return '';
    final document = LyricsDocument.parse(sheet);
    if (line < 0 || line >= document.lines.length) return '';
    return document.lines[line].text;
  }

  /// Writes the reader's words over one line: the sheet goes through the
  /// file the reading chain tops, and the mark is answered that way — the
  /// reader never types into the panel, only here (docs/smart-lyrics.md
  /// §7.4). The contrasts of the song go with the old words: what was
  /// said about lines that are not there any more holds for nobody.
  Future<void> rewordLine(Song song, int line, String text) async {
    final paths = _ref.read(libraryPathsProvider);
    final sheet =
        await paths.readLyrics(song) ?? await paths.readSmartLyrics(song);
    if (sheet == null || sheet.trim().isEmpty) return;

    await paths.saveChosenLyrics(song, rewordSheet(sheet, line: line, text: text));
    await paths.clearSmartContrast(song);
    await _ref.read(smartLyricsTaskStoreProvider).rewordMark(song.id, line);

    // The panel shows the words the reader wrote from the next read on.
    _ref.read(lyricsMemoryProvider).forget(song);
    _ref.invalidate(lyricsControllerProvider);
    _ref.invalidate(songContrastProvider(song));
    await _refresh(song.id);
  }

  Future<void> _refresh(int songId) async {
    _ref.invalidate(songMarksProvider(songId));
    _ref.invalidate(smartLyricsBatchCountsProvider);
    _ref.invalidate(smartLyricsNewMissingProvider);
  }
}
