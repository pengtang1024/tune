import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/widgets/animation/album_cover_particle_animation.dart';
import 'package:tune/ui/widgets/animation/album_cover_rotate_animation.dart';
import 'package:tune/ui/widgets/animation/album_cover_rotation_animation.dart';
import 'package:tune/ui/widgets/animation/album_floating_animation.dart';
import 'package:tune/ui/widgets/animation/album_page_flip_animation.dart';
import 'package:tune/ui/widgets/animation/album_rotation_animation.dart';
import 'package:tune/ui/widgets/animation/album_swing_animation.dart';
import 'package:tune/ui/widgets/animation/audio_peak_blast_animation.dart';
import 'package:tune/ui/widgets/animation/audio_peak_explosion_animation.dart';
import 'package:tune/ui/widgets/animation/audio_peak_fireworks_animation.dart';
import 'package:tune/ui/widgets/animation/audio_ripple_animation.dart';
import 'package:tune/ui/widgets/animation/audio_spectrum_grid_animation.dart';
import 'package:tune/ui/widgets/animation/audio_visualizer_animation.dart';
import 'package:tune/ui/widgets/animation/audio_visualizer_ring_animation.dart';
import 'package:tune/ui/widgets/animation/audio_wave_cube_animation.dart';
import 'package:tune/ui/widgets/animation/audio_wave_distortion_animation.dart';
import 'package:tune/ui/widgets/animation/audio_wave_elastic_animation.dart';
import 'package:tune/ui/widgets/animation/circular_spectrum_animation.dart';
import 'package:tune/ui/widgets/animation/cube_spectrum_animation.dart';
import 'package:tune/ui/widgets/animation/download_progress_fill_animation.dart';
import 'package:tune/ui/widgets/animation/equalizer_knob_animation.dart';
import 'package:tune/ui/widgets/animation/favorite_button_explosion_animation.dart';
import 'package:tune/ui/widgets/animation/favorite_button_rotation_fill_animation.dart';
import 'package:tune/ui/widgets/animation/loading_dot_bounce_animation.dart';
import 'package:tune/ui/widgets/animation/loading_gear_animation.dart';
import 'package:tune/ui/widgets/animation/loading_note_rotation_animation.dart';
import 'package:tune/ui/widgets/animation/loading_sound_wave_animation.dart';
import 'package:tune/ui/widgets/animation/lyrics_gradient_animation.dart';
import 'package:tune/ui/widgets/animation/lyrics_highlight_animation.dart';
import 'package:tune/ui/widgets/animation/lyrics_line_scale_animation.dart';
import 'package:tune/ui/widgets/animation/lyrics_word_bounce_animation.dart';
import 'package:tune/ui/widgets/animation/music_beat_particle_animation.dart';
import 'package:tune/ui/widgets/animation/music_particle_connect_animation.dart';
import 'package:tune/ui/widgets/animation/music_spectrum_cube_animation.dart';
import 'package:tune/ui/widgets/animation/music_spectrum_particle_animation.dart';
import 'package:tune/ui/widgets/animation/music_wave_particle_animation.dart';
import 'package:tune/ui/widgets/animation/note_bounce_animation.dart';
import 'package:tune/ui/widgets/animation/note_bouncing_animation.dart';
import 'package:tune/ui/widgets/animation/note_collision_stack_animation.dart';
import 'package:tune/ui/widgets/animation/note_fall_animation.dart';
import 'package:tune/ui/widgets/animation/note_particle_animation.dart';
import 'package:tune/ui/widgets/animation/note_rain_animation.dart';
import 'package:tune/ui/widgets/animation/note_rotate_animation.dart';
import 'package:tune/ui/widgets/animation/note_sine_wave_animation.dart';
import 'package:tune/ui/widgets/animation/note_spiral_animation.dart';
import 'package:tune/ui/widgets/animation/page_dissolve_transition_animation.dart';
import 'package:tune/ui/widgets/animation/particle_album_aggregation_animation.dart';
import 'package:tune/ui/widgets/animation/particle_grid_wave_animation.dart';
import 'package:tune/ui/widgets/animation/particle_orbit_animation.dart';
import 'package:tune/ui/widgets/animation/particle_vortex_animation.dart';
import 'package:tune/ui/widgets/animation/particle_wave_flow_animation.dart';
import 'package:tune/ui/widgets/animation/pause_button_ripple_animation.dart';
import 'package:tune/ui/widgets/animation/play_button_breathing_animation.dart';
import 'package:tune/ui/widgets/animation/play_button_fill_animation.dart';
import 'package:tune/ui/widgets/animation/play_button_pulse_animation.dart';
import 'package:tune/ui/widgets/animation/play_pause_rotation_animation.dart';
import 'package:tune/ui/widgets/animation/play_state_pulse_animation.dart';
import 'package:tune/ui/widgets/animation/playing_state_animation.dart';
import 'package:tune/ui/widgets/animation/playlist_expand_animation.dart';
import 'package:tune/ui/widgets/animation/progress_bar_segmented_loading_animation.dart';
import 'package:tune/ui/widgets/animation/progress_pulse_animation.dart';
import 'package:tune/ui/widgets/animation/progress_time_scroll_animation.dart';
import 'package:tune/ui/widgets/animation/ripple_diffusion_animation.dart';
import 'package:tune/ui/widgets/animation/sector_spectrum_animation.dart';
import 'package:tune/ui/widgets/animation/share_button_particle_animation.dart';
import 'package:tune/ui/widgets/animation/spectrum_3d_sphere_animation.dart';
import 'package:tune/ui/widgets/animation/spectrum_flash_animation.dart';
import 'package:tune/ui/widgets/animation/spectrum_waterfall_animation.dart';
import 'package:tune/ui/widgets/animation/volume_bubble_animation.dart';
import 'package:tune/ui/widgets/animation/volume_ripple_bars_animation.dart';
import 'package:tune/ui/widgets/animation/volume_sector_expand_animation.dart';
import 'package:tune/ui/widgets/animation/waveform_grid_animation.dart';
import 'package:tune/ui/core/settings/widgets/tabs/animation_item_widget.dart';

