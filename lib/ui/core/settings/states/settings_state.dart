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