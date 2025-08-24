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
import 'package:tune/data/services/providers/cross_platform_music_scanner_provider.dart' as scanner_provider;
import 'package:tune/utils/logger.dart';

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

  /// 加载自定义扫描路径
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
      Log.error('加载自定义扫描路径失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 添加自定义扫描路径
  Future<void> _addCustomScanPath() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        setState(() {
          _customScanPaths = [..._customScanPaths, result];
        });
        await _saveCustomScanPaths();
      }
    } catch (e) {
      Log.error('添加自定义扫描路径失败: $e');
      _showErrorSnackBar(context.loc.failed_to_add_custom_scan_path);
    }
  }

  /// 移除自定义扫描路径
  Future<void> _removeCustomScanPath(int index) async {
    setState(() {
      _customScanPaths = List.from(_customScanPaths)..removeAt(index);
    });
    await _saveCustomScanPaths();
  }

  /// 保存自定义扫描路径
  Future<void> _saveCustomScanPaths() async {
    try {
      final persistenceService = ref.read(sharedPreferencesServiceProvider);
      await persistenceService.setStringList('custom_scan_paths', _customScanPaths);
    } catch (e) {
      Log.error('保存自定义扫描路径失败: $e');
      _showErrorSnackBar(context.loc.failed_to_save_custom_scan_paths);
    }
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
  void _startScan() async {
    try {
      final notifier = ref.read(libraryStateNotifierProvider.notifier);
      final scanner = ref.read(scanner_provider.crossPlatformMusicScannerProvider);
      
      // 开始扫描状态
      notifier.startScanning();
      
      // 执行扫描
      final songs = await scanner.scanCustomPaths(_customScanPaths);
      
      // 完成扫描
      notifier.completeScan(songs);
    } catch (e) {
      Log.error('扫描音乐失败: $e');
      final notifier = ref.read(libraryStateNotifierProvider.notifier);
      notifier.scanError('扫描音乐失败: $e');
      _showErrorSnackBar('failed_to_scan_music');
    }
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