import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/update/update_check_exception.dart';
import 'package:tune/data/services/update/update_release.dart';
import 'package:tune/data/services/update/update_service.dart';

/// Serves one canned answer for every request.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.status, [this.body = const {}]);

  final int status;
  final Map<String, dynamic> body;
  int calls = 0;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Fails the way a timeout does, without a response.
class _TimeoutAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionTimeout,
    );
  }

  @override
  void close({bool force = false}) {}
}

UpdateService _serviceWith(HttpClientAdapter adapter) {
  final dio = Dio(
    BaseOptions(headers: const {'Accept': 'application/vnd.github+json'}),
  )..httpClientAdapter = adapter;
  return UpdateService(dio: dio);
}

Matcher _failure(UpdateCheckFailure failure) {
  return throwsA(
    isA<UpdateCheckException>().having(
      (error) => error.failure,
      'failure',
      failure,
    ),
  );
}

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

  group('check failures', () {
    test('a rate limited answer is a failure, not an empty page', () async {
      final service = _serviceWith(
        _StubAdapter(403, const {'message': 'API rate limit exceeded'}),
      );

      await expectLater(
        service.latest(),
        _failure(UpdateCheckFailure.rateLimited),
      );
    });

    test('a refused token is reported as unauthorized', () async {
      final service = _serviceWith(_StubAdapter(401));

      await expectLater(
        service.latest(),
        _failure(UpdateCheckFailure.unauthorized),
      );
    });

    test('a timeout is a network failure', () async {
      final service = _serviceWith(_TimeoutAdapter());

      await expectLater(service.latest(), _failure(UpdateCheckFailure.network));
    });

    test('a failed check is not cached', () async {
      final adapter = _StubAdapter(403);
      final service = _serviceWith(adapter);

      await expectLater(
        service.latest(),
        _failure(UpdateCheckFailure.rateLimited),
      );
      await expectLater(
        service.latest(),
        _failure(UpdateCheckFailure.rateLimited),
      );

      expect(adapter.calls, 2);
    });

    test('an empty page without a release is a server failure', () async {
      final service = _serviceWith(_StubAdapter(200, const {'message': 'ok'}));

      await expectLater(service.latest(), _failure(UpdateCheckFailure.server));
    });

    test('a project without a release stays an answer and is cached', () async {
      final adapter = _StubAdapter(404);
      final service = _serviceWith(adapter);

      expect(await service.latest(), isNull);
      expect(await service.latest(), isNull);

      expect(adapter.calls, 1);
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
