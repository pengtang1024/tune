import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final int selectedTabIndex;

  SettingsState({
    this.selectedTabIndex = 0,
  });

  SettingsState copyWith({
    int? selectedTabIndex,
  }) {
    return SettingsState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }

  static SettingsState initial() {
    return SettingsState();
  }
}

class SettingsViewModel extends StateNotifier<SettingsState> {
  SettingsViewModel() : super(SettingsState.initial());

  void updateSelectedTab(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }
}