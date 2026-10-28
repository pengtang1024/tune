import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/song_download_service_provider.dart';
import 'package:tune/data/services/providers/stream_url_resolver_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/data/playback_session_store.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/domain/playback_state.dart';
import 'package:tune/providers/persistence_providers.dart';

import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const song = Song(
    id: 1,
    title: 'Alpha',
    artist: 'Artist A',
    duration: 180000,
    uri: '/music/a.mp3',
  );

  test('the start reads the auto resume switch from the settings', () async {
    final persistence = FakePersistenceService();
    final store = PlaybackSessionStore(persistence);
    await store.saveQueue(
      queue: const [song],
      currentUri: song.uri,
      playMode: PlayMode.sequential,
      history: const [],
    );
    await store.savePosition(song.uri, const Duration(seconds: 12));

    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final overrides = [
      persistenceServiceProvider.overrideWithValue(persistence),
      audioPlayerServiceProvider.overrideWithValue(audio),
      songDownloadServiceProvider.overrideWithValue(FakeSongDownloadService()),
      streamUrlResolverProvider.overrideWithValue(FakeStreamUrlResolver()),
    ];

    // The queue comes back either way; the switch only decides whether
    // the restored track plays on by itself.
    final on = ProviderContainer(overrides: overrides);
    addTearDown(on.dispose);
    expect(on.read(playbackControllerProvider).queue, [song]);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(audio.playedSong, song);

    await persistence.setBool('auto_resume_on_startup', false);
    final off = ProviderContainer(overrides: overrides);
    addTearDown(off.dispose);
    expect(off.read(playbackControllerProvider).queue, [song]);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(audio.playedSong, song); // Still the first container's play.
    expect(off.read(playbackControllerProvider).status, PlaybackStatus.paused);
  });
}
