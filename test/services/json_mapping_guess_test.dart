import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/json_mapping_guess.dart';
import 'package:tune/data/services/music_sources/json_source_mapping.dart';

/// The app reads the paths off the answer itself.
///
/// The reader writes the paths by hand today; a guess saves the typing, and
/// the reader corrects what the guess got wrong.
void main() {
  group('the list of the tracks', () {
    test('a list at the top of the answer is the list', () {
      final guess = guessJsonMapping([
        {'title': 'Night Drive'},
      ]);

      expect(guess.listPath, '');
    });

    test('a list under a known name is found', () {
      final guess = guessJsonMapping({
        'data': {
          'songs': [
            {'title': 'Night Drive'},
          ],
        },
      });

      expect(guess.listPath, 'data.songs');
    });

    test('a list under any name is found', () {
      final guess = guessJsonMapping({
        'payload': {
          'whatever': [
            {'title': 'Night Drive'},
          ],
        },
      });

      expect(guess.listPath, 'payload.whatever');
    });

    test('a list that holds no objects is not the list of the tracks', () {
      final guess = guessJsonMapping({
        'tags': ['one', 'two'],
        'songs': [
          {'title': 'Night Drive'},
        ],
      });

      expect(guess.listPath, 'songs');
    });
  });

  group('the fields of a track', () {
    test('the usual names are recognised', () {
      final guess = guessJsonMapping({
        'results': [
          {
            'id': '7',
            'title': 'Night Drive',
            'artist': 'Nova',
            'album': 'City',
            'cover': 'https://example.com/c.jpg',
            'url': 'https://example.com/1.mp3',
            'duration': 210,
            'genre': 'synth',
          },
        ],
      });

      expect(guess.idPath, 'id');
      expect(guess.titlePath, 'title');
      expect(guess.artistPath, 'artist');
      expect(guess.albumPath, 'album');
      expect(guess.coverPath, 'cover');
      expect(guess.urlPath, 'url');
      expect(guess.durationPath, 'duration');
      expect(guess.genrePath, 'genre');
    });

    test('a name in another spelling is recognised', () {
      final guess = guessJsonMapping({
        'tracks': [
          {
            'track_name': 'Night Drive',
            'stream_url': 'https://example.com/1.mp3',
          },
        ],
      });

      expect(guess.titlePath, 'track_name');
      expect(guess.urlPath, 'stream_url');
    });

    test('a name inside a name is read as a path', () {
      final guess = guessJsonMapping({
        'tracks': [
          {
            'title': 'Night Drive',
            'artist': {'name': 'Nova'},
          },
        ],
      });

      expect(guess.artistPath, 'artist.name');
    });

    test('an address is found by what it looks like', () {
      final guess = guessJsonMapping({
        'tracks': [
          {
            'title': 'Night Drive',
            'preview_url': 'https://example.com/1.mp3',
          },
        ],
      });

      expect(guess.urlPath, 'preview_url');
    });

    test('a cover is not taken for the address', () {
      final guess = guessJsonMapping({
        'tracks': [
          {
            'title': 'Night Drive',
            'cover_url': 'https://example.com/c.jpg',
            'audio': 'https://example.com/1.mp3',
          },
        ],
      });

      expect(guess.coverPath, 'cover_url');
      expect(guess.urlPath, 'audio');
    });

    test('a length in milliseconds is left to the reader', () {
      final guess = guessJsonMapping({
        'tracks': [
          {
            'title': 'Night Drive',
            'duration_ms': 210000,
          },
        ],
      });

      expect(guess.durationPath, '');
    });
  });

  group('what the reader wrote', () {
    test('a path of the reader is kept', () {
      final guess = guessJsonMapping(
        {
          'results': [
            {'title': 'Night Drive', 'url': 'https://example.com/1.mp3'},
          ],
        },
        current: const JsonSourceMapping(titlePath: 'my_title'),
      );

      expect(guess.titlePath, 'my_title');
    });

    test('the list the reader named is kept', () {
      final guess = guessJsonMapping(
        {
          'results': [
            {'title': 'Night Drive'},
          ],
        },
        current: const JsonSourceMapping(listPath: 'my_list'),
      );

      expect(guess.listPath, 'my_list');
    });
  });

  group('the suggestions', () {
    test('only the paths that are still empty are suggested', () {
      const current = JsonSourceMapping(titlePath: 'my_title');
      final guessed = guessJsonMapping(
        {
          'results': [
            {'title': 'Night Drive', 'url': 'https://example.com/1.mp3'},
          ],
        },
        current: current,
      );

      final suggestions = jsonPathSuggestions(
        current: current,
        guessed: guessed,
      );

      expect(suggestions.containsKey('titlePath'), isFalse);
      expect(suggestions['listPath'], 'results');
      expect(suggestions['urlPath'], 'url');
    });
  });

  group('an answer the guess does not know', () {
    test('nothing is suggested and nothing is thrown', () {
      final guess = guessJsonMapping('not an answer at all');

      expect(guess.listPath, '');
      expect(guess.titlePath, '');
      expect(guess.urlPath, '');
    });
  });
}
