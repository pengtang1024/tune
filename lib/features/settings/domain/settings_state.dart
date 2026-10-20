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

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('en'),
    this.defaultScanPaths = const [],
    this.customScanPaths = const [],
    this.autoScanOnStartup = true,
    this.closeToTray = true,
    this.mediaControlsEnabled = true,
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
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      defaultScanPaths: defaultScanPaths ?? this.defaultScanPaths,
      customScanPaths: customScanPaths ?? this.customScanPaths,
      autoScanOnStartup: autoScanOnStartup ?? this.autoScanOnStartup,
      closeToTray: closeToTray ?? this.closeToTray,
      mediaControlsEnabled: mediaControlsEnabled ?? this.mediaControlsEnabled,
    );
  }
}
