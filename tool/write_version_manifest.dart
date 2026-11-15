// 生成自动更新读取的 version.json（docs/update-cdn.md §3）。
//
//   dart run tool/write_version_manifest.dart --archive dist/tune-linux-x64-1.32.0.tar.gz
//   dart run tool/write_version_manifest.dart --archive <包> --root
//
// 版本号与构建号取自 pubspec.yaml，说明取自 CHANGELOG.md 顶部同版本段，
// 大小与 sha256 由归档实测。默认写 dist/version.json；加 --root 时同时写仓库根
// 的 version.json——发版要提交的那一份，test/version_manifest_test.dart 会核对
// 它与 pubspec / AppVersion 是否一致。
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const _product = 'pengtang1024/tune';
const _platform = 'linux-x64';

Future<void> main(List<String> args) async {
  String? archive;
  var out = 'dist/version.json';
  var writeRoot = false;
  var minSupported = '';
  String? releasedAt;

  for (var index = 0; index < args.length; index++) {
    switch (args[index]) {
      case '--archive':
        archive = args[++index];
      case '--out':
        out = args[++index];
      case '--root':
        writeRoot = true;
      case '--min-supported':
        minSupported = args[++index];
      case '--released-at':
        releasedAt = args[++index];
      case '-h' || '--help':
        stdout.writeln(_usage);
        return;
      default:
        stderr.writeln('未知选项：${args[index]}');
        exitCode = 2;
        return;
    }
  }

  if (archive == null) {
    stderr.writeln('缺少 --archive <归档路径>');
    stderr.writeln(_usage);
    exitCode = 2;
    return;
  }

  final file = File(archive);
  if (!file.existsSync()) {
    stderr.writeln('找不到归档：$archive');
    exitCode = 1;
    return;
  }

  final version = _readVersion();
  final manifest = <String, Object?>{
    'schema': 1,
    'version': version.version,
    'build': version.build,
    'released_at': releasedAt ?? _now(),
    'release_url':
        'https://github.com/$_product/releases/tag/v${version.version}',
    'notes': _readNotes(version.version),
    'min_supported': minSupported,
    'assets': {
      _platform: {
        'url':
            'https://github.com/$_product/releases/download/'
            'v${version.version}/${file.uri.pathSegments.last}',
        'size': file.lengthSync(),
        'sha256': await _sha256(file),
      },
    },
  };

  final body = '${const JsonEncoder.withIndent('  ').convert(manifest)}\n';
  _write(out, body);
  if (writeRoot) _write('version.json', body);
}

const _usage = '''
用法：dart run tool/write_version_manifest.dart --archive <归档> [选项]

  --archive <路径>       必填。要写进清单的发布归档
  --out <路径>           输出文件，默认 dist/version.json
  --root                 同时写仓库根的 version.json
  --min-supported <版本> 低于此版本强制提示，默认留空
  --released-at <时间>   发行时间，默认当前 UTC 时间
''';

({String version, int build}) _readVersion() {
  final line = _lines('pubspec.yaml').firstWhere(
    (line) => line.startsWith('version:'),
    orElse: () => throw StateError('pubspec.yaml 里没有 version'),
  );
  final raw = line.substring('version:'.length).trim();
  final parts = raw.split('+');
  final build = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return (version: parts.first, build: build);
}

/// The CHANGELOG section of [version], without its heading.
String _readNotes(String version) {
  final lines = _lines('CHANGELOG.md');
  final start = lines.indexWhere(
    (line) => line.startsWith('## [$version]') || line.startsWith('## $version'),
  );
  if (start < 0) return '';
  final end = lines.indexWhere(
    (line) => line.startsWith('## '),
    start + 1,
  );
  final body = lines.sublist(start + 1, end < 0 ? lines.length : end);
  while (body.isNotEmpty && body.first.trim().isEmpty) {
    body.removeAt(0);
  }
  while (body.isNotEmpty && body.last.trim().isEmpty) {
    body.removeLast();
  }
  return body.join('\n');
}

List<String> _lines(String path) => File(path).readAsLinesSync();

String _now() =>
    '${DateTime.now().toUtc().toIso8601String().split('.').first}Z';

Future<String> _sha256(File file) async {
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString();
}

void _write(String path, String body) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(body);
  stdout.writeln(file.path);
}
