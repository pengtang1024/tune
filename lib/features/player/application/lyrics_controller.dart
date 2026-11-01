import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/library/lyrics_text.dart';
import 'package:tune/data/services/providers/library_paths_provider.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/lyrics_document.dart';
import 'package:tune/utils/logger.dart';

/// The lyrics of the track that plays.
///
/// The controller watches the player on its own: the page only shows what is
/// known, so no widget has to change a provider while the tree is built.
final lyricsControllerProvider =
    AsyncNotifierProvider.autoDispose<LyricsController, LyricsState>(
      LyricsController.new,
    );

/// The lyrics this run has already asked about.
///
/// The memory outlives the panel, so a track without lyrics is not asked
/// about again every time the reader opens the page.
final lyricsMemoryProvider = Provider<LyricsMemory>((ref) => LyricsMemory());

/// The line of the lyric sheet that is sung right now.
///
/// The panel watches this instead of the playback position, so it is rebuilt
/// when the line changes and not on every tick of the clock.
final activeLyricLineProvider = Provider<int>((ref) {
  final document = ref.watch(
    lyricsControllerProvider.select((state) => state.valueOrNull?.document),
  );
  if (document == null) return -1;

  final position = ref.watch(
    playbackControllerProvider.select((state) => state.position),
  );
  return document.indexAt(position);
});

/// What is known about the lyrics of the track that plays.
class LyricsState {
  /// The track the lyrics belong to.
  final int? songId;

  /// The parsed sheet, `null` when the track has no lyrics.
  final LyricsDocument? document;

  /// Whether the file the reader brought cannot be read as a sheet.
  final bool invalid;

  /// Whether the sheet on show is the machine's — the one the smart
  /// pipeline wrote. A better sheet found later tops it, so the panel says
  /// what this one is and offers the search again.
  final bool smart;

  const LyricsState({
    this.songId,
    this.document,
    this.invalid = false,
    this.smart = false,
  });

  /// Whether there is something to show.
  bool get hasLyrics => document != null && document!.lines.isNotEmpty;
}

/// Loads the lyrics of the track that plays.
///
/// The lyrics are fetched only when the reader opens them, so a scan never
/// pays for them. The text of a track is kept for the session, because a
/// plugin answers the same question with the same sheet.
class LyricsController extends AutoDisposeAsyncNotifier<LyricsState> {
  /// Every answer the reader brings in gets a new number.
  ///
  /// A request that is still on its way sees the number change and drops its
  /// own answer, so the lyrics of the reader are the ones on screen.
  int _generation = 0;

  @override
  Future<LyricsState> build() async {
    final song = ref.watch(
      playbackControllerProvider.select((state) => state.currentSong),
    );
    if (song == null) return const LyricsState();
    return _load(song);
  }

  /// Asks for the lyrics of [song] again, ignoring what is known.
  Future<void> reload(Song song) async {
    ref.read(lyricsMemoryProvider).forget(song);
    ref.invalidateSelf();
  }

  /// Uses the lyrics the reader brought for [song].
  ///
  /// The text is written next to the track, so it is still there the next
  /// time the track is played.
  ///
  /// Returns whether the file held a sheet.
  Future<bool> attach(Song song, List<int> bytes) async {
    final text = decodeLyricsText(bytes);
    final document = text == null ? null : LyricsDocument.parse(text);
    if (document == null || document.lines.isEmpty) {
      _remember(song, LyricsState(songId: song.id, invalid: true));
      return false;
    }

    await _write(ref.read(libraryPathsProvider).saveChosenLyrics(song, text!));
    _remember(song, LyricsState(songId: song.id, document: document));
    return true;
  }

  /// The lyrics of [song], from the file next to it or from the source.
  ///
  /// The file next to the track is read first, so a sheet that was matched
  /// once is used without asking the network again. A sheet that came from
  /// the source is written next to the track, so the next run finds it there.
  Future<LyricsState> _load(Song song) async {
    final memory = ref.read(lyricsMemoryProvider);
    if (memory.knows(song)) return memory.answerOf(song);

    final generation = _generation;
    final answer = await _lyricsFor(song);

    // While the request was on its way the reader may have brought lyrics
    // of their own; those are the ones that count.
    if (generation != _generation || memory.knows(song)) {
      return memory.answerOf(song);
    }

    final state = answer == null || answer.$1.trim().isEmpty
        ? LyricsState(songId: song.id)
        : LyricsState(
            songId: song.id,
            document: LyricsDocument.parse(answer.$1),
            smart: answer.$2,
          );
    memory.remember(song, state);
    return state;
  }

  /// The raw lyrics of [song], and whether they are the machine's.
  ///
  /// The order is the one the reading chain keeps (docs/lyrics.md): the
  /// file the reader brought, then the file the app matched, then the three
  /// segments of the sources, and the machine sheet the smart pipeline
  /// wrote — always last, so a real sheet found later tops it without
  /// erasing it.
  Future<(String, bool)?> _lyricsFor(Song song) async {
    final paths = ref.read(libraryPathsProvider);

    final stored = await paths.readLyrics(song);
    if (stored != null && stored.trim().isNotEmpty) return (stored, false);

    final raw = await ref.read(musicSourceServiceProvider).fetchLyrics(song);
    if (raw != null && raw.trim().isNotEmpty) {
      unawaited(_write(paths.saveLyrics(song, raw)));
      return (raw, false);
    }

    final machine = await paths.readSmartLyrics(song);
    if (machine != null && machine.trim().isNotEmpty) return (machine, true);
    return null;
  }

  /// Remembers an answer and shows it.
  void _remember(Song song, LyricsState answer) {
    _generation++;
    ref.read(lyricsMemoryProvider).remember(song, answer);
    state = AsyncData(answer);
  }

  /// Writes a file, without letting a failure reach the reader.
  ///
  /// A folder that cannot be written is not a reason to hide the lyrics.
  Future<void> _write(Future<void> write) async {
    try {
      await write;
    } catch (error, stackTrace) {
      Log.error('写入歌词失败: $error', stackTrace);
    }
  }
}

/// The lyrics this run has already asked about.
///
/// The memory holds more than the sheets: it also holds the tracks that have
/// no lyrics and the ones whose file could not be read, so the same question
/// is not asked twice.
class LyricsMemory {
  final Map<int, LyricsState> _answers = {};

  /// Whether [song] has been asked about.
  bool knows(Song song) => _answers.containsKey(song.id);

  /// The answer for [song].
  LyricsState answerOf(Song song) => _answers[song.id]!;

  /// Remembers the answer for [song].
  void remember(Song song, LyricsState answer) {
    _answers[song.id] = answer;
  }

  /// Forgets [song], so the next question is asked from scratch.
  void forget(Song song) {
    _answers.remove(song.id);
  }
}
