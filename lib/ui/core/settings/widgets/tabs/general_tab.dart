import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/data/services/persistence_service.dart';

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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '常规设置',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      const Text(
                        '开机运行',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  const Text(
                    '开机时自动启动应用',
                    style: TextStyle(color: Colors.grey),
                  ),
                  
                  // 启动窗口大小设置
                  if (_autoStart) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '启动窗口大小',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildWindowSizeOption('小', 'small'),
                        const SizedBox(width: 16),
                        _buildWindowSizeOption('中', 'medium'),
                        const SizedBox(width: 16),
                        _buildWindowSizeOption('大', 'large'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 设为默认播放器
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '设为默认播放器',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 启用桌面歌词
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '启用桌面歌词',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowSizeOption(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _windowSize == value,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _windowSize = value;
          });
          _saveSetting('window_size', value);
        }
      },
    );
  }
}