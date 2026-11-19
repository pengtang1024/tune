import 'dart:convert';
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart' as meta;
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/share/data/share_label_writer.dart';
import 'package:tune/features/share/domain/share_ai_disclosure.dart';

/// §7 隐式标识的落地证明：四个键要真的进容器、读回来口径一致、重写不叠加也不丢失，
/// 而且事实不全或写不进时必须 fail-closed。
///
/// 素材不进仓库：全部由 ffmpeg 现场合成 0.3 秒正弦到临时目录（docs/licensing.md）。
/// 本机没有可执行的 ffmpeg 时整组跳过，并在报告里如实说明。
final bool _canRun = _detectFfmpeg();

bool _detectFfmpeg() {
  try {
    return Process.runSync('ffmpeg', ['-version']).exitCode == 0;
  } on ProcessException {
    return false;
  }
}

const String _contentId =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
const ShareAiDisclosure _disclosure = ShareAiDisclosure(
  isSynthetic: true,
  providerName: '本地生成模型 v1',
  providerCode: 'tune-local',
);

Future<File> _synthesize(Directory dir, String name, List<String> codec) async {
  final target = '${dir.path}/$name';
  final result = await Process.run("ffmpeg", [
    '-y',
    '-loglevel',
    'error',
    '-f',
    'lavfi',
    '-i',
    'sine=frequency=440:duration=0.3',
    ...codec,
    target,
  ]);
  expect(result.exitCode, 0, reason: '素材合成失败：${result.stderr}');
  return File(target);
}

Future<String> _sha256(File file) async =>
    sha256.convert(await file.readAsBytes()).toString();

/// 独立于实现的第三口径：数 ffprobe 里某个键出现几次，用来证明重写不叠加条目。
Future<int> _ffprobeKeyCount(String path, String key) async {
  final result = await Process.run("ffprobe", [
    '-hide_banner',
    '-loglevel',
    'error',
    '-show_entries',
    'format_tags:stream_tags',
    '-of',
    'default=noprint_wrappers=1',
    path,
  ]);
  expect(result.exitCode, 0, reason: 'ffprobe 读不出 $path：${result.stderr}');
  final text = result.stdout is String
      ? result.stdout as String
      : utf8.decode(result.stdout as List<int>);
  final pattern = RegExp('^TAG:$key=', multiLine: true, caseSensitive: false);
  return pattern.allMatches(text).length;
}

Future<int> _durationMs(String path) async {
  final result = await Process.run("ffmpeg", ['-hide_banner', '-i', path]);
  final match = RegExp(
    r'Duration:\s*(\d+):(\d+):(\d+(?:\.\d+)?)',
  ).firstMatch('${result.stderr}${result.stdout}');
  expect(match, isNotNull, reason: 'ffmpeg 量不出 $path 的时长');
  final seconds = double.parse(match!.group(3)!);
  return (int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!)) * 1000 +
      (seconds * 1000).round();
}

