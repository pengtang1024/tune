import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/domain/playback_state.dart';

import 'fake_audio_player_service.dart';

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
    controller = PlaybackController(audio);
  });

  tearDown(() {
    controller.dispose();
    audio.dispose();
  });

  test('playQueue owns the queue and starts playback', () async {
    await controller.playQueue([songA, songB], startIndex: 1);

    expect(controller.state.queue, [songA, songB]);
    expect(controller.state.currentIndex, 1);
    expect(controller.state.currentSong, songB);
    expect(controller.state.status, PlaybackStatus.playing);
    expect(audio.playedSong, songB);
  });

  test(
    'playQueue keeps the start song when earlier entries are empty',
    () async {
      const empty = Song(
        id: 4,
        title: 'Empty',
        artist: 'Artist',
        duration: 1000,
        uri: '',
      );

      await controller.playQueue([empty, songA, songB], startIndex: 1);

      expect(audio.playedSong?.uri, songA.uri);
      expect(controller.state.queue.map((song) => song.uri), [
        songA.uri,
        songB.uri,
      ]);

      await controller.playQueue([songA, empty, songB], startIndex: 1);

      expect(audio.playedSong?.uri, songB.uri);
    },
  );

  test('clearing the queue while a track loads keeps playback empty', () async {
    final gate = Completer<void>();
    audio.playGate = gate;

    final playback = controller.playQueue([songA]);
    await Future<void>.delayed(Duration.zero);
    await controller.clearQueue();

    gate.complete();
    await playback;

    expect(controller.state.currentSong, isNull);
    expect(controller.state.queue, isEmpty);
    expect(controller.state.status, PlaybackStatus.idle);
  });

  test('pause and resume keep a single playback state', () async {
    await controller.playQueue([songA]);

    await controller.pause();
    expect(controller.state.status, PlaybackStatus.paused);

    await controller.resume();
    expect(controller.state.status, PlaybackStatus.playing);
  });

  test(
    'next follows queue order and repeat-one repeats on completion',
    () async {
      await controller.playQueue([songA, songB]);

      await controller.next();
      expect(controller.state.currentSong, songB);

      controller.cyclePlayMode();
      expect(controller.state.playMode, PlayMode.repeatOne);

      final playsBeforeCompletion = audio.playCount;
      audio.complete();
      await pumpEventQueue();

      expect(audio.playCount, playsBeforeCompletion + 1);
      expect(controller.state.currentSong, songB);
    },
  );

  test('reorder keeps the current song selected', () async {
    await controller.playQueue([songA, songB, songC]);

    controller.reorderQueue(0, 3);

    expect(controller.state.queue, [songB, songC, songA]);
    expect(controller.state.currentSong, songA);
    expect(controller.state.currentIndex, 2);
  });

  test('removing the current track advances playback', () async {
    await controller.playQueue([songA, songB]);

    await controller.removeFromQueue(0);

    expect(controller.state.queue, [songB]);
    expect(controller.state.currentSong, songB);
    expect(controller.state.currentIndex, 0);
    expect(audio.playedSong, songB);
  });

  test(
    'adding to an empty queue stages the track without auto-playing',
    () async {
      controller.addToQueue(songA);

      expect(controller.state.queue, [songA]);
      expect(controller.state.currentSong, songA);
      expect(controller.state.status, PlaybackStatus.paused);

      await controller.togglePlayPause();
      expect(controller.state.status, PlaybackStatus.playing);
      expect(audio.playedSong, songA);
    },
  );
}
