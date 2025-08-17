import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/settings/states/settings_state.dart';

class SettingsStateNotifier extends StateNotifier<SettingsState> {
  SettingsStateNotifier() : super(SettingsState.initial());

  void updateSelectedTab(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }
}