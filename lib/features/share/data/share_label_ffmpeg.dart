import 'dart:io';

import 'share_label_facts.dart';

/// 用 ffmpeg 把四个键写进副本：MP4/OGG/OPUS/WEBM 家族唯一的通道（vendor 的
/// Mp4Metadata 不保留自定义键，ogg 只有读侧没有写侧）。
///
/// 先写临时文件、用 ffprobe 回读核对，通过才 rename 替换副本——验证不过时原副本
/// 一个字节都没动过。`-c copy` 是硬要求：音频字节必须逐字节保持，否则发布链路
/// 加的 1.2s 显式语音前缀会被重新编码改掉。
Future<ShareLabelResult> stampLabelsViaFfmpeg(
  File copy,
  String ext,
  Map<String, String> desired,
  String ffmpegBinary,
) async {
  // 临时产物必须保留原扩展名：ffmpeg 按输出文件后缀选 muxer，写成
  // a.m4a.ailabel 会直接 "Unable to choose an output format" 退出 234。
  final temp = File(_suffixedPath(copy.path, ext));
  final args = <String>[
    '-hide_banner',
    '-loglevel',
    'error',
    '-y',
    '-i',
    copy.path,
    '-c',
    'copy',
  ];
  if (ShareLabelFacts.movExtensions.contains(ext)) {
    args.addAll(<String>['-movflags', '+use_metadata_tags']);
  }
  for (final entry in desired.entries) {
    args.addAll(<String>['-metadata', '${entry.key}=${entry.value}']);
  }
  args.add(temp.path);
  final int exitCode;
  try {
    exitCode = (await Process.run(ffmpegBinary, args)).exitCode;
  } on ProcessException {
    return (
      outcome: ShareLabelOutcome.failed,
      message: '这台机器上没有可用的 ffmpeg，标识写不了',
    );
  }
  if (exitCode != 0) {
    await _discard(temp);
    return (
      outcome: ShareLabelOutcome.failed,
      message: 'ffmpeg 写标识失败（退出码 $exitCode），副本保持原样',
    );
  }
  // 先验证再替换：容器答应写但实际丢掉键（MP4 不加 use_metadata_tags 就是这样，
  // WAV 更是 exit 0 却哪儿都没有）在这里就会被拦下。
  final labels = await readLabelsViaFfprobe(
    ffprobeSiblingOf(ffmpegBinary),
    temp.path,
  );
  if (!ShareLabelFacts.matches(labels, desired)) {
    await _discard(temp);
    return (outcome: ShareLabelOutcome.failed, message: '写完回读对不上，不能算已标识');
  }
  try {
    await temp.rename(copy.path);
  } on FileSystemException {
    await _discard(temp);
    return (outcome: ShareLabelOutcome.failed, message: '替换副本失败，原副本保持未标识');
  }
  return (outcome: ShareLabelOutcome.stamped, message: null);
}

/// 把标记插在扩展名之前（`a.m4a` → `a.m4a.ailabel.m4a`），保住容器后缀。
String _suffixedPath(String path, String ext) {
  if (path.toLowerCase().endsWith(ext)) {
    return '${path.substring(0, path.length - ext.length)}$ext.ailabel$ext';
  }
  return '$path.ailabel';
}

Future<void> _discard(File file) async {
  try {
    if (await file.exists()) {
      await file.delete();
    }
  } on FileSystemException {
    // 临时产物删不掉只是留了个脏文件，不改变已经成立的失败结论。
  }
}

/// ffprobe 读回通道：MP4 家族的 meta 盒只有它看得见（vendor 的 Mp4Metadata 不保留
/// 自定义键），FLAC/MP3 也用它做第二口径核对。读不到就返回空表，绝不抛——调用方
/// 拿空表判「没标识」，这正是 fail-closed 要的行为。
Future<Map<String, String>> readLabelsViaFfprobe(
  String probeBinary,
  String filePath,
) async {
  final ProcessResult result;
  try {
    result = await Process.run(probeBinary, <String>[
      '-hide_banner',
      '-loglevel',
      'error',
      '-show_entries',
      'format_tags:stream_tags',
      '-of',
      'default=noprint_wrappers=1',
      filePath,
    ]);
  } on Exception {
    return const <String, String>{};
  }
  if (result.exitCode != 0) {
    return const <String, String>{};
  }
  return parseFfprobeTagLines(result.stdout.toString());
}

/// `TAG=key=value`（noprint_wrappers 口径）转成键值表；键统一大写，空值丢弃。
/// Dart 的 RegExp 不支持 `(?mi)` 这种内联组开关，标志必须走构造参数。
Map<String, String> parseFfprobeTagLines(String stdoutText) {
  final labels = <String, String>{};
  final pattern = RegExp(
    r'^tag:([A-Za-z0-9_]+)=(.+)$',
    multiLine: true,
    caseSensitive: false,
  );
  for (final match in pattern.allMatches(stdoutText)) {
    final value = (match.group(2) ?? '').trim();
    if (value.isNotEmpty) {
      labels[(match.group(1) ?? '').toUpperCase()] = value;
    }
  }
  return labels;
}

/// ffprobe 与 ffmpeg 同目录：给绝对路径就取同级的 ffprobe，PATH 上的名字就原样用。
String ffprobeSiblingOf(String ffmpegBinary) {
  if (!ffmpegBinary.endsWith('ffmpeg')) {
    return 'ffprobe';
  }
  return '${ffmpegBinary.substring(0, ffmpegBinary.length - 6)}ffprobe';
}
