import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/core/extension/localizations_extension.dart';

// Music scan widgets
import 'package:tune/ui/library/widgets/music_scan/widgets/empty_state_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/widgets/scan_results_header_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/widgets/scan_status_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/widgets/song_list_item_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/widgets/custom_paths_header_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/widgets/custom_paths_description_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/widgets/custom_paths_scan_button_widget.dart';

/// 音乐扫描页面
/// 提供音乐文件扫描功能，包括自定义路径管理和扫描结果显示
class MusicScanPage extends ConsumerStatefulWidget {
  const MusicScanPage({super.key});

  @override
  ConsumerState<MusicScanPage> createState() => _MusicScanPageState();
}

class _MusicScanPageState extends ConsumerState<MusicScanPage> {
  List<String> _customScanPaths = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomScanPaths();
  }

  Future<void> _loadCustomScanPaths() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final persistenceService = ref.read(sharedPreferencesServiceProvider);
      final paths = persistenceService.getStringList('custom_scan_paths') ?? [];
      setState(() {
        _customScanPaths = paths;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.load_stats_failed)),
        );
      }
    }
  }

  Future<void> _saveCustomScanPaths() async {
    try {
      final persistenceService = ref.read(sharedPreferencesServiceProvider);
      await persistenceService.setStringList('custom_scan_paths', _customScanPaths);
    } catch (e) {
      // 错误处理
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.loc.failed_to_save_custom_path}: $e')),
        );
      }
    }
  }

  Future<void> _addCustomScanPath() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null && mounted) {
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

  // 开始扫描
  void _startScan() {
    final notifier = ref.read(libraryStateNotifierProvider.notifier);
    notifier.scanCustomPaths();
  }

  // 将扫描结果添加到音乐库
  void _addToLibrary() {
    final notifier = ref.read(libraryStateNotifierProvider.notifier);
    notifier.addScannedSongsToLibrary();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已将扫描到的歌曲添加到音乐库')),
      );
    }
  }

  // 重置扫描
  void _resetScan() {
    final notifier = ref.read(libraryStateNotifierProvider.notifier);
    notifier.resetScan();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryStateNotifierProvider);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // 扫描状态显示
        ScanStatusWidget(
          statusMessage: state.statusMessage,
          errorMessage: state.errorMessage ?? '',
        ),

        // 扫描进度条
        if (state.scanStatus == ScanStatus.scanning)
          LinearProgressIndicator(value: state.scanProgress),

        // 自定义路径部分
        CustomPathsHeaderWidget(
          onAddPath: _addCustomScanPath,
        ),

        if (_customScanPaths.isEmpty)
          const EmptyStateWidget()
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _customScanPaths.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      _customScanPaths[index],
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () => _removeCustomScanPath(index),
                    ),
                  ),
                );
              },
            ),
          ),

        // 自定义路径描述
        const CustomPathsDescriptionWidget(),

        const SizedBox(height: 16),

        // 扫描按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomPathsScanButtonWidget(
            isScanning: state.scanStatus == ScanStatus.scanning,
            hasCustomPaths: _customScanPaths.isNotEmpty,
            onPressed: _startScan,
          ),
        ),

        const SizedBox(height: 16),

        // 扫描结果
        if (state.foundSongs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ScanResultsHeaderWidget(scannedCount: state.foundSongs.length),
                ElevatedButton(
                  onPressed: _addToLibrary,
                  child: Text('添加到音乐库'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: state.foundSongs.length,
              itemBuilder: (context, index) {
                final song = state.foundSongs[index];
                final durationText =
                    Duration(milliseconds: song.duration).toString().split('.').first.padLeft(8, '0');
                return SongListItemWidget(
                  song: song,
                  durationText: durationText,
                  onPlay: () {
                    final notifier = ref.read(libraryStateNotifierProvider.notifier);
                    notifier.playSong(song);
                  },
                );
              },
            ),
          ),
        ] else if (state.scanStatus == ScanStatus.completed) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  '扫描完成，未找到新歌曲',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _resetScan,
                  child: const Text('重新扫描'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}