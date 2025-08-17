import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/widgets/animation/album_rotation_animation.dart';
import 'package:tune/ui/widgets/animation/album_swing_animation.dart';
import 'package:tune/ui/widgets/animation/note_bouncing_animation.dart';
import 'package:tune/ui/widgets/animation/volume_bubble_animation.dart';
import 'package:tune/ui/widgets/animation/play_button_breathing_animation.dart';
import 'package:tune/ui/widgets/animation/play_pause_rotation_animation.dart';
import 'package:tune/ui/widgets/animation/circular_spectrum_animation.dart';
import 'package:tune/ui/widgets/animation/spectrum_waterfall_animation.dart';
import 'package:tune/ui/widgets/animation/audio_wave_elastic_animation.dart';
import 'package:tune/ui/widgets/animation/particle_album_aggregation_animation.dart';
import 'package:tune/ui/widgets/animation/share_button_particle_animation.dart';
import 'package:tune/ui/widgets/animation/download_progress_fill_animation.dart';
import 'package:tune/ui/widgets/animation/favorite_button_explosion_animation.dart';
import 'package:tune/ui/widgets/animation/volume_ripple_bars_animation.dart';
import 'package:tune/ui/widgets/animation/lyrics_highlight_animation.dart';
import 'package:tune/ui/widgets/animation/audio_peak_blast_animation.dart';
import 'package:tune/ui/widgets/animation/cube_spectrum_animation.dart';
import 'package:tune/ui/widgets/animation/equalizer_knob_animation.dart';
import 'package:tune/ui/widgets/animation/album_floating_animation.dart';
import 'package:tune/ui/widgets/animation/album_page_flip_animation.dart';
import 'package:tune/ui/widgets/animation/audio_peak_explosion_animation.dart';
import 'package:tune/ui/widgets/animation/audio_peak_fireworks_animation.dart';
import 'package:tune/ui/widgets/animation/favorite_button_rotation_fill_animation.dart';
import 'package:tune/ui/widgets/animation/loading_dot_bounce_animation.dart';
import 'package:tune/ui/widgets/animation/loading_gear_animation.dart';
import 'package:tune/ui/widgets/animation/loading_note_rotation_animation.dart';
import 'package:tune/ui/widgets/animation/loading_sound_wave_animation.dart';
import 'package:tune/ui/widgets/animation/lyrics_gradient_animation.dart';
import 'package:tune/ui/widgets/animation/lyrics_line_scale_animation.dart';
import 'package:tune/ui/widgets/animation/lyrics_word_bounce_animation.dart';
import 'package:tune/ui/widgets/animation/note_collision_stack_animation.dart';
import 'package:tune/ui/widgets/animation/note_rain_animation.dart';
import 'package:tune/ui/widgets/animation/note_sine_wave_animation.dart';
import 'package:tune/ui/widgets/animation/note_spiral_animation.dart';
import 'package:tune/ui/widgets/animation/page_dissolve_transition_animation.dart';
import 'package:tune/ui/widgets/animation/particle_grid_wave_animation.dart';
import 'package:tune/ui/widgets/animation/particle_vortex_animation.dart';
import 'package:tune/ui/widgets/animation/particle_wave_flow_animation.dart';
import 'package:tune/ui/widgets/animation/pause_button_ripple_animation.dart';
import 'package:tune/ui/widgets/animation/play_button_fill_animation.dart';
import 'package:tune/ui/widgets/animation/play_state_pulse_animation.dart';
import 'package:tune/ui/widgets/animation/progress_bar_segmented_loading_animation.dart';
import 'package:tune/ui/widgets/animation/progress_pulse_animation.dart';
import 'package:tune/ui/widgets/animation/progress_time_scroll_animation.dart';
import 'package:tune/ui/widgets/animation/ripple_diffusion_animation.dart';
import 'package:tune/ui/widgets/animation/sector_spectrum_animation.dart';
import 'package:tune/ui/widgets/animation/spectrum_3d_sphere_animation.dart';
import 'package:tune/ui/widgets/animation/spectrum_flash_animation.dart';
import 'package:tune/ui/widgets/animation/volume_sector_expand_animation.dart';
import 'package:tune/ui/widgets/animation/waveform_grid_animation.dart';
import 'package:tune/ui/widgets/animation/album_cover_rotation_animation.dart';
import 'package:tune/ui/widgets/animation/audio_visualizer_animation.dart';
import 'package:tune/ui/widgets/animation/playing_state_animation.dart';
import 'package:tune/ui/widgets/animation/play_button_pulse_animation.dart';
import 'package:tune/ui/widgets/animation/note_particle_animation.dart';

