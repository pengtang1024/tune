import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/application/discovery_providers.dart';
import 'package:tune/features/discovery/application/discovery_signal_observer.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/playback_state.dart';
import 'package:tune/providers/persistence_providers.dart';

import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a listen and a skip are summarized on the next track', () async {
    final persistence = FakePersistenceService()
      ..values['discovery_use_listening_history'] = true;
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final playback = _FakePlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    final container = ProviderContainer(
      overrides: [
        persistenceServiceProvider.overrideWithValue(persistence),
        playbackControllerProvider.overrideWith((ref) => playback),
      ],
    );
    addTearDown(container.dispose);

    final observer = container.read(discoverySignalObserverProvider)..start();
    playback.emit(_state('/music/a.mp3', positionMs: 0));
    playback.emit(_state('/music/a.mp3', positionMs: 50000));
    playback.emit(_state('/music/b.mp3', positionMs: 0));
    playback.emit(_state('/music/b.mp3', positionMs: 1000));
    playback.emit(_state('/music/c.mp3', positionMs: 0));
    await observer.flush();

    final signals = container.read(listeningSignalStoreProvider).read();
    expect(signals['/music/a.mp3']!.listens, 1);
    expect(signals['/music/a.mp3']!.listenedMs, 50000);
    expect(signals['/music/b.mp3']!.skips, 1);
  });

  test('nothing is written while the setting is off', () async {
    final persistence = FakePersistenceService();
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final playback = _FakePlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    final container = ProviderContainer(
      overrides: [
        persistenceServiceProvider.overrideWithValue(persistence),
        playbackControllerProvider.overrideWith((ref) => playback),
      ],
    );
    addTearDown(container.dispose);

    final observer = container.read(discoverySignalObserverProvider)..start();
    playback.emit(_state('/music/a.mp3', positionMs: 0));
    playback.emit(_state('/music/b.mp3', positionMs: 0));
    await observer.flush();

    expect(container.read(listeningSignalStoreProvider).read(), isEmpty);
  });
}

PlaybackState _state(String uri, {required int positionMs}) {
  return PlaybackState(
    status: PlaybackStatus.playing,
    position: Duration(milliseconds: positionMs),
    duration: const Duration(minutes: 1),
    queue: [Song(id: uri.hashCode, title: uri, uri: uri)],
    currentUri: uri,
  );
}

class _FakePlaybackController extends PlaybackController {
  _FakePlaybackController(super.audio, super.downloads, super.resolver);

  void emit(PlaybackState next) {
    state = next;
  }
}
