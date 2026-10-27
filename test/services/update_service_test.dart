import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/update/update_release.dart';
import 'package:tune/data/services/update/update_service.dart';

/// The update check compares versions, picks the archive of the machine and
/// swaps the running bundle for the one the archive carries.
void main() {
  group('version comparison', () {
    test('a newer version is newer part by part', () {
      expect(UpdateService.isNewer('1.3.0', '1.4.0'), isTrue);
      expect(UpdateService.isNewer('1.9.9', '1.10.0'), isTrue);
      expect(UpdateService.isNewer('1.4.0', '2.0.0'), isTrue);
      expect(UpdateService.isNewer('1.4.0', '1.4.1'), isTrue);
    });

    test('the same or an older version is not newer', () {
      expect(UpdateService.isNewer('1.4.0', '1.4.0'), isFalse);
      expect(UpdateService.isNewer('1.4.0', '1.3.9'), isFalse);
      expect(UpdateService.isNewer('1.4.0', 'v1.3.0'), isFalse);
    });

    test('a build suffix does not change the version', () {
      expect(UpdateService.isNewer('1.4.0+5', '1.4.0'), isFalse);
      expect(UpdateService.isNewer('1.4.0+5', '1.4.1+1'), isTrue);
    });
  });

  group('release reading', () {
    test('reads the version, the notes and the archive of the platform', () {
      final release = UpdateService.parseRelease({
        'tag_name': 'v1.4.1',
        'body': 'Fixes the update check',
        'assets': [
          {
            'name': 'tune-linux-x64-1.4.1.tar.gz',
            'browser_download_url': 'https://example.com/linux.tar.gz',
            'size': 100,
          },
          {
            'name': 'tune-windows-x64-1.4.1.zip',
            'browser_download_url': 'https://example.com/windows.zip',
          },
        ],
      });

      expect(release, isNotNull);
      expect(release!.version, '1.4.1');
      expect(release.notes, 'Fixes the update check');
      expect(release.asset?.name, contains(Platform.operatingSystem));
    });

    test('a release of another platform carries no archive', () {
      final asset = UpdateService.assetFor(const [
        UpdateAsset(
          name: 'tune-windows-x64-1.0.0.zip',
          url: 'https://example.com/windows.zip',
        ),
      ], platform: 'linux');

      expect(asset, isNull);
    });

    test('an answer without a version is no release', () {
      expect(UpdateService.parseRelease(null), isNull);
      expect(UpdateService.parseRelease({'tag_name': ''}), isNull);
    });
  });

  group('install on Linux', () {
    test('the new bundle replaces the running one', () async {
      final root = await Directory.systemTemp.createTemp('tune-update-test');
      addTearDown(() => root.delete(recursive: true));

      final target = Directory('${root.path}/bundle')
        ..createSync(recursive: true);
      Directory('${target.path}/lib').createSync();
      File('${target.path}/lib/old.txt').writeAsStringSync('old');
      File('${target.path}/tune').writeAsStringSync('old binary');

      final fresh = Directory('${root.path}/fresh')
        ..createSync(recursive: true);
      Directory('${fresh.path}/lib').createSync();
      File('${fresh.path}/lib/new.txt').writeAsStringSync('new');
      File('${fresh.path}/tune').writeAsStringSync('new binary');

      final archive = '${root.path}/update.tar.gz';
      final packed = await Process.run('tar', [
        '-czf',
        archive,
        '-C',
        fresh.path,
        '.',
      ]);
      expect(packed.exitCode, 0);

      await UpdateService().installLinux(archive, target.path);

      expect(File('${target.path}/lib/new.txt').existsSync(), isTrue);
      expect(File('${target.path}/lib/old.txt').existsSync(), isFalse);
      expect(File('${target.path}/tune').readAsStringSync(), 'new binary');
      expect(Directory('${root.path}/.tune-update').existsSync(), isFalse);
      // The previous bundle is kept until the next update, so a build that
      // starts and then fails can be restored by hand.
      expect(Directory('${root.path}/.tune-previous').existsSync(), isTrue);
    });
  });
}
