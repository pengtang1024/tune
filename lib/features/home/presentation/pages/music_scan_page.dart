import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/features/audio/presentation/bloc/music_scan/music_scan_bloc.dart';
import 'package:tune/features/audio/presentation/bloc/music_scan/music_scan_event.dart';
import 'package:tune/features/audio/presentation/bloc/music_scan/music_scan_state.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

@RoutePage()
class MusicScanPage extends StatefulWidget {
  const MusicScanPage({super.key});

  @override
  State<MusicScanPage> createState() => _MusicScanPageState();
}

class _MusicScanPageState extends State<MusicScanPage> {
  late MusicScanBloc _musicScanBloc;
  List<String> _customScanPaths = [];
  bool _isLoadingPaths = true;

  @override
  void initState() {
    super.initState();
    _musicScanBloc = context.read<MusicScanBloc>();
    _loadCustomScanPaths();
  }

  Future<void> _loadCustomScanPaths() async {
    setState(() {
      _isLoadingPaths = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final paths = prefs.getStringList('custom_scan_paths') ?? [];
    setState(() {
      _customScanPaths = paths;
      _isLoadingPaths = false;
    });
  }

  Future<void> _saveCustomScanPaths() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_scan_paths', _customScanPaths);
  }

  Future<void> _addCustomScanPath() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        if (!_customScanPaths.contains(result)) {
          _customScanPaths.add(result);
          _saveCustomScanPaths();
        }
      });
    }
  }

  void _removeCustomScanPath(int index) {
    setState(() {
      _customScanPaths.removeAt(index);
      _saveCustomScanPaths();
    });
  }

  void _scanCustomPaths() {
    if (_customScanPaths.isNotEmpty) {
      _musicScanBloc.add(StartScanFoldersEvent(folderPaths: _customScanPaths));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加自定义扫描路径')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.scan_local_music),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _musicScanBloc.add(StartScanEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<MusicScanBloc, MusicScanState>(
        builder: (context, state) {
          if (state is MusicScanInitial) {
            return _buildInitialView(localizations);
          } else if (state is MusicScanLoading || state is MusicScanInProgress) {
            return _buildScanningView(state, localizations);
          } else if (state is MusicScanCompleted) {
            return _buildCompletedView(state, localizations);
          } else if (state is MusicScanError) {
            return _buildErrorView(state, localizations);
          } else if (state is MusicScanCancelled) {
            return _buildCancelledView(localizations);
          }

          return Container();
        },
      ),
    );
  }

  /// 构建初始视图
  Widget _buildInitialView(AppLocalizations localizations) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标准扫描部分
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '标准扫描',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '扫描系统默认音乐目录',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _musicScanBloc.add(StartScanEvent());
                      },
                      icon: const Icon(Icons.search),
                      label: Text(localizations.scan_local_music),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 自定义扫描路径部分
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
                          '自定义扫描路径',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addCustomScanPath,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '添加自定义目录进行音乐扫描',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    if (_isLoadingPaths)
                      const Center(child: CircularProgressIndicator())
                    else if (_customScanPaths.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Text(
                              '暂无自定义扫描路径',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: _addCustomScanPath,
                              child: const Text('添加路径'),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _customScanPaths.length,
                            itemBuilder: (context, index) {
                              final path = _customScanPaths[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(path),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _removeCustomScanPath(index),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _scanCustomPaths,
                            icon: const Icon(Icons.search),
                            label: const Text('扫描自定义路径'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 说明文本
            Text(
              '点击下方按钮开始扫描设备上的音乐文件。\n确保您的设备上存在音乐文件，并且文件格式受支持（如MP3、FLAC等）。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建扫描中视图
  Widget _buildScanningView(MusicScanState state, AppLocalizations localizations) {
    int progress = 0;
    String message = localizations.scanning;

    if (state is MusicScanInProgress) {
      progress = state.progress;
      message = state.message;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(value: progress / 100.0),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$progress%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () {
              _musicScanBloc.add(CancelScanEvent());
            },
            child: Text(localizations.cancel),
          ),
        ],
      ),
    );
  }

  /// 构建扫描完成视图
  Widget _buildCompletedView(MusicScanCompleted state, AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.scan_completed,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          _musicScanBloc.add(StartScanEvent());
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(localizations.scan_again),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _scanCustomPaths,
                        child: const Text('扫描自定义路径'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
             '${localizations.found_songs}: ${state.songs.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: state.songs.length,
              itemBuilder: (context, index) {
                final song = state.songs[index];
                return Card(
                  child: ListTile(
                    title: Text(song.title),
                    subtitle: Text('${song.artist} - ${song.album}'),
                    trailing: Text(
                      _formatDuration(song.duration),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误视图
  Widget _buildErrorView(MusicScanError state, AppLocalizations localizations) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.scan_failed,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '常见问题及解决方案：\n'
              '1. 确保已授予存储访问权限\n'
              '2. 检查设备上是否存在音乐文件\n'
              '3. 确保音乐文件格式受支持（MP3、FLAC等）\n'
              '4. 尝试重启应用后再次扫描',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _musicScanBloc.add(StartScanEvent());
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(localizations.try_again),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _scanCustomPaths,
                  child: const Text('扫描自定义路径'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建取消视图
  Widget _buildCancelledView(AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cancel,
            size: 64,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            localizations.scan_cancelled,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _musicScanBloc.add(StartScanEvent());
                },
                icon: const Icon(Icons.refresh),
                label: Text(localizations.scan_again),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _scanCustomPaths,
                child: const Text('扫描自定义路径'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 格式化歌曲时长
  String _formatDuration(int durationMs) {
    final Duration duration = Duration(milliseconds: durationMs);
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
