import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart' as meta;

import '../domain/share_ai_disclosure.dart';
import 'share_label_facts.dart';
import 'share_label_ffmpeg.dart';

export 'share_label_facts.dart'
    show ShareLabelFacts, ShareLabelOutcome, ShareLabelResult;

/// 把 AI 隐式标识写进**分享副本**的文件元数据（docs/ai-music-sharing.md §7）。
///
/// 四个键的名字与取值收口在 [ShareLabelFacts] 一处。**调用方负责先复制，本服务不碰
/// 原始文件**：只改写传进来的那一份副本。所有路径 fail-closed：写不下去、或写完
/// 回读对不上，就返回非 stamped，绝不把「没验证」说成「已标识」。
class ShareLabelWriter {
  /// `ffmpegBinaryOf` 解析 ffmpeg 可执行文件；为 null 时用 PATH 上的 `ffmpeg`。
  /// 不硬编码绝对路径：本机组件路径由调用方按 local_component_registry 给
  /// （与 SmartLyricsService 同一口径）。
  const ShareLabelWriter({this.ffmpegBinaryOf});

  final Future<String?> Function()? ffmpegBinaryOf;

  /// 往副本写标识；前置事实不成立时不写任何字节。
  Future<ShareLabelResult> stamp(
    File copy, {
    required ShareAiDisclosure disclosure,
    required String originContentId,
  }) async {
    final desired = ShareLabelFacts.desired(disclosure, originContentId);
    if (desired == null) {
      // 不是生成物、提供者名与编码都空、编号不是 64 位小写十六进制——写进去的
      // 标识本身就是错的，宁可不写。
      return _failed('标识事实不完整，未写入任何字节');
    }
    if (!await copy.exists()) {
      return _failed('分享副本不存在：${copy.path}');
    }
    final ext = ShareLabelFacts.extensionOf(copy.path);
    if (ShareLabelFacts.vendorExtensions.contains(ext)) {
      return _stampViaVendor(copy, desired);
    }
    if (ShareLabelFacts.ffmpegExtensions.contains(ext)) {
      if (ShareLabelFacts.matches(await readLabels(copy), desired)) {
        return _done(ShareLabelOutcome.alreadyStamped);
      }
      final String ffmpeg;
      try {
        ffmpeg = await _resolveFfmpeg();
      } on Exception {
        return _failed('解析 ffmpeg 路径失败，标识写不了');
      }
      return stampLabelsViaFfmpeg(copy, ext, desired, ffmpeg);
    }
    return (
      outcome: ShareLabelOutcome.unsupportedContainer,
      message: '$ext 容器放不下这四个定制键，副本保持原样',
    );
  }

  /// 读回文件上的标识；容器不认识或读不出时返回空表，不抛异常。
  Future<Map<String, String>> readLabels(File file) async {
    final ext = ShareLabelFacts.extensionOf(file.path);
    final isVendor = ShareLabelFacts.vendorExtensions.contains(ext);
    if (!isVendor && !ShareLabelFacts.ffmpegExtensions.contains(ext)) {
      return const <String, String>{};
    }
    // 两口径合并：vendor 读侧知道 FLAC unknowns / MP3 TXXX 的确切落点，ffprobe
    // 看得见 MP4 meta 盒与 ogg 流标签。只补缺不覆盖——ffprobe 会把 MP4 的 ©too
    // 之类映射成别的键名，同一键以本包读到的为准。
    final labels = <String, String>{};
    final tag = isVendor ? await _parseVendor(file) : null;
    if (tag != null) {
      labels.addAll(ShareLabelFacts.fromParserTag(tag));
    }
    if (ShareLabelFacts.requiredKeys.any((key) => !labels.containsKey(key))) {
      for (final entry in (await _probe(file)).entries) {
        labels.putIfAbsent(entry.key, () => entry.value);
      }
    }
    return labels;
  }

  /// 接收侧核验用：四键齐全且 AI_GENERATED=1。
  Future<bool> hasRequiredLabels(File file) async {
    return ShareLabelFacts.hasRequired(await readLabels(file));
  }

  Future<ShareLabelResult> _stampViaVendor(
    File copy,
    Map<String, String> desired,
  ) async {
    final tag = await _parseVendor(copy);
    if (tag == null) {
      return _failed('解析元数据失败，未写入标识');
    }
    if (ShareLabelFacts.matches(ShareLabelFacts.fromParserTag(tag), desired)) {
      return _done(ShareLabelOutcome.alreadyStamped);
    }
    try {
      // 按解析出的实际类型直接调对应 writer，不走 replaceMetadata：那条分发要求
      // 文件已有 ID3v2 标签，无标签的 MP3 会所有分支都不成立、静默什么都不写。
      if (tag is meta.VorbisMetadata) {
        for (final entry in desired.entries) {
          if (entry.key == ShareLabelFacts.keyProducer) {
            // PRODUCER 是 Vorbis comment 的标准键，读侧归到 typed 字段，所以写
            // 它而不是塞进 unknowns（否则同一个键出现两份）。
            tag.producer = <String>[entry.value];
          } else {
            tag.unknowns[entry.key] = entry.value;
          }
        }
        meta.FlacWriter().write(copy, tag);
      } else if (tag is meta.Mp3Metadata) {
        // ID3v2 没有 PRODUCER 文本帧，四个键统一走 TXXX（描述=键名）。
        tag.customMetadata.addAll(desired);
        meta.Id3v4Writer().write(copy, tag);
      } else {
        return _failed('读到的元数据类型不支持定制键写入，未改写副本');
      }
    } on Exception catch (error) {
      return _failed('写入标识失败：$error');
    }
    // 写完必须回读核对：对不上就不算 stamped，不回头狡辩「应该写进去了」。
    return ShareLabelFacts.matches(await readLabels(copy), desired)
        ? _done(ShareLabelOutcome.stamped)
        : _failed('写完回读对不上，不能算已标识');
  }

  /// vendor 的解析 API 是同步的，这里只在分享发布/接收这类后台路径上调用，不进
  /// 每帧重建的 UI 路径（docs/performance.md §1.3）。getImage 保持默认 true：写侧会
  /// 用读到的 pictures 重建封面块，不读回来就等于把副本里已有的封面删掉。
  Future<meta.ParserTag?> _parseVendor(File file) async {
    try {
      return meta.readAllMetadata(file);
    } on Exception {
      return null;
    }
  }

  Future<Map<String, String>> _probe(File file) async {
    try {
      return await readLabelsViaFfprobe(
        ffprobeSiblingOf(await _resolveFfmpeg()),
        file.path,
      );
    } on Exception {
      return const <String, String>{};
    }
  }

  Future<String> _resolveFfmpeg() async {
    return await ffmpegBinaryOf?.call() ?? 'ffmpeg';
  }

  static ShareLabelResult _done(ShareLabelOutcome outcome) {
    return (outcome: outcome, message: null);
  }

  static ShareLabelResult _failed(String message) {
    return (outcome: ShareLabelOutcome.failed, message: message);
  }
}
