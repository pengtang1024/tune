import 'dart:io';

/// 分享副本的显式标识：在音频流开头插入一段节奏提示音（docs/ai-music-sharing.md §7）。
///
/// 为什么写在数据层：GB 45438—2025 要求交付出去的那份文件自带可听标识，所以标识必须进
/// 字节、跟着文件走，接收端用什么播放器都躲不掉；它不是本机播放时叠加的效果。
///
/// 为什么用节奏提示音而不是语音「本音频由人工智能生成」：§7 写明两条路都符合国标。语音要么
/// 依赖 TTS 模型（体积与下载链路归本地组件方案），要么在仓库内置一段人声素材（就得按
/// docs/licensing.md 补许可声明与来源留存）。这里由 ffmpeg 现算正弦波：不内置素材 = 不引入
/// 许可负担，也不给安装包加体积。
///
/// 失败即关闭：任何一步没成，宁可不出副本，也不能退化成原样拷贝——没有标识的副本等于
/// 绕过显式标识，比不分享更糟。
enum ShareCopyOutcome {
  /// 副本已落盘，开头带提示音。
  built,

  /// 容器或扩展名不在支持范围（含没有音频流的文件）。
  unsupportedFormat,

  /// 拿不到可执行的 ffmpeg：注入没给路径，PATH 里的 ffmpeg 也跑不起来。
  ffmpegMissing,

  /// ffmpeg 报错、输出不合法或自检没过——此时保证没有留下副本。
  failed,
}

/// 一次副本生成的结果。
///
/// file 只在 built 时非空。durationMs 是副本落盘后重新量出的时长，调用方拿它更新元数据；
/// 字节变了，内容编号要由调用方在副本生成之后按副本字节重算，所以这里返回的就是最终落盘
/// 的那个文件。message 给人看，不做断言依据。
typedef ShareCopyResult = ({
  ShareCopyOutcome outcome,
  File? file,
  int? durationMs,
  String? message,
});

/// 带显式标识的分享副本写手。
///
/// ffmpeg 的路径由外部注入：本类只接受一个闭包，不自己构造 LocalComponents——组件的解析与
/// 下载归本地组件方案（docs/local-components.md），provider 接线是上层的事。
class ShareCopyBuilder {
  const ShareCopyBuilder({
    this.ffmpegBinaryOf,
    this.preludeSeconds = 1.2,
    this.padSeconds = 0.05,
  });

  /// 解析可用的 ffmpeg 可执行文件；返回 null 表示没有登记的组件路径。
  final Future<String?> Function()? ffmpegBinaryOf;

  /// 提示音的可听时长，取 §7 写死的 1.2 秒。
  final double preludeSeconds;

  /// 提示音前后的静音垫：脉冲满幅起停最容易被听成咔哒，垫一点就没了。
  final double padSeconds;

  /// PATH 兜底用的命令名。不写死绝对路径：装在哪由本地组件方案决定。
  static const String _fallbackBinary = 'ffmpeg';

  /// 支持的容器，与音乐库扫描认的扩展名同源（music_scanner_config.dart），补上下载链路会
  /// 产出的 .oga/.opus。表外一律拒绝：副本要能被库里原有的播放器读，分享这条路不该把不支持
  /// 的容器偷偷换成另一种格式。
  static const Map<String, _ContainerProfile> _containers = {
    'flac': _ContainerProfile(codecArgs: ['-c:a', 'flac']),
    'mp3': _ContainerProfile(
      codecArgs: ['-c:a', 'libmp3lame', '-q:a', '2', '-id3v2_version', '3'],
    ),
    'ogg': _ContainerProfile(codecArgs: ['-c:a', 'libvorbis', '-q:a', '5']),
    'oga': _ContainerProfile(codecArgs: ['-c:a', 'libvorbis', '-q:a', '5']),
    'opus': _ContainerProfile(
      codecArgs: ['-c:a', 'libopus', '-b:a', '128k'],
      muxExtension: 'ogg',
    ),
    'm4a': _ContainerProfile(
      codecArgs: ['-c:a', 'aac', '-b:a', '192k'],
      needsMetadataTags: true,
    ),
    'm4b': _ContainerProfile(
      codecArgs: ['-c:a', 'aac', '-b:a', '192k'],
      needsMetadataTags: true,
    ),
    'aac': _ContainerProfile(codecArgs: ['-c:a', 'aac', '-b:a', '192k']),
    'wav': _ContainerProfile(codecArgs: ['-c:a', 'pcm_s16le']),
  };

