import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/update/update_check_exception.dart';
import 'package:tune/data/services/update/update_release.dart';
import 'package:tune/data/services/update/update_service.dart';
import 'package:tune/data/services/update/version_manifest_source.dart';

/// Answers each host of the check, so the tiers can be told apart.
class _RoutingAdapter implements HttpClientAdapter {
  _RoutingAdapter(this.routes);

  final Map<String, ResponseBody Function(RequestOptions)> routes;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final answer = routes[options.uri.host];
    if (answer == null) return _body('not found', status: 404);
    return answer(options);
  }

  @override
  void close({bool force = false}) {}
}

final _cdn = Uri.parse(
  'https://cdn.jsdelivr.net/gh/pengtang1024/tune@master/version.json',
).host;
final _raw = Uri.parse(
  'https://raw.githubusercontent.com/pengtang1024/tune/master/version.json',
).host;
const _api = 'api.github.com';

ResponseBody _body(
  String text, {
  int status = 200,
  Map<String, List<String>> headers = const {},
}) {
  return ResponseBody.fromString(
    text,
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...headers,
    },
  );
}

ResponseBody _failureBody(int status) => _body('{"message":"error"}', status: status);

Map<String, dynamic> _manifest({
  String version = '1.33.0',
  int build = 53,
  String sha = 'ab',
}) {
  return {
    'schema': 1,
    'version': version,
    'build': build,
    'released_at': '2026-11-16T00:00:00Z',
    'release_url': 'https://example.com/tag/v$version',
    'notes': '### 新增\n- 一件小事',
    'min_supported': '',
    'assets': {
      'linux-x64': {
        'url': 'https://example.com/download/tune-linux-x64-$version.tar.gz',
        'size': 123,
        'sha256': sha,
      },
    },
  };
}

