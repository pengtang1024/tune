import 'package:audio_metadata_reader/audio_metadata_reader.dart' as meta;

import '../domain/share_ai_disclosure.dart';
import '../domain/share_item.dart';

/// 写隐式标识的结论。
enum ShareLabelOutcome {
  /// 四个键都写进去并回读核对过。
  stamped,

  /// 副本上已有这组标识且取值一致，没有再写第二遍（不叠加重复条目）。
  alreadyStamped,

  /// 这个容器放不下定制键，副本原样保留。
  unsupportedContainer,

  /// 写失败、回读对不上或前置事实不成立：不许当成「已标识」。
  failed,
}

typedef ShareLabelResult = ({ShareLabelOutcome outcome, String? message});

/// 标识键名与容器口径。四个键的名字和取值照 docs/ai-music-sharing.md §7 原样，
/// 收口在这里唯一一份：写侧、读侧、接收侧核验都取这里的常量，避免三处各拼一次
/// 字符串再把拼错的版本当成「没标识」。
class ShareLabelFacts {
  static const String producerTag = 'tune';
  static const String keyGenerated = 'AI_GENERATED';
  static const String keyGenerator = 'GENERATOR';
  static const String keyContentId = 'CONTENT_ID';
  static const String keyProducer = 'PRODUCER';
  static const List<String> requiredKeys = [
    keyGenerated,
    keyGenerator,
    keyContentId,
    keyProducer,
  ];

  /// 定制键有明确落点、由随包 vendor 的写侧直接处理的容器。
  static const Set<String> vendorExtensions = {'.flac', '.mp3'};

  /// 只能交给 ffmpeg 改写的容器：MP4 家族的元数据模型不保留自定义键，ogg/opus
  /// 只有读侧、没有对应的写侧实现。
  static const Set<String> ffmpegExtensions = {
    '.m4a',
    '.mp4',
    '.mov',
    '.ogg',
    '.oga',
    '.opus',
    '.webm',
  };

  /// MP4 家族要这对开关才会把自定义键写进 meta 盒，否则 `-metadata` 被丢弃。
  static const Set<String> movExtensions = {'.m4a', '.mp4', '.mov'};

  /// 要写进副本的四条标识；事实不全返回 null（不写比写错好）。
  ///
  /// `originContentId` 是原始文件的 64 位小写十六进制编号，和
  /// `disclosure.contentNumber`（形如 `tune-<前 12 位>` 的人读编号）不是一回事，
  /// 所以必须由调用方单独传；后者当 CONTENT_ID 写进去会让接收侧对不上账。
  static Map<String, String>? desired(
    ShareAiDisclosure disclosure,
    String originContentId,
  ) {
    if (!disclosure.isSynthetic) {
      return null;
    }
    final name = disclosure.providerName?.trim() ?? '';
    final code = disclosure.providerCode?.trim() ?? '';
    final generator = name.isNotEmpty ? name : code;
    final contentId = originContentId.trim();
    if (generator.isEmpty || !ShareItem.isWellFormedContentId(contentId)) {
      return null;
    }
    return <String, String>{
      keyGenerated: '1',
      keyGenerator: generator,
      keyContentId: contentId,
      keyProducer: producerTag,
    };
  }

  /// 四条键逐条等值才算已标识；缺一律不认。
  static bool matches(Map<String, String> labels, Map<String, String> desired) {
    return requiredKeys.every((key) => labels[key] == desired[key]);
  }

  /// 接收侧核验：AI_GENERATED 必须是 1，其余三键都要在且非空。这里不比对生成器
  /// 具体叫什么——接收方无法假定对方的模型名，只能要求「标了、且标得全」。
  static bool hasRequired(Map<String, String> labels) {
    if (labels[keyGenerated] != '1') {
      return false;
    }
    return [
      keyGenerator,
      keyContentId,
      keyProducer,
    ].every((key) => (labels[key] ?? '').trim().isNotEmpty);
  }

  /// vendor 读侧的定制键落点：FLAC 在 `unknowns`（读时已转大写）+ 标准键 PRODUCER
  /// 归到 typed 的 `producer`；MP3 在 TXXX 描述符映射的 `customMetadata`。
  static Map<String, String> fromParserTag(meta.ParserTag tag) {
    final labels = <String, String>{};
    if (tag is meta.VorbisMetadata) {
      tag.unknowns.forEach((key, value) => labels[key.toUpperCase()] = value);
      if (tag.producer.isNotEmpty) {
        labels[keyProducer] = tag.producer.first;
      }
    } else if (tag is meta.Mp3Metadata) {
      tag.customMetadata.forEach(
        (key, value) => labels[key.toUpperCase()] = value,
      );
    }
    return labels;
  }

  /// 取小写扩展名；只在最后一个点之后取，路径里目录带点不会被误判。
  static String extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot <= path.lastIndexOf('/')) {
      return '';
    }
    return path.substring(dot).toLowerCase();
  }
}
