import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/audio_source_status.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/domain/playback_state.dart';

import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

void main() {
  late FakeAudioPlayerService audio;
  late FakeSongDownloadService downloads;
  late FakeStreamUrlResolver resolver;
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

  const remoteSong = Song(
    id: 5,
    title: 'Remote',
    artist: 'Artist R',
    album: 'Album R',
    duration: 150000,
    uri: 'tune://openverse/remote-1',
    streamUrl: 'https://cdn.example.com/remote-1.mp3',
  );

  const expiringSong = Song(
    id: 6,
    title: 'Expiring',
    artist: 'Artist E',
    album: 'Album E',
    duration: 100000,
    uri: 'tune://netease/expiring-1',
    sourceId: 'netease',
    externalId: 'expiring-1',
    streamUrl: 'https://cdn.example.com/expiring-1.mp3?token=old',
  );

  setUp(() {
    audio = FakeAudioPlayerService();
    downloads = FakeSongDownloadService();
    resolver = FakeStreamUrlResolver();
    controller = PlaybackController(audio, downloads, resolver);
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

  group('local sources', () {
    test('a local track plays straight from disk', () async {
      await controller.playQueue([songA]);

      expect(downloads.downloadedUris, isEmpty);
      expect(audio.playedLocalFilePath, isNull);
      expect(controller.state.audioSourceStatus, AudioSourceStatus.local);
    });
  });

  group('remote sources', () {
    test('a remote track is fetched before it plays', () async {
      await controller.playQueue([remoteSong]);

      expect(downloads.downloadedUris, [remoteSong.uri]);
      expect(audio.playedLocalFilePath, isNotNull);
      expect(controller.state.audioSourceStatus, AudioSourceStatus.cached);
      expect(controller.state.downloadProgress, 1);
      expect(controller.state.status, PlaybackStatus.playing);
    });

    test('a stored track is replayed without a new transfer', () async {
      downloads.storedFiles[remoteSong.uri] = '/store/remote-1.mp3';

      await controller.playQueue([remoteSong]);

      expect(downloads.downloadedUris, isEmpty);
      expect(audio.playedLocalFilePath, '/store/remote-1.mp3');
      expect(controller.state.audioSourceStatus, AudioSourceStatus.cached);
    });

    test('the transfer progress reaches the playback state', () async {
      final observed = <double>[];
      downloads.progressObserver = (_) {
        observed.add(controller.state.downloadProgress);
      };

      await controller.playQueue([remoteSong]);

      expect(observed, [0.5, 1.0]);
    });

    test('a failed transfer marks the source as failed', () async {
      downloads.failDownloads = true;

      await controller.playQueue([remoteSong]);

      expect(controller.state.status, PlaybackStatus.error);
      expect(controller.state.audioSourceStatus, AudioSourceStatus.failed);
      expect(audio.playedSong, isNull);
    });

    test('a platform without a file system streams the track', () async {
      downloads.isSupported = false;

      await controller.playQueue([remoteSong]);

      expect(downloads.downloadedUris, isEmpty);
      expect(audio.playedLocalFilePath, isNull);
      expect(audio.playedSong, remoteSong);
      expect(controller.state.status, PlaybackStatus.playing);
    });
  });

  group('expired addresses', () {
    test('a broken address is refreshed once and replayed', () async {
      resolver.responses[expiringSong.uri] = expiringSong.copyWith(
        streamUrl: 'https://cdn.example.com/expiring-1.mp3?token=new',
      );
      audio.nextPlayError = StateError('address expired');

      await controller.playQueue([expiringSong]);

      expect(resolver.refreshedUris, [expiringSong.uri]);
      expect(audio.playCount, 2);
      expect(controller.state.status, PlaybackStatus.playing);
      expect(
        controller.state.queue.first.streamUrl,
        'https://cdn.example.com/expiring-1.mp3?token=new',
      );
    });

    test('a track that keeps failing ends in the error state', () async {
      resolver.responses[expiringSong.uri] = expiringSong.copyWith(
        streamUrl: 'https://cdn.example.com/expiring-1.mp3?token=new',
      );
      audio.failPlays = true;

      await controller.playQueue([expiringSong]);

      expect(resolver.refreshedUris, [expiringSong.uri]);
      expect(audio.playCount, 2);
      expect(controller.state.status, PlaybackStatus.error);
      expect(controller.state.errorMessage, contains('播放失败'));
      expect(controller.state.audioSourceStatus, AudioSourceStatus.failed);
    });

    test('a track without a source is not refreshed', () async {
      audio.nextPlayError = StateError('cannot play');

      await controller.playQueue([songA]);

      expect(resolver.refreshedUris, isEmpty);
      expect(audio.playCount, 1);
      expect(controller.state.status, PlaybackStatus.error);
    });

    test(
      'a backend error reported while loading triggers the refresh',
      () async {
        final gate = Completer<void>();
        audio.playGate = gate;
        resolver.responses[expiringSong.uri] = expiringSong.copyWith(
          streamUrl: 'https://cdn.example.com/expiring-1.mp3?token=new',
        );

        final playback = controller.playQueue([expiringSong]);
        await pumpEventQueue();
        expect(controller.state.status, PlaybackStatus.loading);

        audio.emitError('address expired');
        await pumpEventQueue();
        gate.complete();
        await playback;
        await pumpEventQueue();

        expect(resolver.refreshedUris, [expiringSong.uri]);
        expect(controller.state.status, PlaybackStatus.playing);
        expect(
          controller.state.queue.first.streamUrl,
          'https://cdn.example.com/expiring-1.mp3?token=new',
        );
      },
    );
  });
}
