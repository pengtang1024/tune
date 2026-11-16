/// libmpv 的缓存策略。
///
/// 这是 Tune 唯一声明「音频缓冲占多少内存、要不要落一份磁盘副本」的地方。
/// 播放后端（[MediaKitPlayerService]）在建好 mpv 实例后逐条应用它，业务层
/// 不直接碰到 mpv 的属性名。
///
/// 为什么磁盘缓存默认关闭：
///
/// - mpv 的 `cache-on-disk` 是把解复用缓存区镜像到文件，价值在于给视频
///   拖进度时不必重新下载。音乐是顺序流，跳转要的数据本来就在内存缓存窗口
///   里，落盘换不来体验，只多一份写盘与清理负担。
/// - 曾经的状态是「想要但拿不到」：media_kit 1.2.6 硬开 `cache-on-disk=yes`，
///   而 mpv 0.41 的 `--demuxer-cache-dir` 默认是空串，解析成 `-` 之后每个流
///   都会打印一条 `Failed to create file cache`。现在缓存策略由这里显式决定，
///   这条日志的来源随之消失——不是被屏蔽，而是不再触发。
///
/// 要改成落盘，就把 [diskCacheDirectory] 指到应用支持目录下的缓存目录
/// （调用方负责创建与清理），属性映射会自动把目录交给 mpv。
class MpvPolicy {
  const MpvPolicy({
    this.bufferBytes = defaultBufferBytes,
    this.diskCacheDirectory,
  });

  /// 8 MiB。libmpv 的 `demuxer-max-bytes` 与 `demuxer-max-back-bytes` 各取
  /// 一份（见 [toProperties] 的说明），默认 32 MiB 时播一首本地曲就多驻留
  /// ~35 MB。音乐采样率固定，8 MiB 够缓存约 3 分钟的 320 kbps 音频，也够
  /// 网络流顶住常见抖动。
  static const int defaultBufferBytes = 8 * 1024 * 1024;

  /// 解复用缓存区的内存上限，同时作为 mpv 两个方向的缓存额度。
  final int bufferBytes;

  /// 磁盘缓存目录；`null` 表示不落盘。
  final String? diskCacheDirectory;

  /// 是否启用磁盘缓存。
  bool get usesDiskCache => diskCacheDirectory != null;

  /// 需要写到 mpv 上的属性。
  ///
  /// 只声明与缓存有关的项：音量、播放速度、日志级别等由播放后端各自传参，
  /// 不在这里重复。`demuxer-max-bytes` 与 `demuxer-max-back-bytes` 取同一个
  /// 值，所以内存驻留上限约为 [bufferBytes] 的两倍——这是 mpv 的语义，不是
  /// 这里的口径，写清楚以免下次误以为是 bug。
  Map<String, String> toProperties() {
    final directory = diskCacheDirectory;
    return <String, String>{
      'cache': 'yes',
      'cache-on-disk': directory == null ? 'no' : 'yes',
      'demuxer-cache-dir': ?directory,
      'demuxer-max-bytes': bufferBytes.toString(),
      'demuxer-max-back-bytes': bufferBytes.toString(),
    };
  }
}
