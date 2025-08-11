import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:tune/app/router/app_router.dart';
import 'package:tune/l10n/app_localizations.dart';

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
                      localizations.username_default,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.user_email_default,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 分割线
          const Divider(),

          // 功能选项列表
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(localizations.settings_title),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              context.pushRoute(const SettingsRoute());
            },
          ),

          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('播放历史'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: 跳转到播放历史页面
            },
          ),

          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('我的收藏'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: 跳转到收藏页面
            },
          ),

          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('下载管理'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: 跳转到下载页面
            },
          ),
        ],
      ),
    );
  }
}
