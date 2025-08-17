import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/ui/core/layout/providers/app_bar_providers.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/widgets/animation/playing_state_animation.dart';
import 'package:url_launcher/url_launcher.dart';

/// 自定义AppBar组件
/// 实现全局唯一的标题栏，所有页面共享同一实例
class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarState = ref.watch(appBarStateNotifierProvider);
    final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);

    return AppBar(
      // 标题
      title: Text(
        appBarState.title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // 返回按钮（仅在二级页面显示）
      leading: appBarState.showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // 使用GoRouter返回上一页
                if (GoRouter.of(context).canPop()) {
                  GoRouter.of(context).pop();
                } else {
                  // 如果无法使用GoRouter返回，则导航到首页
                  context.go('/');
                }
              },
            )
          : null,

      // 操作按钮
      actions: [
        // 动态按钮（最右侧，从右到左排列）
        ...appBarState.dynamicActions,

        // GitHub按钮（动态按钮左侧）
        IconButton(
          icon: const Icon(Icons.code),
          tooltip: '访问 GitHub',
          onPressed: () async {
            final Uri url = Uri.parse('https://github.com');
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            } else {
              // 添加错误提示
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('无法打开 GitHub 链接')),
                );
              }
            }
          },
        ),

        // 播放按钮（GitHub按钮左侧）
        _buildPlayButton(ref),

        // 本地化按钮（播放按钮左侧）
        IconButton(
          icon: const Icon(Icons.g_translate),
          tooltip: '切换语言',
          onPressed: () {
            _showLanguageSelectionDialog(context, ref);
          },
        ),

        // 主题切换按钮（本地化按钮左侧）
        IconButton(
          icon: Icon(_getThemeIcon(appBarState.themeMode)),
          tooltip:switch (appBarState.themeMode) {
            ThemeMode.light => '切换到深色模式',
            ThemeMode.dark => '切换到跟随系统',
            ThemeMode.system => '切换到浅色模式',
          },
          onPressed: () {
            appBarNotifier.toggleThemeMode();
          },
        ),

        // "我的"按钮（最左侧，但显示在最右边）
        PopupMenuButton<String>(
          icon: const Icon(Icons.person),
          tooltip: '我的',
          onSelected: (String result) {
            switch (result) {
              case 'settings':
                context.go('/settings');
                break;
              // 可以添加更多选项
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'profile',
              enabled: false,
              child: _buildUserProfile(appBarState),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'settings',
              child: Text('设置'),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建播放按钮
  Widget _buildPlayButton(WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    final appBarState = ref.watch(appBarStateNotifierProvider);
    final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);

    // 根据播放状态和悬停状态确定图标
    Widget getPlayIcon() {
      if (appBarState.isPlayButtonHovered) {
        // 悬停状态
        if (playerState.isPlaying) {
          return const Icon(Icons.pause); // 播放状态悬停显示暂停图标
        } else {
          return const Icon(Icons.play_arrow); // 暂停/停止状态悬停显示播放图标
        }
      } else {
        // 常态
        if (playerState.isPlaying) {
          // 播放状态显示播放中动画
          return const PlayingStateAnimation(isPlaying: true);
        } else {
          return const Icon(Icons.play_arrow); // 暂停/停止状态显示播放图标
        }
      }
    }

    return MouseRegion(
      onEnter: (_) {
        // 鼠标悬停时更新状态
        appBarNotifier.setPlayButtonHover(true);
      },
      onExit: (_) {
        // 鼠标离开时更新状态
        appBarNotifier.setPlayButtonHover(false);
      },
      child: GestureDetector(
        onLongPress: () {
          // 长按停止播放
          playerNotifier.stop();
        },
        child: IconButton(
          icon: getPlayIcon(),
          tooltip: playerState.isPlaying ? '暂停' : '播放',
          onPressed: () {
            // 点击切换播放状态
            if (playerState.isPlaying) {
              playerNotifier.pause();
            } else {
              playerNotifier.play();
            }
          },
        ),
      ),
    );
  }

  /// 构建用户个人信息区域
  Widget _buildUserProfile(dynamic state) {
    return SizedBox(
      width: 250,
      child: Row(
        children: [
          // 用户头像
          CircleAvatar(
            radius: 20,
            backgroundImage: state.userAvatarUrl != null
                ? NetworkImage(state.userAvatarUrl!)
                : null,
            child: state.userAvatarUrl == null
                ? const Icon(Icons.person, size: 20)
                : null,
          ),
          const SizedBox(width: 10),
          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 用户名和等级
                Row(
                  children: [
                    Text(
                      state.username ?? '未知用户',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 5),
                    if (state.userLevel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Lv.${state.userLevel}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                // 用户标签
                if (state.userTags.isNotEmpty)
                  Wrap(
                    spacing: 5,
                    runSpacing: 3,
                    children: state.userTags.map<Widget>((tag) {
                      Color tagColor = Colors.grey;
                      if (tag == 'vip') {
                        tagColor = Colors.red;
                      } else if (tag == '歌手') {
                        tagColor = Colors.green;
                      } else if (tag == '精英') {
                        tagColor = Colors.purple;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tagColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 根据主题模式获取对应的图标
  IconData _getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.auto_mode;
    }
  }

  /// 显示语言选择对话框
  void _showLanguageSelectionDialog(BuildContext context, WidgetRef ref) {
    final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);
    final currentLocale = ref.read(appBarStateNotifierProvider).locale;
    final supportedLocales = ref.read(appBarStateNotifierProvider).supportedLocales;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择语言'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: supportedLocales.map((Locale locale) {
                return RadioListTile<Locale>(
                  title: Builder(
                    builder: (context) {
                      return Text(_getLocaleDisplayName(locale, context));
                    }
                  ),
                  value: locale,
                  groupValue: currentLocale,
                  onChanged: (Locale? value) {
                    if (value != null) {
                      appBarNotifier.switchLanguage(value);
                      Navigator.of(context).pop();
                    }
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  /// 获取语言显示名称（基于flutter_localizations）
  String _getLocaleDisplayName(Locale locale, BuildContext context) {
    // 使用flutter_localizations提供的方法获取本地化名称
    final displayName = locale.toString();
    try {
      // 尝试获取本地化的语言名称
      final localizations = AppLocalizations.of(context);
      if (localizations != null) {
        // 根据语言代码返回对应的本地化名称
        switch (locale.languageCode) {
          case 'en':
            return '$displayName 英语';
          case 'zh':
            if (locale.countryCode == 'CN') {
              return '$displayName 简体中文';
            }
            return '$displayName 中文';
          default:
            return '$displayName ${locale.languageCode}';
        }
      }
    } catch (e) {
      // 如果出现异常，返回默认格式
      return displayName;
    }

    return displayName;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
