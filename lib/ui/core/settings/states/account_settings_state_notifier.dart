import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/ui/core/settings/states/account_settings_state.dart';
import 'package:tune/utils/logger.dart';

/// 账户设置状态管理器
class AccountSettingsStateNotifier extends StateNotifier<AccountSettingsState> {
  final Ref _ref;

  AccountSettingsStateNotifier(this._ref) : super(AccountSettingsState.initial());

  /// 更新用户名
  void updateUsername(String username) {
    state = state.copyWith(username: username);
  }

  /// 更新邮箱
  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  /// 切换自动登录
  void toggleAutoLogin() {
    state = state.copyWith(autoLogin: !state.autoLogin);
  }

  /// 切换保存密码
  void toggleSavePassword() {
    state = state.copyWith(savePassword: !state.savePassword);
  }

  /// 保存设置
  void saveSettings() {
    try {
      final persistenceService = _ref.read(sharedPreferencesServiceProvider);
      persistenceService.setString('account_username', state.username);
      persistenceService.setString('account_email', state.email);
      persistenceService.setBool('account_auto_login', state.autoLogin);
      persistenceService.setBool('account_save_password', state.savePassword);
    } catch (e) {
      // 错误处理，但不中断主流程
      Log.error('保存账户设置失败: $e');
    }
  }
}