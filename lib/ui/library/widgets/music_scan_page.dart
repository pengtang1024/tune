import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/ui/library/widgets/music_scan/components/custom_paths_manager.dart';
import 'package:tune/ui/library/widgets/music_scan/components/scan_control_buttons.dart';
import 'package:tune/ui/library/widgets/music_scan/components/scan_results_display.dart';
import 'package:tune/ui/library/widgets/music_scan/components/scan_status_display.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc.load_stats_failed)));
      }
    }
  }

  Future<void> _saveCustomScanPaths() async {
    try {
      final persistenceService = ref.read(sharedPreferencesServiceProvider);
      await persistenceService.setStringList('custom_scan_paths', _customScanPaths);
    } catch (e) {
      // 错误处理
      _showErrorSnackBar('${context.loc.failed_to_save_custom_path}: $e');
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

  // 显示错误提示
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // 显示成功提示
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
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

    _showSuccessSnackBar(context.loc.added_scanned_songs_to_library);
  }

  // 重置扫描
  void _resetScan() {
    final notifier = ref.read(libraryStateNotifierProvider.notifier);
    notifier.resetScan();
  }

  // 播放歌曲
  void _playSong(Song song) {
    final notifier = ref.read(libraryStateNotifierProvider.notifier);
    notifier.playSong(song);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryStateNotifierProvider);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.scan_local_music),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 扫描状态显示
            ScanStatusDisplay(state: state),

            // 自定义路径管理
            CustomPathsManager(
              customScanPaths: _customScanPaths, 
              onAddPath: _addCustomScanPath, 
              onRemovePath: _removeCustomScanPath
            ),

            // 扫描控制按钮
            ScanControlButtons(
              isScanning: state.scanStatus == ScanStatus.scanning, 
              hasCustomPaths: _customScanPaths.isNotEmpty, 
              onStartScan: _startScan
            ),

            // 扫描结果展示
            ScanResultsDisplay(
              state: state, 
              onAddToLibrary: _addToLibrary, 
              onResetScan: _resetScan, 
              onPlaySong: _playSong
            ),
          ],
        ),
      ),
    );
  }
}