  /// 生成 source 的带标识副本，落在 `directory`，命名 `<原名>.ai-share.<ext>`——一眼看出是分享
  /// 副本，也不会覆盖用户自己的文件。
  Future<ShareCopyResult> build(
    File source, {
    required Directory directory,
  }) async {
    final extension = _extensionOf(source.path);
    final profile = _containers[extension];
    if (profile == null) {
      return _fail(ShareCopyOutcome.unsupportedFormat, '不支持的音频容器：.$extension');
    }
    if (!await source.exists()) {
      return _fail(ShareCopyOutcome.failed, '源文件不存在：${source.path}');
    }
    final binary = await _resolveBinary();
    if (binary == null) {
      return _fail(ShareCopyOutcome.ffmpegMissing, '未找到可用的 ffmpeg');
    }
    // 先探一遍：拿时长与采样率/声道，顺带把不含音频流的文件挡掉。探测用 ffmpeg 自己——
    // 本机没有登记 ffprobe 组件，不为这件事新增一个依赖。
    final sourceProbe = await _measure(binary, source);
    if (sourceProbe == null) {
      return _fail(ShareCopyOutcome.failed, 'ffmpeg 读不出源文件：${source.path}');
    }
    if (!sourceProbe.hasAudioStream) {
      // 不挡的话 concat 会抛一句很难懂的滤镜图错误（Stream specifier ':a' matches no streams）。
      return _fail(
        ShareCopyOutcome.unsupportedFormat,
        '文件里没有音频流：${source.path}',
      );
    }
    // 交付目录在首次分享时还不存在，而 ffmpeg 打不开不存在的目录会把这件事报成「拼接失败」——
    // 所以在这里建目录，让「目录问题」和「ffmpeg 问题」分开。
    try {
      await directory.create(recursive: true);
    } on FileSystemException catch (error) {
      return _fail(ShareCopyOutcome.failed, '建不出副本目录：${error.message}');
    }
    final scratch = await Directory.systemTemp.createTemp('tune-share-copy-');
    final target = _targetFile(source, directory, extension, profile);
    try {
      final cue = File('${scratch.path}/cue.wav');
      if (!await _writeCue(binary, cue, sourceProbe)) {
        await _deleteQuietly(target);
        return _fail(ShareCopyOutcome.failed, '提示音合成失败');
      }
      final concat = await _run(binary, [
        '-y',
        '-loglevel', 'error',
        '-i', cue.path,
        '-i', source.path,
        // concat 把所有输入统一到第一个输入的格式，所以提示音按源文件的采样率与声道现算：
        // 源的音质与声道数不会被这次拼接顺手改掉。
        '-filter_complex', '[0:a][1:a]concat=n=2:v=0:a=1[out]',
        '-map', '[out]',
        // 封面是容器里一条独立的视频流，只映射 [out] 会把它当无关流丢掉。问号让源没封面时这条
        // 映射自动空转；流序号不写（-c:v 而不是 -c:v:0），实测写序号会让 mp4 家族挑错编码器。
        '-map', '1:v:0?',
        '-c:v', 'copy',
        '-disposition:v', 'attached_pic',
        // 标题/艺术家等标签跟着源走：副本是同一条内容，元数据不该在分享时丢掉。
        '-map_metadata', '1',
        ..._containerFlags(profile),
        ...profile.codecArgs,
        target.path,
      ]);
      if (concat.exitCode != 0) {
        // ffmpeg 失败时会留一个 0 字节的半成品，必须删——它不能当副本交出去。
        await _deleteQuietly(target);
        return _fail(
          ShareCopyOutcome.failed,
          '拼接失败：${_summarize(concat.stderr)}',
        );
      }
      if (!await target.exists() || await target.length() == 0) {
        await _deleteQuietly(target);
        return _fail(ShareCopyOutcome.failed, 'ffmpeg 没产出副本');
      }
      // 自检：标识真的进了字节。副本时长应约等于 源 + 提示音 + 前后静音垫；对不上说明拼接没
      // 生效，这种副本不能交付。两侧都用 _measure，量法一致才谈得上比较。
      final written = await _measure(binary, target);
      final expected = (sourceProbe.durationMs ?? 0) + _insertedMs;
      final actual = written?.durationMs;
      if (actual == null || (actual - expected).abs() > _toleranceMs) {
        await _deleteQuietly(target);
        return _fail(
          ShareCopyOutcome.failed,
          '副本时长自检没过：期望约 ${expected}ms，实际 $actual',
          durationMs: actual,
        );
      }
      return (
        outcome: ShareCopyOutcome.built,
        file: target,
        durationMs: actual,
        message: null,
      );
    } on ProcessException catch (error) {
      await _deleteQuietly(target);
      return _fail(
        ShareCopyOutcome.ffmpegMissing,
        '无法执行 ${error.executable}：${error.message}',
      );
    } finally {
      // 合成中间产物（PCM 提示音）不留在磁盘上；副本是唯一交付物。
      await _deleteQuietly(scratch);
    }
  }

