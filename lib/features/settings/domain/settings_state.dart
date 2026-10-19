import 'package:flutter/material.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final List<String> defaultScanPaths;
  final List<String> customScanPaths;
  final bool autoScanOnStartup;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('en'),
    this.defaultScanPaths = const [],
    this.customScanPaths = const [],
    this.autoScanOnStartup = true,
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
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      defaultScanPaths: defaultScanPaths ?? this.defaultScanPaths,
      customScanPaths: customScanPaths ?? this.customScanPaths,
      autoScanOnStartup: autoScanOnStartup ?? this.autoScanOnStartup,
    );
  }
}
