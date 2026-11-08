import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/openverse_source.dart';
import 'package:tune/domain/models/music_source.dart';

/// Openverse audio comes from several catalogues at once.
///
/// The catalogue filter is one parameter of the service, and the service
/// ignores a name it does not know: an unknown name must not be sent, or the
/// answer would silently be the unfiltered list.
void main() {
  group('Openverse source', () {
    test('a catalogue narrows the answer', () async {
      final answers = _OpenverseAnswers();

      await OpenverseSourceAdapter(
        dio: answers.dio,
      ).scan(_request(const {'source': 'jamendo'}));

      expect(answers.uris.single.queryParameters['source'], 'jamendo');
    });

    test('an unknown catalogue is not sent', () async {
      final answers = _OpenverseAnswers();

      await OpenverseSourceAdapter(
        dio: answers.dio,
      ).scan(_request(const {'source': 'ccmixter'}));

      // The service would ignore the name and answer with everything; the
      // request is left out instead of pretending to filter.
      expect(answers.uris.single.queryParameters.containsKey('source'), isFalse);
    });

    test('every catalogue asks for no filter', () async {
      final answers = _OpenverseAnswers();

      await OpenverseSourceAdapter(dio: answers.dio).scan(_request(const {}));

      expect(answers.uris.single.queryParameters.containsKey('source'), isFalse);
    });

    test('a keyword and a catalogue narrow together', () async {
      final answers = _OpenverseAnswers();

      await OpenverseSourceAdapter(
        dio: answers.dio,
      ).scan(_request(const {'query': 'piano', 'source': 'freesound'}));

      final uri = answers.uris.single;
      expect(uri.queryParameters['q'], 'piano');
      expect(uri.queryParameters['source'], 'freesound');
    });
  });
}

MusicSourceScanRequest _request(Map<String, String> settings) {
  return MusicSourceScanRequest(
    config: MusicSourceConfig(
      id: 'openverse',
      type: 'openverse',
      name: 'openverse',
      kind: MusicSourceKind.openCatalog,
      settings: settings,
    ),
  );
}

/// Answers every request with one song and remembers what was asked.
class _OpenverseAnswers {
  final uris = <Uri>[];

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          uris.add(options.uri);
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'results': [
                  {
                    'id': 'one',
                    'title': 'One',
                    'url': 'https://files.example.com/one.mp3',
                    'creator': 'Someone',
                    'duration': 180000,
                  },
                ],
              },
              statusCode: 200,
            ),
          );
        },
      ),
    );
    return client;
  }
}
