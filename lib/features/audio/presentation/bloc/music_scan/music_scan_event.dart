/// 音乐扫描事件基类
abstract class MusicScanEvent {}

/// 开始扫描事件
class StartScanEvent extends MusicScanEvent {}

/// 取消扫描事件
class CancelScanEvent extends MusicScanEvent {}