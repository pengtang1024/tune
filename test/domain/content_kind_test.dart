import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/content_row.dart';

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
    expect(
      contentKindOfSource(sourceId: 'foreign_audio'),
      ContentKind.audiobook,
    );
  });

  test('a chapter of a foreign book is an audiobook', () {
    const chapter = Song(
      id: 6,
      uri: 'tune://internet_archive/foreign_audio/1',
      sourceId: 'foreign_audio',
      title: "Emile Zola - L'Assommoir - Chapitre10",
      album: "L'Assommoir",
    );

    expect(contentKindOf(chapter), ContentKind.audiobook);
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

  test('a sound effect is named by its genre, never by its length', () {
    const bark = Song(
      id: 7,
      uri: 'tune://internet_archive/unlocked_recordings/1',
      sourceId: 'unlocked_recordings',
      album: 'Sound Effects In Stereo',
      genre: 'Non-Music / Field Recording',
      duration: 4000,
    );
    expect(contentKindOf(bark), ContentKind.soundEffect);
    expect(ContentKind.soundEffect.isSpokenWord, isFalse);
    expect(rowShapeOf(bark), RowShape.soundEffect);

    const shortSong = Song(
      id: 8,
      uri: 'tune://internet_archive/unlocked_recordings/2',
      sourceId: 'unlocked_recordings',
      album: 'Tabla Loops',
      genre: 'Classical',
      duration: 2000,
    );
    expect(contentKindOf(shortSong), ContentKind.music);
  });

  test('an album exception refines an instance that declares nothing', () {
    expect(
      contentKindOfFields(
        sourceId: 'unlocked_recordings',
        album: 'Death of a salesman',
      ),
      ContentKind.audiobook,
    );
    expect(
      contentKindOfFields(
        sourceId: 'unlocked_recordings',
        album: '  death   of a SALESMAN ',
      ),
      ContentKind.audiobook,
    );
    expect(
      contentKindOfFields(
        sourceId: 'unlocked_recordings',
        album: 'For Men Only',
        genre: 'Jazz',
      ),
      ContentKind.music,
    );
    expect(
      contentKindOfFields(
        sourceId: 'another_instance',
        album: 'Death of a salesman',
      ),
      ContentKind.music,
    );
    // A world-music collection holds two books uploaded under their own
    // "Audiobook" item title while their genre tag still says World.
    expect(
      contentKindOfFields(
        sourceId: 'community_world',
        album: "Alice's Adventures In Wonderland Full Audiobook",
        genre: 'World',
      ),
      ContentKind.audiobook,
    );
    expect(
      contentKindOfFields(
        sourceId: 'community_world',
        album: 'Bali Gamelan',
        genre: 'World',
      ),
      ContentKind.music,
    );
  });

  test('a spoken genre refines a declared instance, a music genre never', () {
    expect(
      contentKindOfFields(
        sourceId: 'radio_recordings',
        album: 'American Stories',
        genre: 'Audiobook',
      ),
      ContentKind.audiobook,
    );
    expect(
      contentKindOfFields(
        sourceId: 'radio_recordings',
        album: 'American Stories',
        genre: 'Blues',
      ),
      ContentKind.radio,
    );
    expect(
      contentKindOfFields(
        sourceId: 'archive_podcasts',
        album: 'Some Show',
        genre: 'Podcast',
      ),
      ContentKind.podcast,
    );
    // A music genre may not outrank the instance either.
    expect(
      contentKindOfFields(
        sourceId: 'archive_podcasts',
        album: 'RelicRadio.com',
        genre: 'Gospel',
      ),
      ContentKind.radio,
    );
  });

  test('an album exception refines a declared instance too', () {
    expect(
      contentKindOfFields(
        sourceId: 'archive_podcasts',
        album: 'Sleep Safe & Calm Beat Insomnia. Peaceful Music For Deep Sleep. Delta Waves',
      ),
      ContentKind.music,
    );
    expect(
      contentKindOfFields(sourceId: 'archive_podcasts', album: 'pIANO'),
      ContentKind.music,
    );
    expect(
      contentKindOfFields(
        sourceId: 'archive_podcasts',
        album: 'RelicRadio.com',
      ),
      ContentKind.radio,
    );
    expect(
      contentKindOfFields(
        sourceId: 'archive_podcasts',
        album: 'The Howard Stern Show',
      ),
      ContentKind.podcast,
    );
  });

  test('a loop pack filed under a music collection is not a shelf', () {
    // A pack of one- to three-second tabla loops for composing was uploaded
    // into the classical collection; its genre tag says Classical, so the
    // album name is the only declaration that names what it is.
    expect(
      contentKindOfFields(
        sourceId: 'community_classical',
        album: 'Tabla Loops for Music Composition - 8 Beats Kaharwa Taal',
        genre: 'Classical',
      ),
      ContentKind.soundEffect,
    );
    expect(
      contentKindOfFields(
        sourceId: 'community_classical',
        album: '  tabla LOOPS for music composition - 8 beats kaharwa taal ',
        genre: 'Classical',
      ),
      ContentKind.soundEffect,
    );
    // The rest of that collection is music, artist or no artist.
    expect(
      contentKindOfFields(
        sourceId: 'community_classical',
        album: 'Edward ELGAR - Enigma Variations',
        genre: 'Classic Rock',
      ),
      ContentKind.music,
    );
  });

  test('a kind the item states for itself outranks every other rule', () {
    expect(
      contentKindOfFields(
        sourceId: 'community_classical',
        genre: 'Classical',
        statedKind: 'audiobook',
      ),
      ContentKind.audiobook,
    );
    const item = Song(
      id: 11,
      uri: 'tune://internet_archive/community_classical/1',
      sourceId: 'community_classical',
      genre: 'Classical',
      sourceData: {'contentKind': 'podcast'},
    );
    expect(contentKindOf(item), ContentKind.podcast);
  });

  test('an archive collection names the kind of the items filed under it', () {
    expect(contentKindOfCollections(['librivox']), ContentKind.audiobook);
    expect(contentKindOfCollections(['podcasts', 'foo']), ContentKind.podcast);
    expect(contentKindOfCollections(['oldtimeradio']), ContentKind.radio);
    expect(contentKindOfCollections(['audio_foreign']), ContentKind.audiobook);
    expect(contentKindOfCollections(['community_classical']), isNull);
    expect(contentKindOfCollections([]), isNull);
  });
}
