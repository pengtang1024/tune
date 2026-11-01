import 'dart:io';

import 'package:tune/domain/models/song.dart';

/// The folders of the music library.
///
/// The app keeps the files it fetches in the music library of the machine,
/// so a track it downloads lives next to the tracks the user already has.
/// Every track has a folder of its own, so the files that belong to it — the
/// audio, the cover and the lyrics — stay together.
///
/// The service owns the layout. The parts of the app that need a file ask
/// for it here, so the place of a file is decided in one spot.
abstract class LibraryPaths {
  /// The preference that holds the folder the user picked.
  static const String rootKey = 'library_folder';

  /// The folder the app puts the files it fetches in.
  ///
  /// It is the music library of the machine, unless the user picked another
  /// folder in the settings.
  ///
  /// The folder is known without waiting: the choice of the user is a
  /// preference that is already read, so the answer is there right away.
  Directory root();

  /// The folder that holds the files of [song].
  ///
  /// A track that is on the disk keeps the folder it is in. A track the app
  /// fetches gets a folder of its own under the root.
  Future<Directory> folderFor(Song song);

  /// The name the files of [song] are named after.
  ///
  /// A track that is on the disk is named after its file, so the cover and
  /// the lyrics sit next to it under the same name.
  String nameFor(Song song);

  /// The file the cover of [song] is written to.
  Future<File> coverFileFor(Song song, String extension);

  /// The file the lyrics of [song] are written to.
  Future<File> lyricsFileFor(Song song);

  /// The folder the covers of the tracks that were not fetched are kept in.
  ///
  /// The covers live in one place, split over subfolders, so a single folder
  /// never holds more than a handful of pictures.
  Directory coverCacheFolder();

  /// The lyrics of [song], when they were written down before.
  ///
  /// The file the reader brought comes first: an explicit choice is stronger
  /// than a file the app matched.
  Future<String?> readLyrics(Song song);

  /// Writes the lyrics of [song] next to its other files.
  ///
  /// These are the lyrics the app matched, so they go to `<歌名>.lrc`.
  Future<void> saveLyrics(Song song, String lyrics);

  /// Writes the lyrics the reader brought for [song].
  ///
  /// The file the app matched is not overwritten: the reader's lyrics go to
  /// `<歌名>.manual.lrc` when `<歌名>.lrc` is taken.
  Future<void> saveChosenLyrics(Song song, String lyrics);

  /// Writes the machine sheet of [song] next to its other files.
  ///
  /// The smart sheet carries its own name (`<歌名>.smart.lrc`), so it never
  /// tops the sheets the reader or the source brought; the reader of the
  /// lyrics falls through to it only when the three segments found nothing.
  Future<void> saveSmartLyrics(Song song, String lyrics);

  /// Reads the machine sheet of [song], when one is there.
  Future<String?> readSmartLyrics(Song song);

  /// Writes the contrasts of [song] next to its other files
  /// (docs/smart-lyrics.md §7.5): the translation and the transliteration
  /// of the sheet, in one small json beside the sheet itself.
  Future<void> saveSmartContrast(Song song, String json);

  /// Reads the contrasts of [song], when any were made.
  Future<String?> readSmartContrast(Song song);

  /// Takes the contrasts of [song] away — the words under them changed, so
  /// what was said about the old ones no longer holds.
  Future<void> clearSmartContrast(Song song);
}
