import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/lms_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// A Logitech Media Server answers the Squeezebox command line over JSON-RPC.
///
/// The command names the window of the library and the keyword, and the
/// answer lists the tracks. The tests answer the call the way the server does
/// and look at what the adapter read from it.
void main() {
  group('LMS source', () {
    test('the library is read as tracks', () async {
      final answers = _LmsAnswers();
      final result = await LmsSourceAdapter(dio: answers.dio).scan(
        _request(const {'server': 'http://192.168.1.10:9000'}),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(2));

      final first = result.songs.first;
      expect(first.title, 'So What');
      expect(first.artist, 'Miles Davis');
      expect(first.album, 'Kind of Blue');
      // The command answers seconds; the library keeps milliseconds.
      expect(first.duration, 545400);
      expect(
        first.streamUrl,
        'http://192.168.1.10:9000/music/12/download',
      );
    });

    test('a keyword searches the whole library', () async {
      final answers = _LmsAnswers();
      await LmsSourceAdapter(dio: answers.dio).scan(
        _request(const {
          'server': 'http://192.168.1.10:9000',
          'query': 'miles davis',
        }),
      );

      final command = answers.commands.single;
      expect(command, contains('search:miles davis'));
      // The fields are asked for with the tracks, or the answer names none.
      expect(command, contains(startsWith('tags:')));
    });

    test('a later window asks for the tracks after the first ones', () async {
      final answers = _LmsAnswers();
      await LmsSourceAdapter(dio: answers.dio).scan(
        MusicSourceScanRequest(
          config: _config(const {'server': 'http://192.168.1.10:9000'}),
          offset: 40,
        ),
      );

      final command = answers.commands.single;
      expect(command[1], '40');
      expect(command[2], '20');
    });

    test('an account rides along as a basic header', () async {
      final answers = _LmsAnswers();
      final result = await LmsSourceAdapter(dio: answers.dio).scan(
        _request(const {
          'server': 'http://192.168.1.10:9000',
          'user': 'listener',
          'password': 'secret',
        }),
      );

      expect(answers.headers.single?['Authorization'], startsWith('Basic '));
      expect(
        result.songs.first.httpHeaders?['Authorization'],
        startsWith('Basic '),
      );
    });

    test('a source without a server asks for its settings', () async {
      final answers = _LmsAnswers();
      final result = await LmsSourceAdapter(dio: answers.dio).scan(
        _request(const {'server': ''}),
      );

      expect(result.status, SourceScanStatus.needsConfiguration);
      expect(answers.commands, isEmpty);
    });

    test('an answer without a list is reported as unreadable', () async {
      final answers = _LmsAnswers(loop: false);
      final result = await LmsSourceAdapter(dio: answers.dio).scan(
        _request(const {'server': 'http://192.168.1.10:9000'}),
      );

      expect(result.status, SourceScanStatus.failed);
      expect(result.songs, isEmpty);
    });
  });
}

MusicSourceScanRequest _request(Map<String, String> settings) {
  return MusicSourceScanRequest(config: _config(settings));
}

MusicSourceConfig _config(Map<String, String> settings) {
  return MusicSourceConfig(
    id: 'lms',
    type: 'lms',
    name: 'lms',
    kind: MusicSourceKind.openApi,
    settings: settings,
  );
}

/// Answers the command line with two tracks.
class _LmsAnswers {
  _LmsAnswers({this.loop = true});

  /// Whether the answer carries a list of tracks.
  final bool loop;
  final commands = <List<dynamic>>[];
  final headers = <Map<String, dynamic>?>[];

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final body = jsonDecode(options.data as String) as Map;
          final params = body['params'] as List;
          commands.add((params[1] as List).cast<dynamic>());
          headers.add(options.headers);
          handler.resolve(
            Response(
              requestOptions: options,
              data: jsonEncode({
                'id': 1,
                'method': 'slim.request',
                'result': {
                  if (loop)
                    'titles_loop': [
                      {
                        'id': '12',
                        'title': 'So What',
                        'artist': 'Miles Davis',
                        'album': 'Kind of Blue',
                        'duration': '545.4',
                      },
                      {
                        'id': '13',
                        'title': 'Blue in Green',
                        'artist': 'Miles Davis',
                        'album': 'Kind of Blue',
                        'duration': 331,
                      },
                    ],
                },
              }),
              statusCode: 200,
            ),
          );
        },
      ),
    );
    return client;
  }
}