(UpdateService, _RoutingAdapter) _serviceWith(
  Map<String, ResponseBody Function(RequestOptions)> routes,
) {
  final adapter = _RoutingAdapter(routes);
  final dio = Dio()..httpClientAdapter = adapter;
  return (UpdateService(dio: dio), adapter);
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

final _releaseBody = <String, dynamic>{
  'tag_name': 'v1.31.0',
  'body': 'notes',
  'assets': [
    {
      'name': 'tune-linux-x64-1.31.0.tar.gz',
      'size': 100,
      'browser_download_url': 'https://example.com/tune.tar.gz',
    },
  ],
};

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

    test('a build number breaks the tie between equal versions', () {
      expect(UpdateService.isNewer('1.4.0+52', '1.4.0+53'), isTrue);
      expect(UpdateService.isNewer('1.4.0+53', '1.4.0+53'), isFalse);
      expect(UpdateService.isNewer('1.4.0+53', '1.4.0+52'), isFalse);
      // A list without a build number does not beat a newer build.
      expect(UpdateService.isNewer('1.4.0+5', '1.4.0'), isFalse);
      expect(UpdateService.isNewer('1.4.0+5', '1.4.1+1'), isTrue);
    });
  });

  group('static list', () {
    test('the CDN list is enough and the release page is not asked', () async {
      final (service, adapter) = _serviceWith({
        _cdn: (_) => _body(jsonEncode(_manifest())),
      });

      final release = await service.latest(environment: const {});

      expect(release?.version, '1.33.0');
      expect(release?.build, 53);
      expect(release?.notes, '### 新增\n- 一件小事');
      expect(release?.asset?.name, 'tune-linux-x64-1.33.0.tar.gz');
      expect(release?.asset?.sha256, 'ab');
      expect(adapter.requests.map((request) => request.uri.host), isNot(contains(_api)));
    });

    test('the raw host covers a CDN that cannot be reached', () async {
      final (service, _) = _serviceWith({
        _cdn: (_) => _failureBody(500),
        _raw: (_) => _body(jsonEncode(_manifest(version: '1.34.0'))),
      });

      final release = await service.latest(environment: const {});

      expect(release?.version, '1.34.0');
    });

    test('two lists that disagree are refused', () async {
      final (service, _) = _serviceWith({
        _cdn: (_) => _body(jsonEncode(_manifest(sha: 'aa'))),
        _raw: (_) => _body(jsonEncode(_manifest(sha: 'bb'))),
      });

      await expectLater(
        service.latest(environment: const {}),
        _failure(UpdateCheckFailure.manifestMismatch),
      );
    });

    test('a list without an archive is a different release', () async {
      final (service, _) = _serviceWith({
        _cdn: (_) => _body(jsonEncode(_manifest())),
        _raw: (_) => _body('{"version":"1.33.0","assets":{}}'),
      });

      await expectLater(
        service.latest(environment: const {}),
        _failure(UpdateCheckFailure.manifestMismatch),
      );
    });

    test('a 304 keeps the parsed list and sends the validator', () async {
      var asked = 0;
      final (service, adapter) = _serviceWith({
        _cdn: (request) {
          asked++;
          if (request.headers['If-None-Match'] == 'W/"abc"') {
            return _body('', status: 304);
          }
          return _body(
            jsonEncode(_manifest()),
            headers: {
              'etag': ['W/"abc"'],
            },
          );
        },
        _raw: (_) => _body(jsonEncode(_manifest())),
      });

      expect((await service.latest(environment: const {}))?.version, '1.33.0');
      expect(
        (await service.latest(
          environment: const {},
          forceRefresh: true,
        ))?.version,
        '1.33.0',
      );

      final cdnCalls = adapter.requests.where(
        (request) => request.uri.host == _cdn,
      );
      expect(asked, 2);
      expect(cdnCalls.length, 2);
      expect(cdnCalls.last.headers['If-None-Match'], 'W/"abc"');
    });

    test('a token never rides on a static list request', () async {
      final (service, adapter) = _serviceWith({
        _cdn: (_) => _body(jsonEncode(_manifest())),
        _raw: (_) => _body(jsonEncode(_manifest())),
      });

      await service.latest(manualToken: 'secret', environment: const {});

      for (final request in adapter.requests) {
        expect(request.headers.containsKey('Authorization'), isFalse);
      }
    });
  });

  group('reuse window', () {
    test('a round an hour later asks again instead of reusing', () async {
      var now = DateTime.utc(2026);
      final adapter = _RoutingAdapter({
        _cdn: (_) => _body(jsonEncode(_manifest())),
        _raw: (_) => _body(jsonEncode(_manifest())),
      });
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UpdateService(dio: dio, clock: () => now);

      await service.latest(environment: const {});
      expect(adapter.requests.length, 2);

      // A second ask inside the same round reuses the answer.
      now = now.add(const Duration(minutes: 5));
      await service.latest(environment: const {});
      expect(adapter.requests.length, 2);

      // The next hourly round is past the window, so it asks again: an hour
      // of waiting never ends in a cached answer.
      now = now.add(const Duration(hours: 1));
      await service.latest(environment: const {});
      expect(adapter.requests.length, 4);
    });
  });

  group('release page fallback', () {
    test('the release page is read when no list exists yet', () async {
      final (service, adapter) = _serviceWith({
        _cdn: (_) => _body('', status: 404),
        _raw: (_) => _body('', status: 404),
        _api: (_) => _body(jsonEncode(_releaseBody)),
      });

      final release = await service.latest(environment: const {});

      expect(release?.version, '1.31.0');
      expect(adapter.requests.last.uri.host, _api);
    });

    test('a token rides on the release page as a bearer header', () async {
      final (service, adapter) = _serviceWith({
        _cdn: (_) => _body('', status: 404),
        _raw: (_) => _body('', status: 404),
        _api: (_) => _body(jsonEncode(_releaseBody)),
      });

      await service.latest(manualToken: 'secret', environment: const {});

      final apiCall = adapter.requests.last;
      expect(apiCall.headers['Authorization'], 'Bearer secret');
    });

    test('an environment token is used when the field is empty', () {
      expect(
        UpdateService.resolveToken(
          manualToken: '',
          environment: const {'GITHUB_TOKEN': 'from-github'},
        ),
        'from-github',
      );
    });

    test('a rate limited release page is a failure, not an empty page', () async {
      final (service, _) = _serviceWith({
        _cdn: (_) => _body('', status: 404),
        _raw: (_) => _body('', status: 404),
        _api: (_) => _failureBody(403),
      });

      await expectLater(
        service.latest(environment: const {}),
        _failure(UpdateCheckFailure.rateLimited),
      );
    });

    test('a refused token is reported as unauthorized', () async {
      final (service, _) = _serviceWith({
        _cdn: (_) => _body('', status: 404),
        _raw: (_) => _body('', status: 404),
        _api: (_) => _failureBody(401),
      });

      await expectLater(
        service.latest(manualToken: 'secret', environment: const {}),
        _failure(UpdateCheckFailure.unauthorized),
      );
    });

    test('an unreachable network is a network failure', () async {
      ResponseBody timeout(RequestOptions request) => throw DioException(
        requestOptions: request,
        type: DioExceptionType.connectionTimeout,
      );
      final service = _serviceWith({
        _cdn: timeout,
        _raw: timeout,
        _api: timeout,
      }).$1;

      await expectLater(service.latest(environment: const {}), _failure(UpdateCheckFailure.network));
    });

    test('an empty release page is a server failure', () async {
      final (service, _) = _serviceWith({
        _cdn: (_) => _body('', status: 404),
        _raw: (_) => _body('', status: 404),
        _api: (_) => _body(jsonEncode(const {'message': 'ok'})),
      });

      await expectLater(
        service.latest(environment: const {}),
        _failure(UpdateCheckFailure.server),
      );
    });

    test('no release anywhere is an answer and is cached', () async {
      final (service, adapter) = _serviceWith({
        _cdn: (_) => _body('', status: 404),
        _raw: (_) => _body('', status: 404),
        _api: (_) => _body('', status: 404),
      });

      expect(await service.latest(environment: const {}), isNull);
      expect(await service.latest(environment: const {}), isNull);

      expect(adapter.requests.where((request) => request.uri.host == _api).length, 1);
    });

    test('a failed check is not cached', () async {
      final (service, adapter) = _serviceWith({
        _cdn: (_) => _body('', status: 404),
        _raw: (_) => _body('', status: 404),
        _api: (_) => _failureBody(403),
      });

      await expectLater(service.latest(environment: const {}), _failure(UpdateCheckFailure.rateLimited));
      await expectLater(service.latest(environment: const {}), _failure(UpdateCheckFailure.rateLimited));

      expect(adapter.requests.where((request) => request.uri.host == _api).length, 2);
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

    test('offline and translation archives are not platform updates', () {
      final asset = UpdateService.assetFor(const [
        UpdateAsset(
          name: 'tune-linux-x64-1.0.0-offline.tar.gz',
          url: 'https://example.com/offline.tar.gz',
        ),
        UpdateAsset(
          name: 'tune-translation-qwen2.5-0.5b-b12274.zip',
          url: 'https://example.com/translation.zip',
        ),
      ], platform: 'linux');

      expect(asset, isNull);
    });

    test('an answer without a version is no release', () {
      expect(UpdateService.parseRelease(null), isNull);
      expect(UpdateService.parseRelease({'tag_name': ''}), isNull);
    });
  });

  group('source logging', () {
    test('every address reports its host and result', () async {
      final lines = <String>[];
      final adapter = _RoutingAdapter({
        _cdn: (_) => _body('', status: 404),
        _raw: (_) => _body(jsonEncode(_manifest())),
      });
      final dio = Dio()..httpClientAdapter = adapter;
      final source = VersionManifestSource(dio: dio);

      // The lines the app itself writes, not a copy collected by a hook.
      final manifest = await runZoned(
        source.read,
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => lines.add(line),
        ),
      );

      expect(manifest?.version, '1.33.0');
      expect(lines, hasLength(2));
      expect(lines.first, contains(_cdn));
      expect(lines.first, contains('404'));
      expect(lines.last, contains(_raw));
      expect(lines.last, contains('命中 1.33.0+53'));
      expect(lines.last, contains('ms'));
    });
  });

  group('download check', () {
    test('the archive that matches its list is accepted', () async {
      final directory = await Directory.systemTemp.createTemp('tune-update');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/a.tar.gz')..writeAsStringSync('bytes');
      final asset = UpdateAsset(
        name: 'a.tar.gz',
        url: 'https://example.com/a.tar.gz',
        size: file.lengthSync(),
        sha256: sha256.convert(utf8.encode('bytes')).toString(),
      );

      await UpdateService.verifyArchive(asset, file.path);
    });

    test('a wrong size or digest is refused and the file removed', () async {
      final directory = await Directory.systemTemp.createTemp('tune-update');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/a.tar.gz')..writeAsStringSync('bytes');

      await expectLater(
        UpdateService.verifyArchive(
          UpdateAsset(name: 'a.tar.gz', url: 'https://example.com/a', size: 99, sha256: 'f' * 64),
          file.path,
        ),
        _failure(UpdateCheckFailure.archiveMismatch),
      );
      await expectLater(
        UpdateService.verifyArchive(
          UpdateAsset(name: 'a.tar.gz', url: 'https://example.com/a', size: 5, sha256: 'f' * 64),
          file.path,
        ),
        _failure(UpdateCheckFailure.archiveMismatch),
      );
    });

    test('a download that does not match deletes what it wrote', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        request.response
          ..statusCode = 200
          ..add(utf8.encode('bytes'));
        await request.response.close();
      });
      final directory = await Directory.systemTemp.createTemp('tune-update');
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}/a.tar.gz';

      await expectLater(
        UpdateService().download(
          UpdateAsset(
            name: 'a.tar.gz',
            url: 'http://127.0.0.1:${server.port}/a.tar.gz',
            size: 5,
            sha256: 'f' * 64,
          ),
          path,
        ),
        _failure(UpdateCheckFailure.archiveMismatch),
      );

      expect(File(path).existsSync(), isFalse);
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
