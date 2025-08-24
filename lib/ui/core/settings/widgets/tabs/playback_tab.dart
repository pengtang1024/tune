import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/providers/persistence_providers.dart';

class PlaybackTab extends ConsumerStatefulWidget {
  const PlaybackTab({super.key});

  @override
  ConsumerState<PlaybackTab> createState() => _PlaybackTabState();
}

class _PlaybackTabState extends ConsumerState<PlaybackTab> {
  double _defaultPlaybackSpeed = 1.0;
  bool _crossfadeEnabled = false;
  int _crossfadeDuration = 1000; // milliseconds
  bool _gaplessPlayback = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    final persistenceService = ref.read(sharedPreferencesServiceProvider);

    setState(() {
      _defaultPlaybackSpeed = persistenceService.getDouble('default_playback_speed') ?? 1.0;
      _crossfadeEnabled = persistenceService.getBool('crossfade_enabled') ?? false;
      _crossfadeDuration = persistenceService.getInt('crossfade_duration') ?? 1000;
      _gaplessPlayback = persistenceService.getBool('gapless_playback') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final persistenceService = ref.read(sharedPreferencesServiceProvider);

    if (value is bool) {
      await persistenceService.setBool(key, value);
    } else if (value is double) {
      await persistenceService.setDouble(key, value);
    } else if (value is int) {
      await persistenceService.setInt(key, value);
    } else if (value is String) {
      await persistenceService.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sharedPreferencesServiceProvider);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.playback_settings,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 默认播放速度
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc.default_playback_speed,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<double>(
                    value: _defaultPlaybackSpeed,
                    onChanged: (double? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _defaultPlaybackSpeed = newValue;
                        });
                        _saveSetting('default_playback_speed', newValue);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                      DropdownMenuItem(value: 0.75, child: Text('0.75x')),
                      DropdownMenuItem(value: 1.0, child: Text('1.0x')),
                      DropdownMenuItem(value: 1.25, child: Text('1.25x')),
                      DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                      DropdownMenuItem(value: 2.0, child: Text('2.0x')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.default_playback_speed_description,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 交叉淡入淡出
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.loc.crossfade,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Switch(
                        value: _crossfadeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _crossfadeEnabled = value;
                          });
                          _saveSetting('crossfade_enabled', value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.crossfade_description,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (_crossfadeEnabled) ...[
                    const SizedBox(height: 16),
                    Text(context.loc.crossfade_duration),
                    Slider(
                      value: _crossfadeDuration.toDouble(),
                      min: 100,
                      max: 5000,
                      divisions: 49,
                      label: '${_crossfadeDuration}ms',
                      onChanged: (value) {
                        setState(() {
                          _crossfadeDuration = value.toInt();
                        });
                        _saveSetting('crossfade_duration', _crossfadeDuration);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 无缝播放
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.loc.gapless_playback,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Switch(
                        value: _gaplessPlayback,
                        onChanged: (value) {
                          setState(() {
                            _gaplessPlayback = value;
                          });
                          _saveSetting('gapless_playback', value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.gapless_playback_description,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}