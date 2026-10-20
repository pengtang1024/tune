import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/list_playback.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/playback_state.dart';

import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

void main() {
  late FakeAudioPlayerService audio;
  late PlaybackController controller;

  const songA = Song(
    id: 1,
    title: 'Alpha',
    artist: 'Artist A',
    album: 'Album A',
    duration: 180000,
    uri: '/music/a.mp3',
  );
  const songB = Song(
    id: 2,
    title: 'Beta',
    artist: 'Artist B',
    album: 'Album B',
    duration: 120000,
    uri: '/music/b.mp3',
  );
  const songC = Song(
    id: 3,
    title: 'Gamma',
    artist: 'Artist C',
    album: 'Album C',
    duration: 90000,
    uri: '/music/c.mp3',
  );

  setUp(() {
    audio = FakeAudioPlayerService();
    controller = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
  });

  tearDown(() {
    controller.dispose();
    audio.dispose();
  });

  test('a click that keeps the queue grows the queue', () async {
    await controller.playQueue([songA]);

    await ListPlayback(playback: controller, replaceQueue: false).play(songB);

    expect(controller.state.queue, [songA, songB]);
    expect(controller.state.currentSong, songB);
    expect(controller.state.status, PlaybackStatus.playing);
  });

  test('a click that replaces the queue leaves one track', () async {
    await controller.playQueue([songA]);

    await ListPlayback(playback: controller, replaceQueue: true).play(songB);

    expect(controller.state.queue, [songB]);
    expect(controller.state.currentSong, songB);
  });

  test('playing out of a list replaces the queue with the whole list', () async {
    await controller.playQueue([songA]);

    await ListPlayback(playback: controller, replaceQueue: true)
        .playFrom(songB, [songA, songB, songC], 1);

    expect(controller.state.queue, [songA, songB, songC]);
    expect(controller.state.currentIndex, 1);
  });

  test('playing out of a list that keeps the queue adds the track only',
      () async {
    await controller.playQueue([songA]);

    await ListPlayback(playback: controller, replaceQueue: false)
        .playFrom(songB, [songA, songB, songC], 1);

    expect(controller.state.queue, [songA, songB]);
    expect(controller.state.currentSong, songB);
  });
}