// 假设有一个动画启用状态的Provider
final animationsEnabledProvider = StateProvider<bool>((ref) => true);

class AnimationsTab extends ConsumerStatefulWidget {
  const AnimationsTab({super.key});

  @override
  ConsumerState<AnimationsTab> createState() => _AnimationsTabState();
}

class _AnimationsTabState extends ConsumerState<AnimationsTab> {
  bool _isFavorite = false;
  bool _isPlaying = false;
  bool _expanded = false;
  double _volume = 0.5;
  double _progress = 0.3;
  int _count = 128;

  @override
  Widget build(BuildContext context) {
    final animations = [
      _AnimationItem(
        name: '专辑封面旋转',
        widget: const AlbumCoverRotationAnimation(),
      ),
      _AnimationItem(
        name: '音频可视化',
        widget: const AudioVisualizerAnimation(),
      ),
      _AnimationItem(
        name: '播放状态',
        widget: PlayingStateAnimation(isPlaying: _isPlaying),
      ),
      _AnimationItem(
        name: '专辑旋转',
        widget: const AlbumRotationAnimation(),
      ),
      _AnimationItem(
        name: '专辑摇摆',
        widget: const AlbumSwingAnimation(),
      ),
      _AnimationItem(
        name: '音符弹跳',
        widget: const NoteBouncingAnimation(),
      ),
      _AnimationItem(
        name: '音量气泡',
        widget: const VolumeBubbleAnimation(),
      ),
      _AnimationItem(
        name: '播放按钮呼吸',
        widget: const PlayButtonBreathingAnimation(),
      ),
      _AnimationItem(
        name: '播放暂停旋转',
        widget: const PlayPauseRotationAnimation(),
      ),
      _AnimationItem(
        name: '圆形频谱',
        widget: const CircularSpectrumAnimation(),
      ),
      _AnimationItem(
        name: '瀑布频谱',
        widget: const SpectrumWaterfallAnimation(),
      ),
      _AnimationItem(
        name: '音频波弹性',
        widget: const AudioWaveElasticAnimation(),
      ),
      _AnimationItem(
        name: '粒子专辑聚合',
        widget: const ParticleAlbumAggregationAnimation(),
      ),
      _AnimationItem(
        name: '分享按钮粒子',
        widget: const ShareButtonParticleAnimation(),
      ),
      _AnimationItem(
        name: '下载进度填充',
        widget: const DownloadProgressFillAnimation(),
      ),
      _AnimationItem(
        name: '收藏按钮爆炸',
        widget: const FavoriteButtonExplosionAnimation(),
      ),
      _AnimationItem(
        name: '音量涟漪条',
        widget: const VolumeRippleBarsAnimation(),
      ),
      _AnimationItem(
        name: '歌词高亮',
        widget: const LyricsHighlightAnimation(),
      ),
      _AnimationItem(
        name: '音频峰值爆炸',
        widget: const AudioPeakBlastAnimation(),
      ),
      _AnimationItem(
        name: '立方体频谱',
        widget: const CubeSpectrumAnimation(),
      ),
      _AnimationItem(
        name: '均衡器旋钮',
        widget: const EqualizerKnobAnimation(),
      ),
      _AnimationItem(
        name: '专辑悬浮',
        widget: const AlbumFloatingAnimation(),
      ),
      _AnimationItem(
        name: '专辑翻页',
        widget: const AlbumPageFlipAnimation(),
      ),
      _AnimationItem(
        name: '音频峰值爆炸',
        widget: const AudioPeakExplosionAnimation(),
      ),
      _AnimationItem(
        name: '音频峰值烟花',
        widget: const AudioPeakFireworksAnimation(),
      ),
      _AnimationItem(
        name: '收藏按钮旋转填充',
        widget: const FavoriteButtonRotationFillAnimation(),
      ),
      _AnimationItem(
        name: '加载状态圆点跳动',
        widget: const LoadingDotBounceAnimation(),
      ),
      _AnimationItem(
        name: '加载状态齿轮',
        widget: const LoadingGearAnimation(),
      ),
      _AnimationItem(
        name: '加载状态音符旋转',
        widget: const LoadingNoteRotationAnimation(),
      ),
      _AnimationItem(
        name: '加载状态声波',
        widget: const LoadingSoundWaveAnimation(),
      ),
      _AnimationItem(
        name: '歌词渐变',
        widget: const LyricsGradientAnimation(),
      ),
      _AnimationItem(
        name: '歌词行缩放',
        widget: const LyricsLineScaleAnimation(),
      ),
      _AnimationItem(
        name: '歌词字弹跳',
        widget: const LyricsWordBounceAnimation(),
      ),
      _AnimationItem(
        name: '音符碰撞堆叠',
        widget: const NoteCollisionStackAnimation(),
      ),
      _AnimationItem(
        name: '音符雨',
        widget: const NoteRainAnimation(),
      ),
      _AnimationItem(
        name: '音符正弦波',
        widget: const NoteSineWaveAnimation(),
      ),
      _AnimationItem(
        name: '音符螺旋',
        widget: const NoteSpiralAnimation(),
      ),
      _AnimationItem(
        name: '页面溶解过渡',
        widget: const PageDissolveTransitionAnimation(),
      ),
      _AnimationItem(
        name: '粒子网格波',
        widget: const ParticleGridWaveAnimation(),
      ),
      _AnimationItem(
        name: '粒子旋涡',
        widget: const ParticleVortexAnimation(),
      ),
      _AnimationItem(
        name: '粒子流沿波形',
        widget: const ParticleWaveFlowAnimation(),
      ),
      _AnimationItem(
        name: '暂停按钮波纹',
        widget: const PauseButtonRippleAnimation(),
      ),
      _AnimationItem(
        name: '播放按钮填充',
        widget: const PlayButtonFillAnimation(),
      ),
      _AnimationItem(
        name: '播放状态脉冲',
        widget: const PlayStatePulseAnimation(),
      ),
      _AnimationItem(
        name: '进度条分段加载',
        widget: const ProgressBarSegmentedLoadingAnimation(),
      ),
      _AnimationItem(
        name: '进度脉冲',
        widget: const ProgressPulseAnimation(),
      ),
      _AnimationItem(
        name: '进度时间滚动',
        widget: const ProgressTimeScrollAnimation(),
      ),
      _AnimationItem(
        name: '波纹扩散',
        widget: const RippleDiffusionAnimation(),
      ),
      _AnimationItem(
        name: '扇形频谱',
        widget: const SectorSpectrumAnimation(),
      ),
      _AnimationItem(
        name: '3D频谱球',
        widget: const Spectrum3DSphereAnimation(),
      ),
      _AnimationItem(
        name: '频谱闪光',
        widget: const SpectrumFlashAnimation(),
      ),
      _AnimationItem(
        name: '音量扇形展开',
        widget: const VolumeSectorExpandAnimation(),
      ),
      _AnimationItem(
        name: '波形网格',
        widget: const WaveformGridAnimation(),
      ),
      _AnimationItem(
        name: '播放按钮脉冲动画',
        widget: const PlayButtonPulseAnimation(),
      ),
      _AnimationItem(
        name: '音符粒子动画',
        widget: const NoteParticleAnimation(),
      ),
    ];

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '动画设置',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: theme.colorScheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '启用动画',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '开启或关闭所有动画效果',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text(
                          '全局动画',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        value: ref.watch(animationsEnabledProvider),
                        onChanged: (value) {
                          ref.read(animationsEnabledProvider.notifier).state = value;
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '动画预览',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final animationItem = animations[index];
                return Card(
                  color: theme.colorScheme.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 60,
                          // 使用AnimatedSwitcher实现动画启用/禁用的过渡效果
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: ref.watch(animationsEnabledProvider)
                              ? Builder(
                                  builder: (BuildContext context) {
                                    // 传递主题给动画组件，确保主题适配
                                    // 添加UniqueKey确保组件正确重建，避免黑屏问题
                                    return Theme(
                                      data: Theme.of(context),
                                      child: KeyedSubtree(
                                        key: ValueKey('${animationItem.name}_${ref.watch(animationsEnabledProvider)}'),
                                        child: animationItem.widget,
                                      ),
                                    );
                                  }
                                )
                              : const Icon(Icons.animation_outlined, size: 30),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          animationItem.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: animations.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimationItem {
  final String name;
  final Widget widget;

  _AnimationItem({required this.name, required this.widget});
}