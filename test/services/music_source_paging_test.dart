import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/audius_source.dart';
import 'package:tune/data/services/music_sources/internet_archive_source.dart';
import 'package:tune/data/services/music_sources/librivox_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/openverse_source.dart';
import 'package:tune/domain/models/music_source.dart';

/// A source that serves its list in pages answers a later offset with the
/// next window, so the search panel can ask for more without repeating.
void main() {
  group('paging', () {
    test('Openverse asks for the page that holds the offset', () async {
      final captured = _Captured(body: {'results': <dynamic>[]});

      await OpenverseSourceAdapter(
        dio: captured.dio,
      ).scan(_request('openverse', offset: 20));

      expect(captured.uri?.queryParameters['page'], '2');
      expect(captured.uri?.queryParameters['page_size'], '20');
    });

    test('Audius passes the offset through', () async {
      final captured = _Captured(body: {'data': <dynamic>[]});

      await AudiusSourceAdapter(
        dio: captured.dio,
      ).scan(_request('audius', offset: 40));

      expect(captured.uri?.queryParameters['offset'], '40');
    });

    test('the Internet Archive asks for the page of the offset', () async {
      final captured = _Captured(
        body: {
          'response': {'docs': <dynamic>[]},
        },
      );

      await InternetArchiveSourceAdapter(
        dio: captured.dio,
      ).scan(_request('internet_archive', offset: 8));

      expect(captured.uri?.queryParameters['page'], '2');
    });

    test('LibriVox passes the offset to the catalogue', () async {
      final captured = _Captured(body: {'books': <dynamic>[]});

      await LibrivoxSourceAdapter(
        dio: captured.dio,
      ).scan(_request('librivox', offset: 8, settings: {'query': 'jazz'}));

      expect(captured.uris.first.queryParameters['offset'], '8');
    });

    test('a source without pages says so', () {
      expect(OpenverseSourceAdapter().supportsPaging, isTrue);
      expect(AudiusSourceAdapter().supportsPaging, isTrue);
      expect(InternetArchiveSourceAdapter().supportsPaging, isTrue);
      expect(LibrivoxSourceAdapter().supportsPaging, isTrue);
    });
  });
}

/// One scan of a source.
MusicSourceScanRequest _request(
  String id, {
  int offset = 0,
  Map<String, String> settings = const {},
}) {
  return MusicSourceScanRequest(
    config: MusicSourceConfig(
      id: id,
      type: id,
      name: id,
      kind: MusicSourceKind.openCatalog,
      settings: settings,
    ),
    offset: offset,
  );
}

/// A Dio that answers every request with one body and keeps the requests.
class _Captured {
  _Captured({required Object body}) : _body = body;

  final Object _body;
  final uris = <Uri>[];

  Uri? get uri => uris.isEmpty ? null : uris.last;

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          uris.add(options.uri);
          handler.resolve(
            Response(requestOptions: options, data: _body, statusCode: 200),
          );
        },
      ),
    );
    return client;
  }
}
