import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/settings/view_model/settings_view_model.dart';

final settingsViewModelProvider = StateNotifierProvider<SettingsViewModel, SettingsState>((ref) {
  return SettingsViewModel();
});