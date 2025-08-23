import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/settings/states/account_settings_state.dart';
import 'package:tune/ui/core/settings/states/account_settings_state_notifier.dart';

/// 账户设置状态提供者
final accountSettingsProvider = StateNotifierProvider<AccountSettingsStateNotifier, AccountSettingsState>(
  (ref) => AccountSettingsStateNotifier(ref),
);