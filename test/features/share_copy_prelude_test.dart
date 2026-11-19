import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/share/data/share_copy.dart';

/// §7 显式标识的落地证明：分享副本开头必须真的多出一段提示音（体现在时长上），源文件
/// 一个字节都不能被改动，失败时不能留下一份没有标识的拷贝。
///
/// 素材不进仓库：全部由 ffmpeg 现场合成到临时目录——与实现同源，也避免提交音频带来许可
/// 负担（docs/licensing.md）。本机没有可执行的 ffmpeg 时整组跳过。
final bool _canRun = _detectFfmpeg();

bool _detectFfmpeg() {
  try {
    return Process.runSync('ffmpeg', ['-version']).exitCode == 0;
  } on ProcessException {
    return false;
  }
}

/// 测试自己量时长，与实现同一口径：解析 `ffmpeg -i` 的 stderr（本机没登记 ffprobe 组件）。
/// 与实现的自检分开算，避免「实现自己对自己」这种闭环。
Future<int> _durationMs(String path) async {
  final result = await Process.run('ffmpeg', ['-hide_banner', '-i', path]);
  final match = RegExp(r'Duration:\s*(\d+):(\d+):(\d+(?:\.\d+)?)')
      .firstMatch('${result.stderr}${result.stdout}');
  expect(match, isNotNull, reason: 'ffmpeg 量不出 $path 的时长：${result.stderr}');
  final seconds = double.parse(match!.group(3)!);
  return (int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!)) * 1000 +
      (seconds * 1000).round();
}

/// 只读容器头里的 Duration（不做解码兜底）——用来证明 VBR 素材确实存在估算偏差。
Future<int> _headerDurationMs(String path) async {
  final result = await Process.run('ffmpeg', ['-hide_banner', '-i', path]);
  final match = RegExp(r'Duration:\s*(\d+):(\d+):(\d+(?:\.\d+)?)')
      .firstMatch('${result.stderr}${result.stdout}');
  expect(match, isNotNull, reason: result.stderr.toString());
  return (int.parse(match!.group(1)!) * 60 + int.parse(match.group(2)!)) * 1000 +
      (double.parse(match.group(3)!) * 1000).round();
}
Future<void> _synthesize(Directory dir, String name, List<String> codecArgs) async {
  // 0.6 秒正弦：够短跑得快，同时是时长断言的基准，改这里要一起改期望值。
  final result = await Process.run('ffmpeg', [
    '-y',
    '-loglevel', 'error',
    '-f', 'lavfi',
    '-i', 'sine=frequency=440:duration=0.6',
    ...codecArgs,
    '${dir.path}/$name',
  ]);
  expect(result.exitCode, 0, reason: '素材合成失败：${result.stderr}');
}

Future<List<int>> _head(File file, int count) async {
  final handle = await file.open();
  try {
    return await handle.read(count);
  } finally {
    await handle.close();
  }
}

Future<String> _sha256(File file) async => sha256.convert(await file.readAsBytes()).toString();

