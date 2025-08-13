/// 音乐扫描事件基类
abstract class MusicScanEvent {}

/// 开始扫描事件
class StartScanEvent extends MusicScanEvent {}

/// 开始扫描特定目录事件
class StartScanFoldersEvent extends MusicScanEvent {
  final List<String> folderPaths;

  StartScanFoldersEvent({required this.folderPaths});
}

/// 取消扫描事件
class CancelScanEvent extends MusicScanEvent {}