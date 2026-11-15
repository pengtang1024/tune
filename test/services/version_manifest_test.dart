import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/config/app_version.dart';
import 'package:tune/data/services/update/version_manifest.dart';

void main() {
  group('version.json in the repository', () {
    final file = File('version.json');

    test('exists and carries the version of this build', () {
      expect(file.existsSync(), isTrue, reason: '发版前先跑 tool/write_version_manifest.dart --root');
      final manifest = VersionManifest.parse(file.readAsStringSync());
      expect(manifest, isNotNull);

      final pubspec = File('pubspec.yaml').readAsLinesSync();
      final line = pubspec.firstWhere((line) => line.startsWith('version:'));
      final parts = line.substring('version:'.length).trim().split('+');

      expect(manifest!.version, parts.first);
      expect(manifest.build, int.parse(parts[1]));
      expect(manifest.version, AppVersion.version);
      expect(manifest.build, AppVersion.buildNumber);
    });

    test('lists the Linux archive with a digest and a size', () {
      final manifest = VersionManifest.parse(file.readAsStringSync())!;
      final asset = manifest.assetFor('linux');

      expect(asset, isNotNull);
      expect(asset!.url, contains('/releases/download/'));
      expect(asset.size, greaterThan(0));
      expect(asset.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
    });
  });

  group('VersionManifest.parse', () {
    test('reads the fields the client acts on', () {
      final manifest = VersionManifest.parse('''
{
  "schema": 1,
  "version": "v1.33.0",
  "build": 53,
  "released_at": "2026-11-16T00:00:00Z",
  "release_url": "https://example.test/tag/v1.33.0",
  "notes": "### 新增\\n- 一件小事",
  "min_supported": "1.20.0",
  "assets": {
    "linux-x64": {"url": "https://example.test/a.tar.gz", "size": 12, "sha256": "ab"}
  }
}
''');

      expect(manifest, isNotNull);
      expect(manifest!.version, '1.33.0');
      expect(manifest.build, 53);
      expect(manifest.notes, '### 新增\n- 一件小事');
      expect(manifest.minSupported, '1.20.0');
      expect(manifest.assetFor('linux')?.size, 12);
    });

    test('rejects a body that is not a manifest', () {
      expect(VersionManifest.parse('not json'), isNull);
      expect(VersionManifest.parse('{}'), isNull);
      expect(VersionManifest.parse('{"version": ""}'), isNull);
    });

    test('skips an archive without a digest', () {
      final manifest = VersionManifest.parse(
        '{"version": "1.33.0", "assets": {'
        '"linux-x64": {"url": "https://example.test/a", "size": 1},'
        '"windows-x64": {"url": "https://example.test/b", "sha256": " AB "}'
        '}}',
      );

      expect(manifest!.assets.keys, ['windows-x64']);
      expect(manifest.assetFor('windows')?.sha256, 'ab');
    });

    test('maps the platform of this machine', () {
      expect(VersionManifest.platformKey('linux'), 'linux-x64');
      expect(VersionManifest.platformKey('Windows'), 'windows-x64');
      expect(VersionManifest.platformKey('android'), 'android-arm64');
    });
  });

  group('VersionManifest.sameAs', () {
    VersionManifest read(String version, String sha, [int size = 12]) =>
        VersionManifest(
          version: version,
          build: 1,
          assets: {
            'linux-x64': VersionManifestAsset(
              url: 'https://example.test/$version',
              size: size,
              sha256: sha,
            ),
          },
        );

    test('accepts the same release from two sources', () {
      expect(read('1.33.0', 'ab').sameAs(read('1.33.0', 'ab')), isTrue);
    });

    test('rejects a different digest, size or version', () {
      expect(read('1.33.0', 'ab').sameAs(read('1.33.0', 'cd')), isFalse);
      expect(read('1.33.0', 'ab').sameAs(read('1.33.0', 'ab', 13)), isFalse);
      expect(read('1.33.0', 'ab').sameAs(read('1.33.1', 'ab')), isFalse);
    });
  });
}
