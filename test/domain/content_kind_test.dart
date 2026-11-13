import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/domain/models/song.dart';

void main() {
  test('podcast feeds publish shows', () {
    expect(isPodcastSource('podcast_rss'), isTrue);
    expect(isPodcastSource('podcast_catalog-2'), isTrue);
    expect(isPodcastSource('podcast_apple'), isTrue);
    expect(isPodcastSource('librivox'), isFalse);
    expect(isPodcastSource('local'), isFalse);
    expect(isPodcastSource(null), isFalse);
  });

  test('audiobook sources publish books', () {
    expect(isAudiobookSource('librivox'), isTrue);
    expect(isAudiobookSource('audiobookshelf-1'), isTrue);
    expect(isAudiobookSource('podcast_rss'), isFalse);
    expect(isAudiobookSource('local'), isFalse);
    expect(isAudiobookSource(null), isFalse);
  });

  test('a station wins over the source it comes from', () {
    const station = Song(
      id: 1,
      uri: 'tune://radio/one',
      sourceId: 'podcast_rss',
      isLiveStream: true,
    );

    expect(contentKindOf(station), ContentKind.radio);
  });

  test('a podcast episode and an audiobook chapter are speech', () {
    expect(
      contentKindOf(
        const Song(id: 2, uri: 'tune://podcast_rss/1', sourceId: 'podcast_rss-2'),
      ),
      ContentKind.podcast,
    );
    expect(
      contentKindOf(
        const Song(id: 3, uri: 'tune://librivox/1', sourceId: 'librivox'),
      ),
      ContentKind.audiobook,
    );
    expect(ContentKind.podcast.isSpokenWord, isTrue);
    expect(ContentKind.audiobook.isSpokenWord, isTrue);
    expect(ContentKind.music.isSpokenWord, isFalse);
    expect(ContentKind.radio.isSpokenWord, isFalse);
  });

  test('a row is classified from its source and live flag', () {
    expect(
      contentKindOfSource(sourceId: 'podcast_catalog-3'),
      ContentKind.podcast,
    );
    expect(contentKindOfSource(sourceId: 'librivox'), ContentKind.audiobook);
    expect(
      contentKindOfSource(sourceId: 'podcast_rss-3', isLiveStream: true),
      ContentKind.radio,
    );
    expect(contentKindOfSource(sourceId: null), ContentKind.music);
  });

  test('a local file is music', () {
    expect(
      contentKindOf(const Song(id: 4, uri: '/music/one.flac', sourceId: 'local')),
      ContentKind.music,
    );
  });

  test('a book on this machine is read from its tag, container or folder', () {
    ContentKind kindOf(String path, {String? genre}) => localContentKindOf(
      path: path,
      genre: genre,
    );

    expect(kindOf('/books/one.m4b'), ContentKind.audiobook);
    expect(kindOf('/books/one.mp3', genre: '有声书'), ContentKind.audiobook);
    expect(kindOf('/books/one.mp3', genre: 'Podcast; Audiobook'), ContentKind.audiobook);
    expect(kindOf('/Music/audiobooks/one.mp3'), ContentKind.audiobook);
    expect(kindOf('/Music/听书/one.mp3'), ContentKind.audiobook);
    expect(kindOf('/Music/podcasts/one.mp3'), ContentKind.podcast);
    expect(kindOf('/Music/播客/one.mp3'), ContentKind.podcast);
    expect(kindOf('/Music/one.mp3', genre: 'Jazz'), ContentKind.music);
    expect(kindOf('/Music/albums/one.flac'), ContentKind.music);
  });

  test('a book folder beats a podcast folder below it', () {
    expect(
      localContentKindOf(path: '/Music/audiobooks/podcasts/one.mp3'),
      ContentKind.audiobook,
    );
  });

  test('a built-in instance declares the kind its adapter cannot tell', () {
    expect(contentKindOfSource(sourceId: 'archive_podcasts'), ContentKind.podcast);
    expect(
      contentKindOfSource(sourceId: 'independent_audiobooks'),
      ContentKind.audiobook,
    );
    expect(contentKindOfSource(sourceId: 'old_time_radio'), ContentKind.radio);
    expect(contentKindOfSource(sourceId: 'radio_recordings'), ContentKind.radio);
    expect(contentKindOfSource(sourceId: 'foreign_audio'), ContentKind.music);
  });

  test('a recording of a station is a station, not a live stream', () {
    const recording = Song(
      id: 5,
      uri: 'tune://internet_archive/old-time-radio/1',
      sourceId: 'radio_recordings',
    );

    expect(contentKindOf(recording), ContentKind.radio);
    expect(recording.isLiveStream, isFalse);
  });
}
