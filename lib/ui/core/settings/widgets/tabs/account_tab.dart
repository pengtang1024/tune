import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/core/settings/providers/account_settings_provider.dart';

class AccountTab extends ConsumerWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountSettingsProvider);
    final notifier = ref.read(accountSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.settings),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc.account_settings, // 使用本地化字符串
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: TextEditingController(text: state.username),
              decoration: InputDecoration(
                labelText: context.loc.username,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => notifier.updateUsername(value),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: TextEditingController(text: state.email),
              decoration: InputDecoration(
                labelText: context.loc.email,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => notifier.updateEmail(value),
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
                    notifier.updateAutoLogin(value);
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
                    notifier.updateSavePassword(value);
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.loc.account_settings_saved)), // 使用本地化字符串
                  );
                },
                child: Text(context.loc.save), // 使用本地化字符串
              ),
            ),
          ],
        ),
      ),
    );
  }
}
