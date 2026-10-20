import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/player/application/list_double_click.dart';
import 'package:tune/features/player/application/list_playback.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/playback_state.dart';
import 'package:tune/providers/persistence_providers.dart';

import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

void main() {
  late FakeAudioPlayerService audio;
  late PlaybackController controller;
  late ProviderContainer container;

  const song = Song(
    id: 1,
    title: 'Alpha',
    artist: 'Artist A',
    album: 'Album A',
    duration: 180000,
    uri: '/music/a.mp3',
  );

  setUp(() {
    audio = FakeAudioPlayerService();
    controller = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    container = ProviderContainer(
      overrides: [
        persistenceServiceProvider.overrideWithValue(FakePersistenceService()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    controller.dispose();
    audio.dispose();
  });

  ListDoubleClick doubleClick({required bool playsToo}) {
    return ListDoubleClick(
      favorites: container.read(favoritesControllerProvider.notifier),
      playback: ListPlayback(playback: controller, replaceQueue: false),
      playsToo: playsToo,
    );
  }

  test('a double click likes the track and leaves the music alone', () async {
    await doubleClick(playsToo: false).like(song);

    expect(container.read(favoritesControllerProvider).contains(song.uri), isTrue);
    expect(controller.state.queue, isEmpty);
    expect(controller.state.currentSong, isNull);
    expect(audio.playedSong, isNull);
  });

  test('a double click plays the track when the user asked for that', () async {
    await doubleClick(playsToo: true).like(song);

    expect(container.read(favoritesControllerProvider).contains(song.uri), isTrue);
    expect(controller.state.currentSong, song);
    expect(controller.state.status, PlaybackStatus.playing);
    expect(audio.playedSong, song);
  });

  test('a double click takes the mark away again', () async {
    final gesture = doubleClick(playsToo: false);

    await gesture.like(song);
    await gesture.like(song);

    expect(container.read(favoritesControllerProvider).contains(song.uri), isFalse);
  });
}
