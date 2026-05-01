import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/widgets/player_content.dart';
import 'package:tune/ui/player/widgets/player_controls.dart';
import 'package:tune/ui/player/widgets/player_history.dart';
import 'package:tune/ui/player/widgets/player_options.dart';
import 'package:tune/ui/player/widgets/player_progress.dart';
import 'package:tune/ui/widgets/modern_card.dart';
import 'package:tune/ui/widgets/modern_button.dart';
import 'package:tune/ui/theme/app_design_system.dart';

/// 现代化播放器页面
/// 提供沉浸式的音乐播放体验
class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F0F0F),
                    Color(0xFF1A1A1A),
                    Color(0xFF2D1B69),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF8FAFC),
                    Color(0xFFF1F5F9),
                    Color(0xFFE0E7FF),
                  ],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部导航栏
              _buildTopAppBar(context, playerState),
              
              // 错误状态显示
              if (playerState.isError)
                Padding(
                  padding: const EdgeInsets.all(AppDesignSystem.spacing16),
                  child: ModernCard(
                    backgroundColor: AppDesignSystem.error.withValues(alpha: 0.1),
                    borderSide: BorderSide(color: AppDesignSystem.error.withValues(alpha: 0.3)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.error_rounded,
                                color: AppDesignSystem.error,
                                size: AppDesignSystem.iconSize24,
                              ),
                              const SizedBox(width: AppDesignSystem.spacing12),
                              Expanded(
                                child: Text(
                                  '播放错误',
                                  style: TextStyle(
                                    color: AppDesignSystem.error,
                                    fontWeight: AppDesignSystem.fontWeightSemiBold,
                                    fontSize: AppDesignSystem.fontSize16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDesignSystem.spacing8),
                          Text(
                            playerState.errorMessage,
                            style: TextStyle(
                              color: AppDesignSystem.error,
                              fontSize: AppDesignSystem.fontSize14,
                            ),
                          ),
                          const SizedBox(height: AppDesignSystem.spacing16),
                          ModernButton.primary(
                            text: '重试',
                            onPressed: () {
                              if (playerState.currentSong != null) {
                                playerNotifier.playSong(playerState.currentSong!);
                              }
                            },
                            isFullWidth: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // 专辑封面和歌曲信息
              Expanded(
                child: playerState.isLoading || playerState.isError
                    ? _buildLoadingState()
                    : const PlayerContent(),
              ),
              
              // 播放控制
              if (!playerState.isLoading && !playerState.isError) ...[
                const SizedBox(height: AppDesignSystem.spacing20),
                const PlayerProgress(),
                const SizedBox(height: AppDesignSystem.spacing24),
                const PlayerControls(),
                const SizedBox(height: AppDesignSystem.spacing24),
                const PlayerOptions(),
                const SizedBox(height: AppDesignSystem.spacing20),
                const PlayerHistory(),
                const SizedBox(height: AppDesignSystem.spacing16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, dynamic playerState) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      child: Row(
        children: [
          // 返回按钮
          ModernCard.bordered(
            padding: const EdgeInsets.all(AppDesignSystem.spacing8),
            borderColor: Colors.transparent,
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.iconTheme.color,
              size: AppDesignSystem.iconSize28,
            ),
          ),
          
          const Spacer(),
          
          // 歌曲信息（如果有的话）
          if (playerState.currentSong != null) ...[
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    '正在播放',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.iconTheme.color?.withValues(alpha: 0.7),
                      fontSize: AppDesignSystem.fontSize12,
                    ),
                  ),
                  const SizedBox(height: AppDesignSystem.spacing2),
                  Text(
                    playerState.currentSong?.title ?? '',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: AppDesignSystem.fontWeightMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          
          const Spacer(),
          
          // 更多选项按钮
          ModernCard.bordered(
            padding: const EdgeInsets.all(AppDesignSystem.spacing8),
            borderColor: Colors.transparent,
            onTap: () {
              // TODO: 显示更多选项
            },
            child: Icon(
              Icons.more_vert_rounded,
              color: theme.iconTheme.color,
              size: AppDesignSystem.iconSize24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: AppDesignSystem.albumCoverSize240,
            height: AppDesignSystem.albumCoverSize240,
            decoration: BoxDecoration(
              color: AppDesignSystem.neutral200,
              borderRadius: AppDesignSystem.borderRadius24,
              boxShadow: AppDesignSystem.shadowMedium,
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppDesignSystem.primary),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing24),
          Text(
            '加载中...',
            style: TextStyle(
              color: AppDesignSystem.neutral500,
              fontSize: AppDesignSystem.fontSize16,
              fontWeight: AppDesignSystem.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }
}