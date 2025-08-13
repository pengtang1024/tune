import 'package:equatable/equatable.dart';

/// 音乐扫描事件基类
abstract class MusicScanEvent extends Equatable {
  const MusicScanEvent();

  @override
  List<Object> get props => [];
}

/// 开始扫描事件
class StartScanEvent extends MusicScanEvent {
  const StartScanEvent();
}

/// 开始扫描特定目录事件
class StartScanFoldersEvent extends MusicScanEvent {
  final List<String> folderPaths;

  const StartScanFoldersEvent({required this.folderPaths});

  @override
  List<Object> get props => [folderPaths];
}

/// 取消扫描事件
class CancelScanEvent extends MusicScanEvent {
  const CancelScanEvent();
}

/// 重置扫描事件
class ResetScanEvent extends MusicScanEvent {
  const ResetScanEvent();
}