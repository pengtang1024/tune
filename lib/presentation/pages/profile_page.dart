import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/core/routes/app_router.dart';

/// 个人页面
///
/// 显示用户个人信息和相关设置选项
@RoutePage()
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.profile_title),
      ),
      body: ListView(
        children: [
          // 用户信息区域
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // 用户头像
                const CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person, size: 30),
                ),
                const SizedBox(width: 16),
                // 用户名
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.profile_default_username,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.profile_default_user_email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // 设置选项
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(localizations.settings_title),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              context.pushRoute(const SettingsRoute());
            },
          ),
          
          // 其他可能的选项可以在这里添加
        ],
      ),
    );
  }
}