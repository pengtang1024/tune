import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/domain/library_collection.dart';

void main() {
  test('the tracks of an instance become one collection', () {
    const songs = [
      Song(
        id: 1,
        title: 'Tabla Loop 4',
        album: 'Tabla Loops for Music Composition',
        uri: 'tune://archive/loop-4',
        sourceId: 'community_classical',
      ),
      Song(
        id: 2,
        title: 'Theme',
        album: 'Enigma Variations',
        uri: 'tune://archive/elgar-1',
        sourceId: 'community_classical',
        albumArtPath: '/music/elgar.jpg',
      ),
      Song(
        id: 3,
        title: 'Mine',
        uri: '/music/mine.mp3',
      ),
    ];

    final collections = libraryCollectionsOf(songs, const {
      'community_classical': SourceLabel(
        name: 'community_classical',
        localizedName: '社区古典',
      ),
      'local': SourceLabel(
        name: 'local',
        localizedName: '本地音乐',
        kind: MusicSourceKind.localDirectory,
      ),
    });

    expect(collections.map((collection) => collection.sourceId), [
      'community_classical',
      'local',
    ]);
    final classical = collections.first;
    expect(classical.name, '社区古典');
    expect(classical.trackCount, 2);
    expect(classical.itemCount, 2);
    expect(classical.artPath, '/music/elgar.jpg');
    expect(collections.last.name, '本地音乐');
    expect(collections.last.itemCount, 1);
  });

  test('a collection keeps the tracks of an instance that is gone', () {
    const songs = [
      Song(
        id: 1,
        title: 'Left behind',
        album: 'Record',
        uri: '/music/left.mp3',
        sourceId: 'deleted_instance',
      ),
    ];

    final collections = libraryCollectionsOf(songs, const {});

    expect(collections, hasLength(1));
    expect(collections.single.name, 'deleted_instance');
  });

  test('the largest collection comes first, then the name decides', () {
    const songs = [
      Song(id: 1, title: 'A', album: 'R1', uri: '/a.mp3', sourceId: 'small'),
      Song(id: 2, title: 'B', album: 'R2', uri: '/b.mp3', sourceId: 'big'),
      Song(id: 3, title: 'C', album: 'R3', uri: '/c.mp3', sourceId: 'big'),
      Song(id: 4, title: 'D', album: 'R4', uri: '/d.mp3', sourceId: 'zed'),
    ];

    final collections = libraryCollectionsOf(songs, const {});

    expect(collections.map((collection) => collection.sourceId), [
      'big',
      'small',
      'zed',
    ]);
  });

  test('an album-less track is an item of its own', () {
    const songs = [
      Song(id: 1, title: 'One', uri: '/1.mp3', sourceId: 'radio'),
      Song(id: 2, title: 'Two', uri: '/2.mp3', sourceId: 'radio'),
    ];

    final collections = libraryCollectionsOf(songs, const {});

    expect(collections.single.itemCount, 2);
  });
}
