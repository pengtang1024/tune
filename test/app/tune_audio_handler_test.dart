import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/application/tune_audio_handler.dart';
import 'package:tune/features/player/data/playback_session_store.dart';
import 'package:tune/features/player/domain/play_mode.dart';

import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

void main() {
  const songA = Song(
    id: 1,
    title: 'Alpha',
    artist: 'Artist A',
    duration: 180000,
    uri: '/music/a.mp3',
  );
  const songB = Song(
    id: 2,
    title: 'Beta',
    artist: 'Artist B',
    duration: 120000,
    uri: '/music/b.mp3',
  );

  late FakeAudioPlayerService audio;
  late FakeSongDownloadService downloads;
  late FakeStreamUrlResolver resolver;

  setUp(() {
    audio = FakeAudioPlayerService();
    downloads = FakeSongDownloadService();
    resolver = FakeStreamUrlResolver();
  });

  tearDown(() => audio.dispose());

  test('the media session mirrors the controller and keeps its queue', () async {
    final store = PlaybackSessionStore(FakePersistenceService());
    await store.saveQueue(
      queue: const [songA, songB],
      currentUri: songB.uri,
      playMode: PlayMode.sequential,
      history: [songA.uri],
    );

    final controller = PlaybackController(
      audio,
      downloads,
      resolver,
      sessionStore: store,
    );
    final container = ProviderContainer(
      overrides: [playbackControllerProvider.overrideWith((ref) => controller)],
    );
    addTearDown(container.dispose);

    final handler = TuneAudioHandler();
    handler.attach(container);

    final item = await handler.mediaItem.first;
    expect(item?.title, 'Beta');
    expect(item?.artist, 'Artist B');
    expect(item?.duration, const Duration(seconds: 120));

    final state = await handler.playbackState.first;
    expect(state.playing, isFalse);
    expect(state.processingState, audio_service.AudioProcessingState.ready);
    expect(state.queueIndex, 1);
    expect(
      state.controls.map((control) => control.action),
      contains(audio_service.MediaAction.play),
    );

    final mirrored = await handler.queue.first;
    expect(mirrored.map((item) => item.title), ['Alpha', 'Beta']);
  });
}