void main() {
  late Directory temp;
  const writer = ShareLabelWriter();

  setUp(
    () async =>
        temp = await Directory.systemTemp.createTemp('share-label-test-'),
  );
  tearDown(() async => temp.delete(recursive: true));

  Future<File> stamping(File file) async {
    final result = await writer.stamp(
      file,
      disclosure: _disclosure,
      originContentId: _contentId,
    );
    expect(
      result.outcome,
      ShareLabelOutcome.stamped,
      reason: '${result.outcome} ${result.message}',
    );
    return file;
  }

  void expectFourKeys(Map<String, String> labels) {
    // 逐条等值，不写 containsKey 了事：MP3 读侧曾经带前导 NUL，只有 == 才拦得住。
    expect(labels[ShareLabelFacts.keyGenerated], '1');
    expect(labels[ShareLabelFacts.keyGenerator], '本地生成模型 v1');
    expect(labels[ShareLabelFacts.keyContentId], _contentId);
    expect(labels[ShareLabelFacts.keyProducer], ShareLabelFacts.producerTag);
  }

  group('四个容器的正路径', () {
    test('flac 写入四键并可读回', () async {
      final file = await stamping(
        await _synthesize(temp, 'a.flac', ['-c:a', 'flac']),
      );
      expectFourKeys(await writer.readLabels(file));
      expect(await _ffprobeKeyCount(file.path, 'AI_GENERATED'), 1);
    }, skip: !_canRun);

    test('mp3 写入四键、值不带前导或尾随 NUL', () async {
      final file = await stamping(
        await _synthesize(temp, 'a.mp3', ['-c:a', 'libmp3lame']),
      );
      final labels = await writer.readLabels(file);
      expectFourKeys(labels);
      for (final value in labels.values) {
        expect(value, isNot(contains('\u0000')), reason: '值里残留 NUL');
      }
    }, skip: !_canRun);

    test('opus 写入四键（vendor 没有 ogg 写侧，走 ffmpeg）', () async {
      final file = await stamping(
        await _synthesize(temp, 'a.opus', ['-c:a', 'libopus']),
      );
      expectFourKeys(await writer.readLabels(file));
      expect(await _ffprobeKeyCount(file.path, 'PRODUCER'), 1);
    }, skip: !_canRun);

    test('m4a 写入四键且不重编码音频', () async {
      final file = await _synthesize(temp, 'a.m4a', ['-c:a', 'aac']);
      final before = await _durationMs(file.path);
      await stamping(file);
      expectFourKeys(await writer.readLabels(file));
      // 字节没重编：时长与源一致，重编会引入编码器延迟与量化误差。
      expect(await _durationMs(file.path), before, reason: '-c copy 没保住音频字节');
    }, skip: !_canRun);
  });

  group('幂等：重写不叠加条目', () {
    final specs = [
      ('flac', <String>['-c:a', 'flac']),
      ('mp3', <String>['-c:a', 'libmp3lame']),
      ('m4a', <String>['-c:a', 'aac']),
    ];
    for (final spec in specs) {
      final ext = spec.$1;
      test('第二次 stamp 返回 alreadyStamped 且每个键只一份（$ext）', () async {
        final file = await stamping(await _synthesize(temp, 'a.$ext', spec.$2));
        final hash = await _sha256(file);
        final again = await writer.stamp(
          file,
          disclosure: _disclosure,
          originContentId: _contentId,
        );
        expect(
          again.outcome,
          ShareLabelOutcome.alreadyStamped,
          reason: again.message ?? '',
        );
        expect(await _sha256(file), hash, reason: '已标识还被改写');
        for (final key in ShareLabelFacts.requiredKeys) {
          expect(await _ffprobeKeyCount(file.path, key), 1, reason: '$key 叠加了');
        }
      }, skip: !_canRun);
    }
  });

  group('改写不丢标识（vendor 写侧补丁的回归护栏）', () {
    // 库扫描、歌词落池、其它写者都会重写元数据。上游写侧只认固定字段，不补
    // unknowns 与 TXXX 的话，一次「只改曲风」的改写就把四个标识静默删了——
    // 合规状态看着还在，文件里已经没有了。这里直接用 vendor API 改写一次。
    final specs = [
      ('flac', <String>['-c:a', 'flac']),
      ('mp3', <String>['-c:a', 'libmp3lame']),
    ];
    for (final spec in specs) {
      final ext = spec.$1;
      test('只改曲风的第二次改写后四键仍在（$ext）', () async {
        final file = await stamping(await _synthesize(temp, 'a.$ext', spec.$2));
        final tag = meta.readAllMetadata(file);
        if (tag is meta.VorbisMetadata) {
          tag.genres = <String>['爵士'];
          meta.FlacWriter().write(file, tag);
        } else if (tag is meta.Mp3Metadata) {
          tag.genres = <String>['爵士'];
          meta.Id3v4Writer().write(file, tag);
        } else {
          fail('解析出的元数据类型不符合预期：${tag.runtimeType}');
        }
        expectFourKeys(await writer.readLabels(file));
        expect(await writer.hasRequiredLabels(file), isTrue);
      }, skip: !_canRun);
    }
  });

  group('fail-closed：不许把没验证说成已标识', () {
    test('不是生成物时不写任何字节', () async {
      final file = await _synthesize(temp, 'a.flac', ['-c:a', 'flac']);
      final hash = await _sha256(file);
      final result = await writer.stamp(
        file,
        disclosure: ShareAiDisclosure.none,
        originContentId: _contentId,
      );
      expect(result.outcome, ShareLabelOutcome.failed);
      expect(await _sha256(file), hash);
      expect(await writer.hasRequiredLabels(file), isFalse);
    }, skip: !_canRun);

    test('提供者名与编码都空、或编号不是 64 位十六进制，都不写', () async {
      final file = await _synthesize(temp, 'a.flac', ['-c:a', 'flac']);
      final hash = await _sha256(file);
      const noName = ShareAiDisclosure(isSynthetic: true);
      expect(
        (await writer.stamp(
          file,
          disclosure: noName,
          originContentId: _contentId,
        )).outcome,
        ShareLabelOutcome.failed,
      );
      const badId = ShareAiDisclosure(isSynthetic: true, providerName: 'x');
      expect(
        (await writer.stamp(
          file,
          disclosure: badId,
          originContentId: 'ZZZ',
        )).outcome,
        ShareLabelOutcome.failed,
      );
      expect(await _sha256(file), hash, reason: '事实不全却改写了副本');
      expect(await writer.hasRequiredLabels(file), isFalse);
    }, skip: !_canRun);

    test('损坏文件解析不出元数据时返回 failed 且字节不动', () async {
      final broken = File('${temp.path}/broken.flac');
      final bytes = <int>[
        ...latin1.encode('fLaC'),
        ...List<int>.filled(400, 1),
      ];
      await broken.writeAsBytes(bytes);
      final hash = await _sha256(broken);
      final result = await writer.stamp(
        broken,
        disclosure: _disclosure,
        originContentId: _contentId,
      );
      expect(result.outcome, ShareLabelOutcome.failed);
      expect(await _sha256(broken), hash);
    }, skip: !_canRun);

    test('wav 承载不了定制键，判 unsupportedContainer 不动副本', () async {
      final file = await _synthesize(temp, 'a.wav', ['-c:a', 'pcm_s16le']);
      final hash = await _sha256(file);
      final result = await writer.stamp(
        file,
        disclosure: _disclosure,
        originContentId: _contentId,
      );
      expect(
        result.outcome,
        ShareLabelOutcome.unsupportedContainer,
        reason: result.message ?? '',
      );
      expect(await _sha256(file), hash);
      expect(await writer.readLabels(file), isEmpty);
    }, skip: !_canRun);

    test('没有 AI_GENERATED 时接收侧核验为 false，标完才为 true', () async {
      final file = await _synthesize(temp, 'a.flac', ['-c:a', 'flac']);
      expect(await writer.hasRequiredLabels(file), isFalse);
      await stamping(file);
      expect(await writer.hasRequiredLabels(file), isTrue);
    }, skip: !_canRun);

    test('providerName 为空时 GENERATOR 退到 providerCode', () async {
      final file = await _synthesize(temp, 'a.flac', ['-c:a', 'flac']);
      const byCode = ShareAiDisclosure(
        isSynthetic: true,
        providerCode: 'tune-local',
      );
      final result = await writer.stamp(
        file,
        disclosure: byCode,
        originContentId: _contentId,
      );
      expect(
        result.outcome,
        ShareLabelOutcome.stamped,
        reason: result.message ?? '',
      );
      expect(
        (await writer.readLabels(file))[ShareLabelFacts.keyGenerator],
        'tune-local',
      );
    }, skip: !_canRun);
  });
}
