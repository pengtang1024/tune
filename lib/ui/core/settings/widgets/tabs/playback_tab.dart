import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/data/services/persistence_service.dart';

class PlaybackTab extends ConsumerStatefulWidget {
  const PlaybackTab({super.key});

  @override
  ConsumerState<PlaybackTab> createState() => _PlaybackTabState();
}

class _PlaybackTabState extends ConsumerState<PlaybackTab> {
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  bool _crossFade = true;
  String _audioQuality = 'high';
  bool _headsetPause = true;
  String _playMode = 'sequence';

  @override
  void initState() {
    super.initState();
    _loadPlaybackSettings();
  }

  Future<void> _loadPlaybackSettings() async {
    final persistenceService = ref.read(sharedPreferencesServiceProvider);
    
    final volume = persistenceService.getDouble('playback_volume') ?? 1.0;
    final playbackSpeed = persistenceService.getDouble('playback_speed') ?? 1.0;
    final crossFade = persistenceService.getBool('playback_cross_fade') ?? true;
    final audioQuality = persistenceService.getString('playback_audio_quality') ?? 'high';
    final headsetPause = persistenceService.getBool('playback_headset_pause') ?? true;
    final playMode = persistenceService.getString('playback_mode') ?? 'sequence';
    
    setState(() {
      _volume = volume;
      _playbackSpeed = playbackSpeed;
      _crossFade = crossFade;
      _audioQuality = audioQuality;
      _headsetPause = headsetPause;
      _playMode = playMode;
    });
  }

  Future<void> _savePlaybackSettings() async {
    final persistenceService = ref.read(sharedPreferencesServiceProvider);
    
    await persistenceService.setDouble('playback_volume', _volume);
    await persistenceService.setDouble('playback_speed', _playbackSpeed);
    await persistenceService.setBool('playback_cross_fade', _crossFade);
    await persistenceService.setString('playback_audio_quality', _audioQuality);
    await persistenceService.setBool('playback_headset_pause', _headsetPause);
    await persistenceService.setString('playback_mode', _playMode);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('播放设置已保存')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '播放设置',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('音量', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: _volume,
            min: 0.0,
            max: 1.0,
            divisions: 100,
            label: '${(_volume * 100).round()}%',
            onChanged: (value) {
              setState(() {
                _volume = value;
              });
            },
          ),
          const SizedBox(height: 16),
          const Text('播放速度', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: _playbackSpeed,
            min: 0.5,
            max: 2.0,
            divisions: 30,
            label: '${_playbackSpeed.toStringAsFixed(1)}x',
            onChanged: (value) {
              setState(() {
                _playbackSpeed = value;
              });
            },
          ),
          const SizedBox(height: 16),
          const Text('播放模式', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<String>(
            value: _playMode,
            items: const [
              DropdownMenuItem(value: 'sequence', child: Text('顺序播放')),
              DropdownMenuItem(value: 'loop', child: Text('列表循环')),
              DropdownMenuItem(value: 'single', child: Text('单曲循环')),
              DropdownMenuItem(value: 'random', child: Text('随机播放')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _playMode = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          const Text('音质选择', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<String>(
            value: _audioQuality,
            items: const [
              DropdownMenuItem(value: 'low', child: Text('低音质 (128kbps)')),
              DropdownMenuItem(value: 'medium', child: Text('中等音质 (192kbps)')),
              DropdownMenuItem(value: 'high', child: Text('高音质 (320kbps)')),
              DropdownMenuItem(value: 'lossless', child: Text('无损音质 (FLAC)')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _audioQuality = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('交叉淡入淡出'),
            value: _crossFade,
            onChanged: (value) {
              setState(() {
                _crossFade = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('耳机拔出时暂停播放'),
            value: _headsetPause,
            onChanged: (value) {
              setState(() {
                _headsetPause = value ?? false;
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _savePlaybackSettings,
            child: const Text('保存设置'),
          ),
        ],
      ),
    );
  }
}