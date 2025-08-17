import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/settings/states/settings_state_notifier.dart';
import 'package:tune/ui/core/settings/states/settings_state.dart';

final settingsStateNotifierProvider =
    StateNotifierProvider<SettingsStateNotifier, SettingsState>((ref) {
  return SettingsStateNotifier();
});