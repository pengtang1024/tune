import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/audiobookshelf_source.dart';
import 'package:tune/data/services/music_sources/funkwhale_source.dart';

/// Two services that need a server before they answer.
///
/// The tests below read the answers they give: what a track of Funkwhale
/// becomes, and how the chapters of one audiobook are read.
void main() {
  group('Funkwhale adapter', () {
    test('maps the tracks of an instance', () {
      final songs = FunkwhaleSourceAdapter.parseResults(
        _funkwhaleAnswer(),
        sourceId: 'funkwhale',
        server: 'https://fw.example',
      );

      expect(songs, hasLength(1));
      final song = songs.single;
      expect(song.title, 'Night Drive');
      expect(song.artist, 'The Artist');
      expect(song.album, 'The Album');
      expect(song.duration, 213000);
      expect(song.artworkUrl, 'https://fw.example/media/cover-large.jpg');
      expect(song.streamUrl, 'https://fw.example/api/v1/listen/upload-1/');
      expect(song.externalId, '1');
    });

    test('a relative listen address is read on the server', () {
      final answer = _funkwhaleAnswer();
      final track = (answer['results'] as List).first as Map<String, dynamic>;
      track['listen_url'] = '/api/v1/listen/upload-1/';
      track.remove('uploads');

      final song = FunkwhaleSourceAdapter.parseResults(
        answer,
        sourceId: 'funkwhale',
        server: 'https://fw.example',
      ).single;

      expect(song.streamUrl, 'https://fw.example/api/v1/listen/upload-1/');
    });
  });

  group('Audiobookshelf adapter', () {
    test('maps the chapters of one audiobook', () {
      final songs = AudiobookshelfSourceAdapter.parseBooks(
        _audiobookshelfAnswer(),
        sourceId: 'audiobookshelf',
        server: 'http://abs.example',
        token: 'token',
        limit: 8,
      );

      expect(songs, hasLength(2));
      final first = songs.first;
      expect(first.title, 'Chapter One');
      expect(first.artist, 'Charles Dickens');
      expect(first.album, 'Bleak House');
      expect(first.duration, 900000);
      expect(first.trackNumber, 1);
      expect(first.trackTotal, 2);
      expect(
        first.streamUrl,
        'http://abs.example/api/items/book-1/file/0?token=token',
      );
      expect(
        first.artworkUrl,
        'http://abs.example/api/items/book-1/cover?token=token',
      );
    });

    test('a book without tracks is not kept', () {
      final answer = _audiobookshelfAnswer();
      final book = (answer['results'] as List).first as Map<String, dynamic>;
      (book['media'] as Map<String, dynamic>).remove('tracks');

      expect(
        AudiobookshelfSourceAdapter.parseBooks(
          answer,
          sourceId: 'audiobookshelf',
          server: 'http://abs.example',
          token: 'token',
        ),
        isEmpty,
      );
    });
  });
}

Map<String, dynamic> _funkwhaleAnswer() => {
  'results': [
    {
      'id': 1,
      'title': 'Night Drive',
      'duration': 213,
      'artist': {'name': 'The Artist'},
      'album': {
        'title': 'The Album',
        'cover': {
          'urls': {
            'large': 'https://fw.example/media/cover-large.jpg',
            'medium': 'https://fw.example/media/cover-medium.jpg',
          },
        },
      },
      'uploads': [
        {'listen_url': 'https://fw.example/api/v1/listen/upload-1/'},
      ],
    },
  ],
};

Map<String, dynamic> _audiobookshelfAnswer() => {
  'results': [
    {
      'id': 'book-1',
      'media': {
        'metadata': {'title': 'Bleak House', 'authorName': 'Charles Dickens'},
        'tracks': [
          {
            'index': 0,
            'duration': 900,
            'contentUrl': '/api/items/book-1/file/0',
            'title': 'Chapter One',
          },
          {
            'index': 1,
            'duration': 1200,
            'contentUrl': '/api/items/book-1/file/1',
            'title': 'Chapter Two',
          },
        ],
      },
    },
  ],
};
