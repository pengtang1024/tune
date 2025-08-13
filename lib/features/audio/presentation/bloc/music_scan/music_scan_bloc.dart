import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/core/services/platform_music_scanner_service.dart';
import 'package:tune/core/services/music_scanner_service.dart' as music_scanner_service;
import 'package:tune/features/audio/presentation/bloc/music_scan/music_scan_event.dart';
import 'package:tune/features/audio/presentation/bloc/music_scan/music_scan_state.dart';

/// 音乐扫描Bloc，用于管理本地音乐扫描过程的状态
class MusicScanBloc extends Bloc<MusicScanEvent, MusicScanState> {
  final PlatformMusicScannerService _musicScannerService;
  StreamSubscription? _scanSubscription;

  MusicScanBloc({required PlatformMusicScannerService musicScannerService})
      : _musicScannerService = musicScannerService,
        super(MusicScanInitial()) {
    on<StartScanEvent>(_onStartScan);
    on<StartScanFoldersEvent>(_onStartScanFolders);
    on<CancelScanEvent>(_onCancelScan);
    on<ResetScanEvent>(_onResetScan);
    on<_ScanProgressEvent>(_onScanProgress);
    on<_ScanErrorEvent>(_onScanError);
  }

  /// 处理开始扫描事件
  Future<void> _onStartScan(
      StartScanEvent event, Emitter<MusicScanState> emit) async {
    emit(MusicScanLoading());
    
    try {
      // 订阅扫描进度流
      _scanSubscription?.cancel();
      _scanSubscription = _musicScannerService.scanAllMusic().listen(
        (progress) {
          add(_ScanProgressEvent(progress));
        },
        onError: (error) {
          add(_ScanErrorEvent(error.toString()));
        },
      );
    } catch (e) {
      emit(MusicScanError(message: '扫描启动失败: $e'));
    }
  }

  /// 处理开始扫描特定目录事件
  Future<void> _onStartScanFolders(
      StartScanFoldersEvent event, Emitter<MusicScanState> emit) async {
    emit(MusicScanLoading());
    
    try {
      // 订阅扫描进度流
      _scanSubscription?.cancel();
      // 检查服务是否支持扫描特定目录
      if (_musicScannerService is DesktopMusicScannerService) {
        final desktopService = _musicScannerService as DesktopMusicScannerService;
        _scanSubscription = desktopService.scanMusicInFolders(event.folderPaths).listen(
          (progress) {
            add(_ScanProgressEvent(progress));
          },
          onError: (error) {
            add(_ScanErrorEvent(error.toString()));
          },
        );
      } else {
        // 对于不支持特定目录扫描的平台，使用全盘扫描
        _scanSubscription = _musicScannerService.scanAllMusic().listen(
          (progress) {
            add(_ScanProgressEvent(progress));
          },
          onError: (error) {
            add(_ScanErrorEvent(error.toString()));
          },
        );
      }
    } catch (e) {
      emit(MusicScanError(message: '扫描启动失败: $e'));
    }
  }

  /// 处理扫描进度更新
  void _onScanProgress(
      _ScanProgressEvent event, Emitter<MusicScanState> emit) {
    final progress = event.progress;
    
    switch (progress.status) {
      case music_scanner_service.ScanStatus.scanning:
        emit(MusicScanInProgress(
          progress: progress.progress,
          message: progress.message,
        ));
        break;
      case music_scanner_service.ScanStatus.completed:
        emit(MusicScanCompleted(
          songs: progress.songs,
          message: progress.message,
        ));
        break;
      case music_scanner_service.ScanStatus.error:
        emit(MusicScanError(message: progress.message));
        break;
      case music_scanner_service.ScanStatus.cancelled:
        emit(MusicScanCancelled());
        break;
      default:
        // 其他状态不处理
        break;
    }
  }

  /// 处理扫描错误
  void _onScanError(
      _ScanErrorEvent event, Emitter<MusicScanState> emit) {
    emit(MusicScanError(message: event.error));
  }

  /// 处理取消扫描事件
  Future<void> _onCancelScan(
      CancelScanEvent event, Emitter<MusicScanState> emit) async {
    _musicScannerService.cancelScan();
    emit(MusicScanCancelled());
  }

  /// 处理重置扫描事件
  Future<void> _onResetScan(
      ResetScanEvent event, Emitter<MusicScanState> emit) async {
    _scanSubscription?.cancel();
    emit(MusicScanInitial());
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    return super.close();
  }
}

/// 内部事件类，用于处理扫描进度
class _ScanProgressEvent extends MusicScanEvent {
  final music_scanner_service.ScanProgress progress;

  _ScanProgressEvent(this.progress);
}

/// 内部事件类，用于处理扫描错误
class _ScanErrorEvent extends MusicScanEvent {
  final String error;

  _ScanErrorEvent(this.error);
}