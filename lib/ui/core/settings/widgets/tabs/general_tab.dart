import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/providers/persistence_providers.dart';

class GeneralTab extends ConsumerStatefulWidget {
  const GeneralTab({super.key});

  @override
  ConsumerState<GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends ConsumerState<GeneralTab> {
  bool _autoStart = false;
  String _windowSize = 'medium'; // small, medium, large
  bool _defaultPlayer = false;
  bool _desktopLyrics = false;
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

    // 使用全局的sharedPreferencesServiceProvider
    final persistenceService = ref.read(sharedPreferencesServiceProvider);

    setState(() {
      _autoStart = persistenceService.getBool('auto_start') ?? false;
      _windowSize = persistenceService.getString('window_size') ?? 'medium';
      _defaultPlayer = persistenceService.getBool('default_player') ?? false;
      _desktopLyrics = persistenceService.getBool('desktop_lyrics') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    // 使用全局的sharedPreferencesServiceProvider
    final persistenceService = ref.read(sharedPreferencesServiceProvider);

    if (value is bool) {
      await persistenceService.setBool(key, value);
    } else if (value is String) {
      await persistenceService.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听持久化服务的变化，当设置改变时刷新UI
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
            context.loc.general_settings,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 开机运行
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
                        context.loc.auto_start,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Switch(
                        value: _autoStart,
                        onChanged: (value) {
                          setState(() {
                            _autoStart = value;
                          });
                          _saveSetting('auto_start', value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.auto_start_description,
                    style: const TextStyle(color: Colors.grey),
                  ),

                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 窗口大小
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc.window_size,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _windowSize,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _windowSize = newValue;
                        });
                        _saveSetting('window_size', newValue);
                      }
                    },
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'small',
                        child: Text(context.loc.small),
                      ),
                      DropdownMenuItem<String>(
                        value: 'medium',
                        child: Text(context.loc.medium),
                      ),
                      DropdownMenuItem<String>(
                        value: 'large',
                        child: Text(context.loc.large),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.window_size_description,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 默认播放器
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
                        context.loc.default_player,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Switch(
                        value: _defaultPlayer,
                        onChanged: (value) {
                          setState(() {
                            _defaultPlayer = value;
                          });
                          _saveSetting('default_player', value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.default_player_description,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 桌面歌词
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
                        context.loc.desktop_lyrics,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Switch(
                        value: _desktopLyrics,
                        onChanged: (value) {
                          setState(() {
                            _desktopLyrics = value;
                          });
                          _saveSetting('desktop_lyrics', value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.desktop_lyrics_description,
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