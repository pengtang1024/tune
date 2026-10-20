import 'package:flutter/material.dart';

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

  /// Whether a single click on a track replaces the play queue.
  ///
  /// When it is off, a click queues the track and plays it right away, so the
  /// queue grows instead of turning into a single song.
  final bool replaceQueueOnClick;

  /// The folder the app writes the files it fetches into.
  ///
  /// It is the music library of the machine, unless the user picked another
  /// folder.
  final String? libraryFolder;

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
      libraryFolder: identical(libraryFolder, _unset)
          ? this.libraryFolder
          : libraryFolder as String?,
      defaultLibraryFolder: defaultLibraryFolder ?? this.defaultLibraryFolder,
    );
  }
}

/// The marker that tells a value apart from one that was not given.
const _unset = Object();
