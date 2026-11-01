import 'package:flutter/material.dart';
import 'package:tune/domain/models/source_health_weights.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_config.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final List<String> defaultScanPaths;
  final List<String> customScanPaths;
  final bool autoScanOnStartup;

  /// Whether closing the window only hides it, so the playback continues.
  final bool closeToTray;

  /// Whether the player shows up in the media controls of the system.
  final bool mediaControlsEnabled;

  /// Whether a start picks up playing where the last run stopped.
  ///
  /// The queue and the position are always restored; the switch only
  /// decides whether the restored track plays on by itself instead of
  /// waiting, paused, for the reader to press play.
  final bool autoResumeOnStartup;

  /// Whether a single click on a track replaces the play queue.
  ///
  /// When it is off, a click queues the track and plays it right away, so the
  /// queue grows instead of turning into a single song.
  final bool replaceQueueOnClick;

  /// Whether a double click on a track only marks it as a favorite.
  ///
  /// A double click plays the track as well, because the first click of it
  /// plays the track already. When this is on the double click leaves the
  /// music alone and only adds the heart: a double click never takes a mark
  /// away, that is the single click on the heart.
  final bool onlyLikeOnDoubleClick;

  /// Whether a double click in the favorites page plays the track and
  /// replaces the play queue.
  ///
  /// The favorites page is the one list where the reader usually wants to
  /// hear the track now; this switch keeps that the default and lets the
  /// reader fall back to the old "double click only likes" behavior.
  final bool favoritesDoubleClickPlays;

  /// The folder the app writes the files it fetches into.
  ///
  /// It is the music library of the machine, unless the user picked another
  /// folder.
  final String? libraryFolder;

  /// Whether the folded group of the sources needs a key is open.
  ///
  /// The sources that ask for a key wait in a folded section, so they do
  /// not push the ones that work right away out of sight. The reader opens
  /// the section once and it stays open.
  final bool sourcesMoreExpanded;

  /// The weights of the dimensions of the source health score.
  final SourceHealthWeights sourceHealthWeights;

  /// What the reader pasted for the smart lyrics pipeline.
  final SmartLyricsConfig smartLyrics;

  /// Whether the discover page may learn from the tracks that were played.
  ///
  /// It is off by default: the page works from the hearts and the metadata
  /// alone until the reader asks for the extra signal.
  final bool useListeningHistory;

  /// The music library of the machine.
  final String defaultLibraryFolder;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('en'),
    this.defaultScanPaths = const [],
    this.customScanPaths = const [],
    this.autoScanOnStartup = true,
    this.closeToTray = true,
    this.mediaControlsEnabled = true,
    this.replaceQueueOnClick = false,
    this.onlyLikeOnDoubleClick = false,
    this.favoritesDoubleClickPlays = true,
    this.autoResumeOnStartup = true,
    this.sourcesMoreExpanded = false,
    this.sourceHealthWeights = SourceHealthWeights.defaults,
    this.smartLyrics = const SmartLyricsConfig(),
    this.useListeningHistory = false,
    this.libraryFolder,
    this.defaultLibraryFolder = '',
  });

  /// Default music folders plus user folders, de-duplicated.
  List<String> get effectiveScanPaths {
    return <String>{...defaultScanPaths, ...customScanPaths}.toList();
  }

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    List<String>? defaultScanPaths,
    List<String>? customScanPaths,
    bool? autoScanOnStartup,
    bool? closeToTray,
    bool? mediaControlsEnabled,
    bool? replaceQueueOnClick,
    bool? onlyLikeOnDoubleClick,
    bool? favoritesDoubleClickPlays,
    bool? autoResumeOnStartup,
    bool? sourcesMoreExpanded,
    SourceHealthWeights? sourceHealthWeights,
    SmartLyricsConfig? smartLyrics,
    bool? useListeningHistory,
    Object? libraryFolder = _unset,
    String? defaultLibraryFolder,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      defaultScanPaths: defaultScanPaths ?? this.defaultScanPaths,
      customScanPaths: customScanPaths ?? this.customScanPaths,
      autoScanOnStartup: autoScanOnStartup ?? this.autoScanOnStartup,
      closeToTray: closeToTray ?? this.closeToTray,
      mediaControlsEnabled: mediaControlsEnabled ?? this.mediaControlsEnabled,
      replaceQueueOnClick: replaceQueueOnClick ?? this.replaceQueueOnClick,
      onlyLikeOnDoubleClick:
          onlyLikeOnDoubleClick ?? this.onlyLikeOnDoubleClick,
      favoritesDoubleClickPlays:
          favoritesDoubleClickPlays ?? this.favoritesDoubleClickPlays,
      autoResumeOnStartup: autoResumeOnStartup ?? this.autoResumeOnStartup,
      sourcesMoreExpanded: sourcesMoreExpanded ?? this.sourcesMoreExpanded,
      sourceHealthWeights: sourceHealthWeights ?? this.sourceHealthWeights,
      smartLyrics: smartLyrics ?? this.smartLyrics,
      useListeningHistory: useListeningHistory ?? this.useListeningHistory,
      libraryFolder: identical(libraryFolder, _unset)
          ? this.libraryFolder
          : libraryFolder as String?,
      defaultLibraryFolder: defaultLibraryFolder ?? this.defaultLibraryFolder,
    );
  }
}

/// The marker that tells a value apart from one that was not given.
const _unset = Object();
