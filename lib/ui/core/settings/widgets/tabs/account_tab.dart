import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/core/settings/providers/account_settings_provider.dart';

/// 账户设置标签页
class AccountTab extends ConsumerWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountSettingsProvider);
    final notifier = ref.read(accountSettingsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.account_settings, // 使用本地化字符串
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: TextEditingController(text: state.username),
            decoration: InputDecoration(
              labelText: context.loc.username, // 使用本地化字符串
              border: const OutlineInputBorder(),
            ),
            onChanged: notifier.updateUsername,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: TextEditingController(text: state.email),
            decoration: InputDecoration(
              labelText: context.loc.email, // 使用本地化字符串
              border: const OutlineInputBorder(),
            ),
            onChanged: notifier.updateEmail,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                context.loc.auto_login, // 使用本地化字符串
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Switch(
                value: state.autoLogin,
                onChanged: (bool value) {
                  notifier.toggleAutoLogin();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                context.loc.save_password, // 使用本地化字符串
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Switch(
                value: state.savePassword,
                onChanged: (bool value) {
                  notifier.toggleSavePassword();
                },
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                notifier.saveSettings();
                // 显示保存成功的提示
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.loc.settings_saved)),
                );
              },
              child: Text(context.loc.save), // 使用本地化字符串
            ),
          ),
        ],
      ),
    );
  }
}