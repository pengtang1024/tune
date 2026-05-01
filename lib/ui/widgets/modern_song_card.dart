import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/theme/app_design_system.dart';

/// 现代化音乐卡片组件
/// 提供优雅的音乐项显示效果
class ModernSongCard extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onMore;
  final bool isPlaying;
  final bool isSelected;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final bool showAlbumArt;
  final bool showArtist;
  final bool showAlbum;
  final bool showDuration;

  const ModernSongCard({
    super.key,
    required this.song,
    this.onTap,
    this.onPlay,
    this.onMore,
    this.isPlaying = false,
    this.isSelected = false,
    this.width,
    this.height,
    this.margin,
    this.showAlbumArt = true,
    this.showArtist = true,
    this.showAlbum = false,
    this.showDuration = true,
  });

  /// 创建紧凑版本的音乐卡片
  factory ModernSongCard.compact({
    Key? key,
    required Song song,
    VoidCallback? onTap,
    VoidCallback? onPlay,
    bool isPlaying = false,
    bool isSelected = false,
  }) {
    return ModernSongCard(
      key: key,
      song: song,
      onTap: onTap,
      onPlay: onPlay,
      isPlaying: isPlaying,
      isSelected: isSelected,
      height: AppDesignSystem.albumCoverSize56,
      showAlbum: false,
      showDuration: false,
    );
  }

  /// 创建列表版本的音乐卡片
  factory ModernSongCard.list({
    Key? key,
    required Song song,
    VoidCallback? onTap,
    VoidCallback? onPlay,
    VoidCallback? onMore,
    bool isPlaying = false,
    bool isSelected = false,
  }) {
    return ModernSongCard(
      key: key,
      song: song,
      onTap: onTap,
      onPlay: onPlay,
      onMore: onMore,
      isPlaying: isPlaying,
      isSelected: isSelected,
      height: AppDesignSystem.albumCoverSize64,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacing16,
        vertical: AppDesignSystem.spacing4,
      ),
    );
  }

  /// 创建网格版本的音乐卡片
  factory ModernSongCard.grid({
    Key? key,
    required Song song,
    VoidCallback? onTap,
    VoidCallback? onPlay,
    VoidCallback? onMore,
    bool isPlaying = false,
    bool isSelected = false,
  }) {
    return ModernSongCard(
      key: key,
      song: song,
      onTap: onTap,
      onPlay: onPlay,
      onMore: onMore,
      isPlaying: isPlaying,
      isSelected: isSelected,
      width: double.infinity,
      margin: const EdgeInsets.all(AppDesignSystem.spacing4),
      showAlbum: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height ?? AppDesignSystem.albumCoverSize64,
      margin: margin,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppDesignSystem.borderRadius12,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDesignSystem.borderRadius12,
          splashColor: AppDesignSystem.primary.withValues(alpha: 0.1),
          highlightColor: AppDesignSystem.primary.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: AppDesignSystem.duration200,
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppDesignSystem.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: AppDesignSystem.borderRadius12,
              border: isSelected 
                  ? Border.all(color: AppDesignSystem.primary, width: 2)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDesignSystem.spacing8),
              child: Row(
                children: [
                  // 专辑封面区域
                  if (showAlbumArt) ...[
                    _buildAlbumArt(isDark),
                    const SizedBox(width: AppDesignSystem.spacing12),
                  ],
                  
                  // 音乐信息区域
                  Expanded(
                    child: _buildMusicInfo(theme),
                  ),
                  
                  // 控制按钮区域
                  _buildControlButtons(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt(bool isDark) {
    return Container(
      width: height ?? AppDesignSystem.albumCoverSize48,
      height: height ?? AppDesignSystem.albumCoverSize48,
      decoration: BoxDecoration(
        borderRadius: AppDesignSystem.borderRadius8,
        gradient: AppDesignSystem.primaryGradient,
        boxShadow: isPlaying ? AppDesignSystem.shadowColored : AppDesignSystem.shadowLight,
      ),
      child: Stack(
        children: [
          // 背景图片或默认图标
          Center(
            child: song.albumArtPath != null && song.albumArtPath!.isNotEmpty
                ? ClipRRect(
                    borderRadius: AppDesignSystem.borderRadius8,
                    child: Image.file(
                      File(song.albumArtPath!),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAlbumArt();
                      },
                      cacheWidth: 200, // 优化性能，指定缓存宽度
                      cacheHeight: 200, // 优化性能，指定缓存高度
                    ),
                  )
                : _buildDefaultAlbumArt(),
          ),
          
          // 播放状态指示器
          if (isPlaying)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: AppDesignSystem.borderRadius8,
                color: Colors.black.withValues(alpha: 0.3),
              ),
              child: Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: AppDesignSystem.iconSize32,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAlbumArt() {
    return Icon(
      Icons.album_rounded,
      color: Colors.white.withValues(alpha: 0.8),
      size: AppDesignSystem.iconSize32,
    );
  }

  Widget _buildMusicInfo(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 歌曲标题
        Text(
          song.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: AppDesignSystem.fontWeightMedium,
            color: isPlaying 
                ? AppDesignSystem.primary
                : (isDark ? AppDesignSystem.neutral100 : AppDesignSystem.neutral900),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: AppDesignSystem.spacing2),
        
        // 艺术家名称
        if (showArtist)
          Text(
            song.artist,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark 
                  ? AppDesignSystem.neutral400 
                  : AppDesignSystem.neutral600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        
        // 专辑名称和时长
        if (showAlbum || showDuration) ...[
          const SizedBox(height: AppDesignSystem.spacing2),
          Row(
            children: [
              if (showAlbum) ...[
                Expanded(
                  child: Text(
                    song.album,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark 
                          ? AppDesignSystem.neutral500 
                          : AppDesignSystem.neutral500,
                      fontSize: AppDesignSystem.fontSize11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (showDuration) ...[
                if (showAlbum) const SizedBox(width: AppDesignSystem.spacing8),
                Text(
                  _formatDuration(Duration(milliseconds: song.duration)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark 
                        ? AppDesignSystem.neutral500 
                        : AppDesignSystem.neutral500,
                    fontSize: AppDesignSystem.fontSize11,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildControlButtons(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 播放按钮
        if (onPlay != null)
          Container(
            margin: const EdgeInsets.only(right: AppDesignSystem.spacing4),
            child: Material(
              color: Colors.transparent,
              borderRadius: AppDesignSystem.borderRadius20,
              child: InkWell(
                onTap: onPlay,
                borderRadius: AppDesignSystem.borderRadius20,
                child: Container(
                  width: AppDesignSystem.iconSize32,
                  height: AppDesignSystem.iconSize32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppDesignSystem.primary.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: AppDesignSystem.iconSize20,
                    color: AppDesignSystem.primary,
                  ),
                ),
              ),
            ),
          ),
        
        // 更多操作按钮
        if (onMore != null)
          Material(
            color: Colors.transparent,
            borderRadius: AppDesignSystem.borderRadius20,
            child: InkWell(
              onTap: onMore,
              borderRadius: AppDesignSystem.borderRadius20,
              child: SizedBox(
                width: AppDesignSystem.iconSize32,
                height: AppDesignSystem.iconSize32,
                child: Icon(
                  Icons.more_vert_rounded,
                  size: AppDesignSystem.iconSize20,
                  color: theme.iconTheme.color?.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}