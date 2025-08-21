

/// 账户设置状态
class AccountSettingsState {
  final String username;
  final String email;
  final bool autoLogin;
  final bool savePassword;

  AccountSettingsState({
    required this.username,
    required this.email,
    required this.autoLogin,
    required this.savePassword,
  });

  /// 创建初始状态
  static AccountSettingsState initial() {
    return AccountSettingsState(
      username: '',
      email: '',
      autoLogin: false,
      savePassword: false,
    );
  }

  /// 创建副本并更新指定字段
  AccountSettingsState copyWith({
    String? username,
    String? email,
    bool? autoLogin,
    bool? savePassword,
  }) {
    return AccountSettingsState(
      username: username ?? this.username,
      email: email ?? this.email,
      autoLogin: autoLogin ?? this.autoLogin,
      savePassword: savePassword ?? this.savePassword,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountSettingsState &&
        other.username == username &&
        other.email == email &&
        other.autoLogin == autoLogin &&
        other.savePassword == savePassword;
  }

  @override
  int get hashCode => Object.hash(
        username,
        email,
        autoLogin,
        savePassword,
      );
}