void main() {
  late Directory temp;

  setUp(() async => temp = await Directory.systemTemp.createTemp('share-prelude-test-'));
  tearDown(() async => temp.delete(recursive: true));

  group('分享副本的节奏提示音', () {
    test('flac 副本 = 源 + 1.3 秒，容器仍是 fLaC，源哈希不动', () async {
      await _synthesize(temp, 'a.flac', ['-c:a', 'flac']);
      final source = File('${temp.path}/a.flac');
      final before = await _sha256(source);
      final sourceMs = await _durationMs(source.path);

      final out = Directory('${temp.path}/out');
      final result = await ShareCopyBuilder().build(source, directory: out);

      expect(result.outcome, ShareCopyOutcome.built, reason: result.message ?? '');
      expect(result.file, isNotNull);
      expect(result.file!.path, endsWith('a.ai-share.flac'));
      expect(await result.file!.length(), greaterThan(0));
      // 提示音没进字节的话，这里会整整差出 1300ms。
      expect(await _durationMs(result.file!.path), closeTo(sourceMs + 1300, 300),
          reason: '副本时长没多出提示音，说明显式标识没进音频流');
      expect(await _head(result.file!, 4), 'fLaC'.codeUnits);
      expect(await _sha256(source), before, reason: '原始文件被改动了');
    }, skip: !_canRun);

    test('mp3 副本容器不变（ID3v2 或帧同步头），源哈希不动', () async {
      await _synthesize(temp, 'a.mp3', ['-c:a', 'libmp3lame', '-q:a', '2']);
      final source = File('${temp.path}/a.mp3');
      final before = await _sha256(source);
      final sourceMs = await _durationMs(source.path);

      final result = await ShareCopyBuilder().build(source, directory: temp);

      expect(result.outcome, ShareCopyOutcome.built, reason: result.message ?? '');
      expect(await _durationMs(result.file!.path), closeTo(sourceMs + 1300, 300));
      final head = await _head(result.file!, 3);
      final isId3 = head.join(',') == 'ID3'.codeUnits.join(',');
      final isFrameSync = head[0] == 0xFF && (head[1] & 0xE0) == 0xE0;
      expect(isId3 || isFrameSync, isTrue, reason: '副本不是 mp3 容器：$head');
      expect(await _sha256(source), before);
    }, skip: !_canRun);

    test('opus 副本写成 .ogg 文件名，容器仍是 OggS', () async {
      await _synthesize(temp, 'a.opus', ['-c:a', 'libopus', '-b:a', '128k']);
      final source = File('${temp.path}/a.opus');
      final before = await _sha256(source);

      final result = await ShareCopyBuilder().build(source, directory: temp);

      expect(result.outcome, ShareCopyOutcome.built, reason: result.message ?? '');
      // opus 的容器就是 ogg，所以副本扩展名换成 ogg：按容器认，不靠扩展名猜编码。
      expect(result.file!.path, endsWith('a.ai-share.ogg'));
      expect(await _head(result.file!, 4), 'OggS'.codeUnits);
      expect(await _sha256(source), before);
    }, skip: !_canRun);

    test('m4a 副本仍是 mp4 家族（第 4-8 字节 ftyp），时长对得上', () async {
      await _synthesize(temp, 'a.m4a', ['-c:a', 'aac', '-b:a', '192k']);
      final source = File('${temp.path}/a.m4a');
      final before = await _sha256(source);
      final sourceMs = await _durationMs(source.path);

      final result = await ShareCopyBuilder().build(source, directory: temp);

      expect(result.outcome, ShareCopyOutcome.built, reason: result.message ?? '');
      final head = await _head(result.file!, 8);
      expect(head.sublist(4, 8), 'ftyp'.codeUnits, reason: '副本不是 mp4 家族容器');
      expect(await _durationMs(result.file!.path), closeTo(sourceMs + 1300, 300));
      expect(await _sha256(source), before);
    }, skip: !_canRun);

    // 直接回答「VBR mp3 的 Duration 是估算值，容差够不够」：去掉 Xing/Info 头，容器头里的
    // 时长按 bitrate 反推，实测 30 秒只读成 27.4 秒。若自检只用头时长，这条必然被误判成
    // failed——所以实现里取「头时长与解码时长的大值」，这里钉住这个行为。
    test('无 Xing 头的 VBR mp3：头时长偏 -2.6 秒也不会误杀正常副本', () async {
      final made = await Process.run('ffmpeg', [
        '-y',
        '-loglevel', 'error',
        '-f', 'lavfi',
        '-i', 'sine=frequency=440:duration=30',
        '-c:a', 'libmp3lame', '-q:a', '2', '-write_xing', '0',
        '${temp.path}/vbr.mp3',
      ]);
      expect(made.exitCode, 0, reason: made.stderr.toString());
      final source = File('${temp.path}/vbr.mp3');
      final before = await _sha256(source);
      // 前提：头时长确实偏短，否则这条用例就退化成普通 mp3 用例了。
      expect(await _headerDurationMs(source.path), lessThan(28500),
          reason: '素材没复现出估算偏差，用例失去意义');

      final result = await ShareCopyBuilder().build(source, directory: temp);

      expect(result.outcome, ShareCopyOutcome.built, reason: result.message ?? '');
      expect(result.durationMs, closeTo(31300, 300),
          reason: '30 秒源 + 1.3 秒提示音；自检被估算值骗到就会走不到这里');
      expect(await _sha256(source), before);
    }, skip: !_canRun);

    test('表外扩展名直接判不支持，不产出任何副本', () async {
      final source = File('${temp.path}/a.wv')..writeAsBytesSync([1, 2, 3, 4, 5]);

      final result = await ShareCopyBuilder().build(source, directory: temp);

      expect(result.outcome, ShareCopyOutcome.unsupportedFormat);
      expect(result.file, isNull);
      expect(File('${temp.path}/a.ai-share.wv').existsSync(), isFalse);
      expect(Directory('${temp.path}/out').existsSync(), isFalse);
    }, skip: !_canRun);

    test('没有音频流的容器判为不支持', () async {
      // 只有视频流的 m4a：不挡的话 concat 会抛一句看不懂的滤镜图错误。
      final made = await Process.run('ffmpeg', [
        '-y',
        '-loglevel', 'error',
        '-f', 'lavfi',
        '-i', 'color=c=black:s=64x64:d=0.5',
        '-pix_fmt', 'yuv420p',
        '${temp.path}/video_only.m4a',
      ]);
      expect(made.exitCode, 0, reason: made.stderr.toString());

      final result = await ShareCopyBuilder()
          .build(File('${temp.path}/video_only.m4a'), directory: temp);

      expect(result.outcome, ShareCopyOutcome.unsupportedFormat);
      expect(result.file, isNull);
      expect(File('${temp.path}/video_only.ai-share.m4a').existsSync(), isFalse);
    }, skip: !_canRun);

    test('注入的 ffmpeg 不可执行：判 ffmpegMissing 且目录里没有副本', () async {
      await _synthesize(temp, 'g.flac', ['-c:a', 'flac']);
      final outDir = Directory('${temp.path}/out2');
      final builder = ShareCopyBuilder(ffmpegBinaryOf: () async => '/nonexistent/ffmpeg');

      final result = await builder.build(File('${temp.path}/g.flac'), directory: outDir);

      // 必须是 ffmpegMissing 而不是笼统的 failed：上层据此提示「先去设置里装 ffmpeg」。
      expect(result.outcome, ShareCopyOutcome.ffmpegMissing, reason: result.message ?? '');
      expect(result.file, isNull);
      // 失败即关闭：不能留下一份原样拷贝当副本。
      if (outDir.existsSync()) {
        expect(outDir.listSync(), isEmpty, reason: '失败却留下了产物');
      }
      expect(File('${temp.path}/g.ai-share.flac').existsSync(), isFalse);
    }, skip: !_canRun);

    test('坏文件不会退化成原样拷贝（fail-closed）', () async {
      final bad = File('${temp.path}/bad.flac')
        ..writeAsBytesSync(List<int>.filled(4096, 7));

      final result = await ShareCopyBuilder().build(bad, directory: temp);

      expect(result.outcome, isNot(ShareCopyOutcome.built), reason: result.message ?? '');
      expect(result.file, isNull);
      expect(File('${temp.path}/bad.ai-share.flac').existsSync(), isFalse,
          reason: '没标识的拷贝等于绕过显式标识');
    }, skip: !_canRun);
  });
}
