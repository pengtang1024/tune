import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/notifications/providers/notification_providers.dart';
import 'package:tune/ui/notifications/states/notification_state.dart';
import 'package:tune/ui/widgets/modern_button.dart';
import 'package:tune/ui/widgets/modern_card.dart';
import 'package:tune/ui/theme/app_design_system.dart';

/// 现代化欢迎页面组件
/// 显示应用的欢迎信息和标语，具有优美的视觉效果
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 添加测试通知的方法
    void addTestNotification(NotificationType type) {
      final notificationNotifier = ref.read(notificationStateNotifierProvider.notifier);
      String title;
      String content;
      IconData icon;

      switch (type) {
        case NotificationType.important:
          title = '重要通知';
          content = '这是一条重要通知，包含关键信息！';
          icon = Icons.warning_rounded;
          break;
        case NotificationType.system:
          title = '系统通知';
          content = '系统更新已完成，新版本提供了更多功能。';
          icon = Icons.system_update_rounded;
          break;
        case NotificationType.message:
          title = '消息通知';
          content = '您收到了一条新消息，请查看！';
          icon = Icons.message_rounded;
          break;
        case NotificationType.update:
          title = '更新通知';
          content = '应用有新版本可用，建议及时更新。';
          icon = Icons.refresh_rounded;
          break;
        case NotificationType.normal:
          title = '普通通知';
          content = '这是一条普通通知，包含一般信息。';
          icon = Icons.info_rounded;
          break;
      }

      notificationNotifier.addNotification(
        NotificationData(
          id: DateTime.now().millisecondsSinceEpoch,
          title: title,
          content: content,
          type: type,
          timestamp: DateTime.now(),
          icon: icon,
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
              ? AppDesignSystem.backgroundGradientDark
              : AppDesignSystem.backgroundGradientLight,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDesignSystem.spacing24),
            child: Column(
              children: [
                // 顶部装饰区域
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 音乐图标动画容器
                        Container(
                          width: AppDesignSystem.albumCoverSize160,
                          height: AppDesignSystem.albumCoverSize160,
                          decoration: BoxDecoration(
                            gradient: AppDesignSystem.primaryGradient,
                            borderRadius: BorderRadius.circular(
                              AppDesignSystem.albumCoverSize160 / 2,
                            ),
                            boxShadow: AppDesignSystem.shadowColored,
                          ),
                          child: Icon(
                            Icons.music_note_rounded,
                            size: AppDesignSystem.iconSize80,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: AppDesignSystem.spacing32),
                        
                        // 应用标题
                        Text(
                          '欢迎使用 Tune',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: AppDesignSystem.fontWeightBold,
                            color: isDark 
                                ? AppDesignSystem.neutral100 
                                : AppDesignSystem.neutral900,
                          ),
                        ),
                        
                        const SizedBox(height: AppDesignSystem.spacing12),
                        
                        // 副标题
                        Text(
                          '让每一段旋律都找到归属',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isDark 
                                ? AppDesignSystem.neutral400 
                                : AppDesignSystem.neutral600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        
                        const SizedBox(height: AppDesignSystem.spacing8),
                        
                        // 更详细的描述
                        Text(
                          '在喧嚣的日常里，总有一些旋律会悄悄住进心里',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark 
                                ? AppDesignSystem.neutral500 
                                : AppDesignSystem.neutral500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 底部功能区域
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // 功能介绍卡片
                      ModernCard(
                        padding: const EdgeInsets.all(AppDesignSystem.spacing20),
                        margin: const EdgeInsets.only(bottom: AppDesignSystem.spacing24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '开始您的音乐之旅',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: AppDesignSystem.fontWeightSemiBold,
                              ),
                            ),
                            const SizedBox(height: AppDesignSystem.spacing12),
                            _buildFeatureItem(
                              icon: Icons.library_music_rounded,
                              title: '音乐库管理',
                              description: '轻松整理本地音乐库',
                            ),
                            _buildFeatureItem(
                              icon: Icons.playlist_play_rounded,
                              title: '智能歌单',
                              description: '按风格和心情自定义',
                            ),
                            _buildFeatureItem(
                              icon: Icons.graphic_eq_rounded,
                              title: '音效调节',
                              description: '让音符更加饱满清晰',
                            ),
                          ],
                        ),
                      ),
                      
                      // 测试按钮区域
                      ModernCard(
                        padding: const EdgeInsets.all(AppDesignSystem.spacing20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '测试功能',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: AppDesignSystem.fontWeightSemiBold,
                              ),
                            ),
                            const SizedBox(height: AppDesignSystem.spacing16),
                            
                            ModernButton.primary(
                              text: '添加普通通知',
                              onPressed: () => addTestNotification(NotificationType.normal),
                              isFullWidth: true,
                            ),
                            const SizedBox(height: AppDesignSystem.spacing12),
                            
                            ModernButton.secondary(
                              text: '添加重要通知',
                              onPressed: () => addTestNotification(NotificationType.important),
                              isFullWidth: true,
                            ),
                            const SizedBox(height: AppDesignSystem.spacing12),
                            
                            ModernButton.outline(
                              text: '添加系统通知',
                              onPressed: () => addTestNotification(NotificationType.system),
                              isFullWidth: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignSystem.spacing12),
      child: Row(
        children: [
          Container(
            width: AppDesignSystem.iconSize32,
            height: AppDesignSystem.iconSize32,
            decoration: BoxDecoration(
              color: AppDesignSystem.primary.withValues(alpha: 0.1),
              borderRadius: AppDesignSystem.borderRadius8,
            ),
            child: Icon(
              icon,
              size: AppDesignSystem.iconSize20,
              color: AppDesignSystem.primary,
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppDesignSystem.fontSize14,
                    fontWeight: AppDesignSystem.fontWeightMedium,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: AppDesignSystem.fontSize12,
                    color: AppDesignSystem.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
