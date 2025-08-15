import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tune/core/extension/scaffold_messenger_extension.dart';
import 'package:tune/core/extension/theme_extension.dart';
import 'package:tune/providers/music_providers.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';
import 'package:tune/ui/core/layout/widgets/app_bar.dart';

class MusicScanPage extends ConsumerStatefulWidget {
  const MusicScanPage({super.key});

  @override
  ConsumerState<MusicScanPage> createState() => _MusicScanPageState();
}

class _MusicScanPageState extends ConsumerState<MusicScanPage> {
  bool _isScanning = false;
  int _scannedCount = 0;
  int _totalCount = 0;
  List<Song> _songs = [];
  String _statusMessage = '';
  String _errorMessage = '';
  List<String> _customScanPaths = [];
  bool _isLoadingPaths = true;

  @override
  void initState() {
    super.initState();
    _loadCustomScanPaths();
  }

  Future<void> _loadCustomScanPaths() async {
    setState(() {
      _isLoadingPaths = true;
    });

    try {
      final persistenceService = ref.read(sharedPreferencesServiceProvider);
      final paths = persistenceService.getStringList('custom_scan_paths') ?? [];

      setState(() {
        _customScanPaths = paths;
        _isLoadingPaths = false;
      });
    } catch (e) {
      Log.info('MusicScanPage: Failed to load custom scan paths: $e');
      setState(() {
        _isLoadingPaths = false;
      });
    }
  }

  Future<void> _saveCustomScanPaths() async {
    try {
      final persistenceService = ref.read(sharedPreferencesServiceProvider);
      await persistenceService.setStringList('custom_scan_paths', _customScanPaths);
    } catch (e) {
      Log.info('MusicScanPage: Failed to save custom scan paths: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存扫描路径失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addCustomScanPath() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        setState(() {
          if (!_customScanPaths.contains(result)) {
            _customScanPaths.add(result);
            _saveCustomScanPaths();
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已添加自定义扫描路径'),
            ),
          );
        }
      }
    } catch (e) {
      Log.info('MusicScanPage: Failed to add custom scan path: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加扫描路径失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeCustomScanPath(int index) {
    setState(() {
      _customScanPaths.removeAt(index);
      _saveCustomScanPaths();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已移除扫描路径'),
        ),
      );
    }
  }

  Future<void> _scanCustomPaths() async {
    if (_isScanning || _customScanPaths.isEmpty) return;
    
    await _startScan();
  }

  // 开始扫描音乐
  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _scannedCount = 0;
      _totalCount = 0;
      _songs = [];
      _statusMessage = '开始扫描音乐库...';
      _errorMessage = '';
    });

    try {
      Log.info('MusicScanPage: Starting music scan');
      // 使用跨平台音乐扫描服务替代原来的平台音乐服务
      final crossPlatformScanner = ref.read(crossPlatformMusicScannerProvider);

      // 显示扫描开始信息
      setState(() {
        _statusMessage = '正在扫描音乐文件...';
      });

      // 获取所有歌曲
      List<Song> songs;
      if (_customScanPaths.isNotEmpty) {
        // 如果有自定义扫描路径，则扫描这些路径
        Log.info('MusicScanPage: Scanning custom paths: $_customScanPaths');
        songs = await crossPlatformScanner.scanMusicInDirectories(_customScanPaths);
      } else {
        // 否则执行全平台扫描
        Log.info('MusicScanPage: Performing cross-platform scan');
        songs = await crossPlatformScanner.scanMusic();
      }

      setState(() {
        _songs = songs;
        _scannedCount = songs.length;
        _totalCount = songs.length;
        _statusMessage = '扫描完成';
        _isScanning = false;
      });

      Log.info('MusicScanPage: Scan completed, found ${songs.length} songs');

      // 显示扫描结果
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('扫描完成，共找到 $_scannedCount 首歌曲'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Log.info('MusicScanPage: Scan failed with error: $e');
      String errorMessage = '扫描失败';
      
      // 检查是否为MissingPluginException
      if (e.toString().contains('MissingPluginException')) {
        errorMessage = '当前平台不支持音乐扫描功能。此功能仅在Android和iOS设备上可用。';
      } else if (e.toString().contains('Permission denied')) {
        errorMessage = '没有音乐库访问权限，请在设置中授予相关权限。';
      } else {
        errorMessage = '扫描失败: ${e.toString()}';
      }

      setState(() {
        _isScanning = false;
        _errorMessage = errorMessage;
        _statusMessage = '扫描失败';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('扫描失败，请查看日志了解详情'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '音乐扫描',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 实现搜索功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('搜索功能待实现')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: 实现更多功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('更多功能待实现')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '扫描本地音乐',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '扫描本地音乐库，自动整理您的音乐文件并提取元数据',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isScanning ? null : _startScan,
                              icon: _isScanning
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.search),
                              label: Text(_isScanning ? '扫描中...' : '开始扫描'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_statusMessage.isNotEmpty)
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _errorMessage.isEmpty ? Colors.blue : Colors.red,
                          ),
                        ),
                      if (_isScanning && _totalCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: LinearProgressIndicator(
                            value: _totalCount > 0 ? _scannedCount / _totalCount : 0,
                            backgroundColor: context.theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      if (_isScanning && _totalCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '已扫描 $_scannedCount / $_totalCount 首歌曲',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 自定义扫描路径
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
                            '自定义扫描路径',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addCustomScanPath,
                            tooltip: '添加自定义扫描路径',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '添加自定义文件夹路径以扫描特定位置的音乐文件',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingPaths)
                        const Center(child: CircularProgressIndicator())
                      else if (_customScanPaths.isEmpty)
                        const Text('暂无自定义扫描路径')
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _customScanPaths.length,
                          itemBuilder: (context, index) {
                            final path = _customScanPaths[index];
                            return ListTile(
                              title: Text(path),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeCustomScanPath(index),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      if (_customScanPaths.isNotEmpty)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isScanning ? null : _scanCustomPaths,
                                icon: _isScanning
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.folder_open),
                                label: Text(_isScanning ? '扫描中...' : '扫描自定义路径'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 扫描结果
              if (!_isScanning && _songs.isNotEmpty) ...[
                Text(
                  '扫描结果 ($_scannedCount 首歌曲)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: _songs.length,
                    itemBuilder: (context, index) {
                      final song = _songs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: context.theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.music_note,
                              color: context.theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          title: Text(song.title),
                          subtitle: Text('${song.artist ?? '未知艺术家'} · ${song.album ?? '未知专辑'}'),
                          trailing: Text(_formatDuration(song.duration)),
                        ),
                      );
                    },
                  ),
                ),
              ] else if (_errorMessage.isNotEmpty) ...[
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _startScan,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ] else if (!_isScanning && _statusMessage.isNotEmpty && _songs.isEmpty) ...[
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_off,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '未找到音乐文件\n点击"开始扫描"按钮扫描本地音乐',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int durationInMilliseconds) {
    final duration = Duration(milliseconds: durationInMilliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
