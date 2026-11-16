import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/update/update_check_exception.dart';
import 'package:tune/data/services/update/version_manifest_cache.dart';
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

/// A source over [root] that behaves like a new process: its cache reads the
/// directory but keeps nothing from the previous instance.
VersionManifestSource _source(Dio dio, Directory root) {
  return VersionManifestSource(
    dio: dio,
    cache: VersionManifestCache(supportDirectory: () async => root),
  );
}

String? _validator(RequestOptions request) {
  final value = request.headers['If-None-Match'];
  return value?.toString();
}

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tune_manifest_cache');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('a restart still sends the validator of the last answer', () async {
    final first = _RoutingAdapter({
      _cdn: (_) => _body(
        jsonEncode(_manifest()),
        headers: {
          'etag': ['W/"cdn-1"'],
        },
      ),
      _raw: (_) => _body(
        jsonEncode(_manifest()),
        headers: {
          'etag': ['W/"raw-1"'],
        },
      ),
    });
    final firstSource = _source(Dio()..httpClientAdapter = first, root);
    expect((await firstSource.read())?.version, '1.33.0');
    expect(first.requests.every((it) => _validator(it) == null), isTrue);

    // A new process: the cache file is all that survives.
    final second = _RoutingAdapter({
      _cdn: (_) => _body('', status: 304),
      _raw: (_) => _body('', status: 304),
    });
    final secondSource = _source(Dio()..httpClientAdapter = second, root);
    final manifest = await secondSource.read();

    // Keyed by host: the order of the addresses is a policy, not a contract.
    final validators = {
      for (final request in second.requests)
        request.uri.host: request.headers['If-None-Match'],
    };
    expect(validators[_cdn], 'W/"cdn-1"');
    expect(validators[_raw], 'W/"raw-1"');
    // Both answered 304: the parsed lists from the file are the answer.
    expect(manifest?.version, '1.33.0');
  });

  test('the two sources never borrow each other validator', () async {
    final first = _RoutingAdapter({
      _cdn: (_) => _body(
        jsonEncode(_manifest()),
        headers: {
          'etag': ['W/"cdn-1"'],
        },
      ),
      _raw: (_) => _body(
        jsonEncode(_manifest()),
        headers: {
          'etag': ['W/"raw-1"'],
        },
      ),
    });
    await _source(Dio()..httpClientAdapter = first, root).read();

    final second = _RoutingAdapter({
      _cdn: (_) => _body('', status: 304),
      _raw: (_) => _body('', status: 304),
    });
    await _source(Dio()..httpClientAdapter = second, root).read();

    final byHost = {
      for (final request in second.requests)
        request.uri.host: _validator(request),
    };
    expect(byHost[_cdn], 'W/"cdn-1"');
    expect(byHost[_raw], 'W/"raw-1"');
  });

  test('a 304 and a newer 200 take the newer list', () async {
    final first = _RoutingAdapter({
      _cdn: (_) => _body(
        jsonEncode(_manifest()),
        headers: {
          'etag': ['W/"cdn-1"'],
        },
      ),
      _raw: (_) => _body(
        jsonEncode(_manifest()),
        headers: {
          'etag': ['W/"raw-1"'],
        },
      ),
    });
    await _source(Dio()..httpClientAdapter = first, root).read();

    // The CDN edge still serves the previous release while the raw host is
    // already new. That is the ordinary shape of a fresh release, not a
    // disagreement to refuse: the newer list is the answer.
    final second = _RoutingAdapter({
      _cdn: (_) => _body('', status: 304),
      _raw: (_) => _body(
        jsonEncode(_manifest(version: '1.34.0', build: 54)),
        headers: {
          'etag': ['W/"raw-2"'],
        },
      ),
    });

    final manifest = await _source(Dio()..httpClientAdapter = second, root).read();
    expect(manifest?.version, '1.34.0');
    expect(manifest?.build, 54);
  });

  test('one build with two different archives is still refused', () async {
    final first = _RoutingAdapter({
      _cdn: (_) => _body(
        jsonEncode(_manifest()),
        headers: {
          'etag': ['W/"cdn-1"'],
        },
      ),
      _raw: (_) => _body(
        jsonEncode(_manifest()),
        headers: {
          'etag': ['W/"raw-1"'],
        },
      ),
    });
    await _source(Dio()..httpClientAdapter = first, root).read();

    // Same version and build, another digest: a truncated upload or a file
    // swapped on the way. There is no newer list to prefer.
    final second = _RoutingAdapter({
      _cdn: (_) => _body(
        jsonEncode(_manifest()),
        headers: {
          'etag': ['W/"cdn-1"'],
        },
      ),
      _raw: (_) => _body(
        jsonEncode(_manifest(sha: 'f' * 64)),
        headers: {
          'etag': ['W/"raw-2"'],
        },
      ),
    });

    await expectLater(
      _source(Dio()..httpClientAdapter = second, root).read(),
      throwsA(
        isA<UpdateCheckException>().having(
          (error) => error.failure,
          'failure',
          UpdateCheckFailure.manifestMismatch,
        ),
      ),
    );
  });

  test('a corrupt cache file falls back to an unconditional request', () async {
    final file = File('${root.path}/update/version_manifest_cache.json');
    await file.parent.create(recursive: true);
    await file.writeAsString('{not json');

    final adapter = _RoutingAdapter({
      _cdn: (_) => _body(
        jsonEncode(_manifest()),
        headers: {
          'etag': ['W/"cdn-1"'],
        },
      ),
      _raw: (_) => _body(
        jsonEncode(_manifest()),
        headers: {
          'etag': ['W/"raw-1"'],
        },
      ),
    });
    final manifest = await _source(
      Dio()..httpClientAdapter = adapter,
      root,
    ).read();

    expect(manifest?.version, '1.33.0');
    expect(adapter.requests.every((it) => _validator(it) == null), isTrue);
  });

  test('a cache of another schema is dropped, not loaded', () async {
    final file = File('${root.path}/update/version_manifest_cache.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'schema': VersionManifestCache.schema + 1,
        'entries': {
          'https://cdn.jsdelivr.net/gh/pengtang1024/tune@master/version.json':
              {
                'url':
                    'https://cdn.jsdelivr.net/gh/pengtang1024/tune@master/version.json',
                'etag': 'W/"cdn-1"',
                'manifest': _manifest(),
              },
        },
      }),
    );

    final adapter = _RoutingAdapter({
      _cdn: (_) => _body(
        jsonEncode(_manifest()),
        headers: {
          'etag': ['W/"cdn-1"'],
        },
      ),
      _raw: (_) => _body(jsonEncode(_manifest())),
    });
    await _source(Dio()..httpClientAdapter = adapter, root).read();

    expect(adapter.requests.every((it) => _validator(it) == null), isTrue);
  });
}
