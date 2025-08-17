import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/settings/states/settings_state.dart';
import 'package:tune/ui/core/settings/states/settings_state_notifier.dart';

final settingsStateNotifierProvider =
    StateNotifierProvider<SettingsStateNotifier, SettingsState>((ref) {
  return SettingsStateNotifier();
});