  /// 解析出可用的 ffmpeg：闭包给了路径也要真跑一次确认它可执行。不在这里挡，后面每一次
  /// Process.run 都会抛 ProcessException，把「没有 ffmpeg」伪装成别的错误，而调用方要的正是
  /// 能区分这两件事（本地组件还没下好 vs 拼接真的失败）。闭包返回 null 时退回 PATH 里的
  /// ffmpeg，取法与 smart_lyrics_service.dart 一致。
  Future<String?> _resolveBinary() async {
    final injected = ffmpegBinaryOf == null ? null : await ffmpegBinaryOf!();
    final candidate = (injected == null || injected.isEmpty)
        ? _fallbackBinary
        : injected;
    return await _canRun(candidate) ? candidate : null;
  }

  Future<bool> _canRun(String binary) async {
    try {
      return (await _run(binary, ['-version'])).exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  /// 合成节奏提示音：两声短促的下行音（880Hz → 660Hz），前后各一段静音垫。
  ///
  /// 做成提示音而不是一声长鸣：长音更像故障音，两声短的才是可听的开始标记。音量压到 0.5：
  /// 正弦满幅在手机上刺耳，半幅足够听见又不压过音乐开头。
  Future<bool> _writeCue(String binary, File cue, _Probe probe) async {
    final rate = probe.sampleRate ?? 44100;
    // 只分单声道与立体声：5.1 及以上的源极少，按立体声走、由 ffmpeg 降混——显式标识优先于
    // 环绕声道，副本仍可播放。
    final layout = (probe.channels ?? 2) <= 1 ? 'mono' : 'stereo';
    // 两声之间留空隙才有「嘀—哒」的节奏感，空隙占提示音的 16%。
    final gap = (preludeSeconds * 0.16).clamp(0.0, preludeSeconds / 2);
    final burst = (preludeSeconds - gap) / 2;
    final fade = (burst / 3).clamp(0.005, 0.02);
    final graph = StringBuffer();
    for (var i = 0; i < 2; i++) {
      // 880 与 660：一个整五度下行，听得出是提示，且不需要任何素材文件。
      graph
        ..write('[$i:a]afade=t=in:st=0:d=${_seconds(fade)},')
        ..write('afade=t=out:st=${_seconds(burst - fade)}:d=${_seconds(fade)},')
        ..write(
          'volume=0.5,aformat=sample_rates=$rate:channel_layouts=$layout[b$i];',
        );
      if (i == 0 && gap > 0) {
        graph.write('anullsrc=r=$rate:cl=$layout:d=${_seconds(gap)}[gap];');
      }
    }
    graph
      ..write('anullsrc=r=$rate:cl=$layout:d=${_seconds(padSeconds)}[p0];')
      ..write('anullsrc=r=$rate:cl=$layout:d=${_seconds(padSeconds)}[p1];')
      ..write('[p0][b0]${gap > 0 ? '[gap]' : ''}[b1][p1]')
      ..write('concat=n=${gap > 0 ? 5 : 4}:v=0:a=1[cue]');
    final result = await _run(binary, [
      '-y',
      '-loglevel', 'error',
      '-f', 'lavfi',
      '-i', 'sine=frequency=880:duration=${_seconds(burst)}:sample_rate=$rate',
      '-f', 'lavfi',
      '-i', 'sine=frequency=660:duration=${_seconds(burst)}:sample_rate=$rate',
      '-filter_complex', graph.toString(),
      '-map', '[cue]',
      // 中间产物用无压缩 wav：只做一次搬运，不在合成阶段引入第二次有损编码。
      '-c:a', 'pcm_s16le',
      cue.path,
    ]);
    return result.exitCode == 0 && await cue.exists() && await cue.length() > 0;
  }

  /// 取一个文件的可信时长：容器头里的 Duration 与真解码一遍得到的 time= 取大。
  ///
  /// 为什么要取大：缺 Xing/Info 头的 VBR mp3，头里的 Duration 是按 bitrate 反推的估算值，实测
  /// 30 秒的文件读成 27.40 秒（偏 -2.6 秒）；只按头算会把正常副本误判成自检失败。解码 -f null
  /// 一遍实测 3 分钟素材只用 40ms，代价可以忽略。
  ///
  /// 取大对源与副本是同一种量法，所以自检比较的是拼接前后差了多少，不会被单侧的估算误差
  /// 单方面放大。
  Future<_Probe?> _measure(String binary, File file) async {
    final header = await _probe(binary, file);
    if (header == null) return null;
    final decoded = await _decodedDurationMs(binary, file);
    final candidates = [header.durationMs, decoded].whereType<int>().toList();
    return _Probe(
      durationMs: candidates.isEmpty
          ? null
          : candidates.reduce((a, b) => a > b ? a : b),
      sampleRate: header.sampleRate,
      channels: header.channels,
      hasAudioStream: header.hasAudioStream,
    );
  }

  /// 真解码一遍但不写任何输出，从结尾统计行取 time=。容器头给不出时长时兜底。
  Future<int?> _decodedDurationMs(String binary, File file) async {
    final result = await _run(binary, [
      '-hide_banner',
      '-nostats',
      '-i',
      file.path,
      '-f',
      'null',
      '-',
    ]);
    final matches = RegExp(
      r'time=(\d+):(\d+):(\d+(?:\.\d+)?)',
    ).allMatches('${result.stderr}${result.stdout}').toList();
    if (matches.isEmpty) return null;
    return _toMs(matches.last);
  }

  Future<_Probe?> _probe(String binary, File file) async {
    // ffmpeg -i x 不给输出文件会返回非零，这是设计如此；要的是它打到 stderr 的探测信息。
    // 这一条不能加 -loglevel error，那样连这些信息也不打印了。
    final result = await _run(binary, ['-hide_banner', '-i', file.path]);
    final text = '${result.stderr}${result.stdout}';
    if (!text.contains('Input #')) return null;
    final audio = RegExp(
      r'Audio:.*?(\d+)\s*Hz(?:,\s*([\w.()]+))?',
    ).firstMatch(text);
    final duration = RegExp(
      r'Duration:\s*(\d+):(\d+):(\d+(?:\.\d+)?)',
    ).firstMatch(text);
    return _Probe(
      durationMs: duration == null ? null : _toMs(duration),
      sampleRate: audio == null ? null : int.tryParse(audio.group(1)!),
      channels: audio == null ? null : _channelCount(audio.group(2)),
      hasAudioStream: text.contains('Audio:'),
    );
  }

  /// 把 hh:mm:ss(.kk) 换成毫秒；Duration: 与 time= 两种匹配共用。
  static int? _toMs(RegExpMatch match) {
    final hours = int.tryParse(match.group(1) ?? '');
    final minutes = int.tryParse(match.group(2) ?? '');
    final seconds = double.tryParse(match.group(3) ?? '');
    if (hours == null || minutes == null || seconds == null) return null;
    return (hours * 3600 + minutes * 60) * 1000 + (seconds * 1000).round();
  }

  static int? _channelCount(String? layout) => switch (layout?.toLowerCase()) {
    null || '' => null,
    'mono' => 1,
    'stereo' => 2,
    '2.1' => 3,
    'quad' || '5.0' || '5.1' || '5.1(side)' || '5.1(back)' => 5,
    '7.1' || '7.1(wide)' => 8,
    _ => null,
  };

  /// mp4 家族要 use_metadata_tags 才读得出自定义标签（实测不加会静默丢掉，与
  /// share_label_writer.dart 的结论一致）。
  static List<String> _containerFlags(_ContainerProfile profile) =>
      profile.needsMetadataTags
      ? const ['-movflags', 'use_metadata_tags']
      : const [];

  /// 插进流头的总时长：提示音加前后静音垫。
  int get _insertedMs => ((preludeSeconds + padSeconds * 2) * 1000).round();

  /// 自检容差。实测（ffmpeg 8.0.1，0.6 秒源 + 1.3 秒提示音）：flac/mp3/m4a 偏差 ≤10ms，
  /// opus +10ms，ADTS .aac 因帧填充 +230ms——所以取 300ms。它仍远小于「提示音根本没拼上」
  /// 的 1300ms，放不过没有标识的副本。
  static const int _toleranceMs = 300;

  File _targetFile(
    File source,
    Directory directory,
    String extension,
    _ContainerProfile profile,
  ) {
    final name = source.uri.pathSegments.last;
    final dot = name.lastIndexOf('.');
    final stem = dot <= 0 ? name : name.substring(0, dot);
    return File(
      '${directory.path}/$stem.ai-share.${profile.muxExtension ?? extension}',
    );
  }

  static ShareCopyResult _fail(
    ShareCopyOutcome outcome,
    String message, {
    int? durationMs,
  }) =>
      (outcome: outcome, file: null, durationMs: durationMs, message: message);

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    return path.substring(dot + 1).toLowerCase();
  }

  static String _seconds(double value) => value.toStringAsFixed(3);

  static String _summarize(String stderr) {
    final lines = stderr
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return lines.isEmpty ? '无错误输出' : lines.take(3).join(' / ');
  }

  Future<ProcessResult> _run(String binary, List<String> args) =>
      Process.run(binary, args);

  Future<void> _deleteQuietly(FileSystemEntity entity) async {
    try {
      if (await entity.exists()) await entity.delete(recursive: true);
    } on FileSystemException {
      // 临时目录清不掉不影响交付正确性，不值得为它让整个调用失败。
    }
  }
}

/// 每种容器怎么把带提示音的音频流写回原来的封装。
class _ContainerProfile {
  const _ContainerProfile({
    required this.codecArgs,
    this.muxExtension,
    this.needsMetadataTags = false,
  });

  /// 重编码参数：容器不变，编码回到该容器的原生音频编码。
  final List<String> codecArgs;

  /// 副本扩展名的覆盖值；默认与源一致，只有 opus 写成它的容器名 ogg。
  final String? muxExtension;

  /// 是否需要 movflags use_metadata_tags。
  final bool needsMetadataTags;
}

/// 从 ffmpeg 探测输出里读到的文件形态。
class _Probe {
  const _Probe({
    required this.durationMs,
    required this.sampleRate,
    required this.channels,
    required this.hasAudioStream,
  });

  final int? durationMs;
  final int? sampleRate;
  final int? channels;

  /// 探测输出里有没有 Audio: 这一行；没有就说明容器不含音频流。
  final bool hasAudioStream;
}