// 假设有一个动画启用状态的Provider
final animationsEnabledProvider = StateProvider<bool>((ref) => true);

// _AnimationItem 类已移除，使用 animation_item_widget.dart 中定义的 AnimationItem 类代替
class AnimationsTab extends ConsumerStatefulWidget {
  const AnimationsTab({super.key});

  @override
  ConsumerState<AnimationsTab> createState() => _AnimationsTabState();
}

class _AnimationsTabState extends ConsumerState<AnimationsTab> {
  final bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    final animations = [
      AnimationItem(
        name: '专辑封面旋转',
        widget: const AlbumCoverRotationAnimation(),
      ),
      AnimationItem(name: '音频可视化', widget: const AudioVisualizerAnimation()),
      AnimationItem(
        name: '播放状态',
        widget: PlayingStateAnimation(isPlaying: _isPlaying),
      ),
      AnimationItem(name: '专辑旋转', widget: const AlbumRotationAnimation()),
      AnimationItem(name: '专辑摇摆', widget: const AlbumSwingAnimation()),
      AnimationItem(name: '音符弹跳', widget: const NoteBouncingAnimation()),
      AnimationItem(name: '音量气泡', widget: const VolumeBubbleAnimation()),
      AnimationItem(
        name: '播放按钮呼吸',
        widget: const PlayButtonBreathingAnimation(),
      ),
      AnimationItem(name: '播放暂停旋转', widget: const PlayPauseRotationAnimation()),
      AnimationItem(name: '圆形频谱', widget: const CircularSpectrumAnimation()),
      AnimationItem(name: '瀑布频谱', widget: const SpectrumWaterfallAnimation()),
      AnimationItem(name: '音频波弹性', widget: const AudioWaveElasticAnimation()),
      AnimationItem(
        name: '粒子专辑聚合',
        widget: const ParticleAlbumAggregationAnimation(),
      ),
      AnimationItem(
        name: '分享按钮粒子',
        widget: const ShareButtonParticleAnimation(),
      ),
      AnimationItem(
        name: '下载进度填充',
        widget: const DownloadProgressFillAnimation(),
      ),
      AnimationItem(
        name: '收藏按钮爆炸',
        widget: const FavoriteButtonExplosionAnimation(),
      ),
      AnimationItem(name: '音量涟漪条', widget: const VolumeRippleBarsAnimation()),
      AnimationItem(name: '歌词高亮', widget: const LyricsHighlightAnimation()),
      AnimationItem(name: '音频峰值爆炸', widget: const AudioPeakBlastAnimation()),
      AnimationItem(name: '立方体频谱', widget: const CubeSpectrumAnimation()),
      AnimationItem(name: '均衡器旋钮', widget: const EqualizerKnobAnimation()),
      AnimationItem(name: '专辑悬浮', widget: const AlbumFloatingAnimation()),
      AnimationItem(name: '专辑翻页', widget: const AlbumPageFlipAnimation()),
      AnimationItem(
        name: '音频峰值爆炸',
        widget: const AudioPeakExplosionAnimation(),
      ),
      AnimationItem(
        name: '音频峰值烟花',
        widget: const AudioPeakFireworksAnimation(),
      ),
      AnimationItem(
        name: '收藏按钮旋转填充',
        widget: const FavoriteButtonRotationFillAnimation(),
      ),
      AnimationItem(
        name: '加载状态圆点跳动',
        widget: const LoadingDotBounceAnimation(),
      ),
      AnimationItem(name: '加载状态齿轮', widget: const LoadingGearAnimation()),
      AnimationItem(
        name: '加载状态音符旋转',
        widget: const LoadingNoteRotationAnimation(),
      ),
      AnimationItem(name: '加载状态声波', widget: const LoadingSoundWaveAnimation()),
      AnimationItem(name: '歌词渐变', widget: const LyricsGradientAnimation()),
      AnimationItem(name: '歌词行缩放', widget: const LyricsLineScaleAnimation()),
      AnimationItem(name: '歌词字弹跳', widget: const LyricsWordBounceAnimation()),
      AnimationItem(
        name: '音符碰撞堆叠',
        widget: const NoteCollisionStackAnimation(),
      ),
      AnimationItem(name: '音符雨', widget: const NoteRainAnimation()),
      AnimationItem(name: '音符正弦波', widget: const NoteSineWaveAnimation()),
      AnimationItem(name: '音符螺旋', widget: const NoteSpiralAnimation()),
      AnimationItem(
        name: '页面溶解过渡',
        widget: const PageDissolveTransitionAnimation(),
      ),
      AnimationItem(name: '粒子网格波', widget: const ParticleGridWaveAnimation()),
      AnimationItem(name: '粒子旋涡', widget: const ParticleVortexAnimation()),
      AnimationItem(name: '粒子流沿波形', widget: const ParticleWaveFlowAnimation()),
      AnimationItem(name: '暂停按钮波纹', widget: const PauseButtonRippleAnimation()),
      AnimationItem(name: '播放按钮填充', widget: const PlayButtonFillAnimation()),
      AnimationItem(name: '播放状态脉冲', widget: const PlayStatePulseAnimation()),
      AnimationItem(
        name: '进度条分段加载',
        widget: const ProgressBarSegmentedLoadingAnimation(),
      ),
      AnimationItem(name: '进度脉冲', widget: const ProgressPulseAnimation()),
      AnimationItem(
        name: '进度时间滚动',
        widget: const ProgressTimeScrollAnimation(),
      ),
      AnimationItem(name: '波纹扩散', widget: const RippleDiffusionAnimation()),
      AnimationItem(name: '扇形频谱', widget: const SectorSpectrumAnimation()),
      AnimationItem(name: '3D频谱球', widget: const Spectrum3DSphereAnimation()),
      AnimationItem(name: '频谱闪光', widget: const SpectrumFlashAnimation()),
      AnimationItem(
        name: '音量扇形展开',
        widget: const VolumeSectorExpandAnimation(),
      ),
      AnimationItem(name: '波形网格', widget: const WaveformGridAnimation()),
      AnimationItem(name: '播放按钮脉冲动画', widget: const PlayButtonPulseAnimation()),
      AnimationItem(name: '音符粒子动画', widget: const NoteParticleAnimation()),
      // 新增的动画组件
      AnimationItem(
        name: '专辑封面粒子动画',
        widget: const AlbumCoverParticleAnimation(),
      ),
      AnimationItem(
        name: '专辑封面旋转动画',
        widget: const AlbumCoverRotateAnimation(),
      ),
      AnimationItem(name: '音频涟漪动画', widget: const AudioRippleAnimation()),
      AnimationItem(
        name: '音频频谱网格动画',
        widget: const AudioSpectrumGridAnimation(),
      ),
      AnimationItem(
        name: '音频可视化环形动画',
        widget: const AudioVisualizerRingAnimation(),
      ),
      AnimationItem(name: '音频波形立方体动画', widget: const AudioWaveCubeAnimation()),
      AnimationItem(
        name: '音频波形失真动画',
        widget: const AudioWaveDistortionAnimation(),
      ),
      AnimationItem(
        name: '音乐节拍粒子动画',
        widget: const MusicBeatParticleAnimation(),
      ),
      AnimationItem(
        name: '音乐粒子连接动画',
        widget: const MusicParticleConnectAnimation(),
      ),
      AnimationItem(
        name: '音乐频谱立方体动画',
        widget: const MusicSpectrumCubeAnimation(),
      ),
      AnimationItem(
        name: '音乐频谱粒子动画',
        widget: const MusicSpectrumParticleAnimation(),
      ),
      AnimationItem(
        name: '音乐波形粒子动画',
        widget: const MusicWaveParticleAnimation(),
      ),
      AnimationItem(name: '音符弹跳动画', widget: const NoteBounceAnimation()),
      AnimationItem(name: '音符下落动画', widget: const NoteFallAnimation()),
      AnimationItem(name: '音符旋转动画', widget: const NoteRotateAnimation()),
      AnimationItem(name: '粒子轨道动画', widget: const ParticleOrbitAnimation()),
      AnimationItem(name: '播放列表展开动画', widget: const PlaylistExpandAnimation()),
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
                color: theme.colorScheme.surfaceContainerHighest,
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
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
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
                          ref.read(animationsEnabledProvider.notifier).state =
                              value;
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
            delegate: SliverChildBuilderDelegate((context, index) {
              final animationItem = animations[index];
              return AnimationItemWidget(animationItem: animationItem);
            }, childCount: animations.length),
          ),
        ],
      ),
    );
  }
}
