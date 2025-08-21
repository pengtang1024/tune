import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/settings/states/account_settings_state.dart';

/// 账户设置状态管理器
class AccountSettingsStateNotifier extends StateNotifier<AccountSettingsState> {
  AccountSettingsStateNotifier() : super(AccountSettingsState.initial());

  /// 更新用户名
  void updateUsername(String username) {
    state = state.copyWith(username: username);
  }

  /// 更新邮箱
  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  /// 更新自动登录设置
  void updateAutoLogin(bool autoLogin) {
    state = state.copyWith(autoLogin: autoLogin);
  }

  /// 更新保存密码设置
  void updateSavePassword(bool savePassword) {
    state = state.copyWith(savePassword: savePassword);
  }

  /// 保存设置
  void saveSettings() {
    // TODO: 实现保存设置到持久化存储的逻辑
  }
}