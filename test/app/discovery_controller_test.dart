import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/built_in_music_sources.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/application/discovery_controller.dart';
import 'package:tune/features/discovery/data/discovery_feedback_store.dart';
import 'package:tune/features/discovery/domain/discovery_section.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/domain/music_sources_state.dart';
import 'package:tune/providers/persistence_providers.dart';

import '../services/fake_persistence.dart';
import 'compact_layout_test.dart' show FakeLibraryController;
import 'music_sources_section_test.dart' show FakeMusicSourcesController;

void main() {
  Song song(int id, {String artist = 'Artist'}) {
    return Song(
      id: id,
      title: 'Song $id',
      artist: artist,
      album: 'Album $id',
      uri: '/music/$id.mp3',
      dateAdded: DateTime.now().millisecondsSinceEpoch,
    );
  }

  final songs = [
    for (var index = 0; index < 30; index++)
      song(index, artist: index < 6 ? 'Nujabes' : 'Artist $index'),
  ];

  ProviderContainer createContainer(FakePersistenceService persistence) {
    final container = ProviderContainer(
      overrides: [
        persistenceServiceProvider.overrideWithValue(persistence),
        libraryControllerProvider.overrideWith(
          () => FakeLibraryController(LibraryState(songs: songs)),
        ),
        musicSourcesControllerProvider.overrideWith(
          () => FakeMusicSourcesController(
            MusicSourcesState(sources: BuiltInMusicSources.defaults),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> keepAlive(ProviderContainer container) async {
    container.listen(discoveryControllerProvider, (previous, next) {});
    await container.read(discoveryControllerProvider.future);
  }

  test('the page is a projection of the library', () async {
    final container = createContainer(FakePersistenceService());
    await keepAlive(container);

    final state = container.read(discoveryControllerProvider).requireValue;
    expect(state.sections, isNotEmpty);
    expect(
      state.sections.any(
        (section) => section.kind == DiscoverySectionKind.dailyMix,
      ),
      isTrue,
    );
  });

  test('a heart gives the artist a shelf', () async {
    final container = createContainer(FakePersistenceService());
    await keepAlive(container);

    for (var index = 0; index < 2; index++) {
      await container
          .read(favoritesControllerProvider.notifier)
          .mark('/music/$index.mp3');
    }
    await container.read(discoveryControllerProvider.future);

    final state = container.read(discoveryControllerProvider).requireValue;
    final artistSections = state.sections.where(
      (section) => section.kind == DiscoverySectionKind.artist,
    );
    expect(artistSections, isNotEmpty);
    expect(artistSections.first.reason.artist, 'Nujabes');
  });

  test('a dismissal is removed and survives a restart', () async {
    final persistence = FakePersistenceService();
    final container = createContainer(persistence);
    await keepAlive(container);

    final first = container
        .read(discoveryControllerProvider)
        .requireValue
        .sections
        .first;
    final uri = first.tracks.first.song.uri;
    await container.read(discoveryControllerProvider.notifier).dismiss(uri);

    final after = container.read(discoveryControllerProvider).requireValue;
    final uris = {
      for (final section in after.sections)
        for (final track in section.tracks) track.song.uri,
    };
    expect(uris, isNot(contains(uri)));
    expect(
      persistence.getString(DiscoveryFeedbackStore.key),
      contains(uri),
    );

    final restarted = createContainer(persistence);
    await keepAlive(restarted);
    final restartedUris = {
      for (final section in restarted
          .read(discoveryControllerProvider)
          .requireValue
          .sections)
        for (final track in section.tracks) track.song.uri,
    };
    expect(restartedUris, isNot(contains(uri)));
  });

  test('undo brings a dismissed track back', () async {
    final container = createContainer(FakePersistenceService());
    await keepAlive(container);

    final uri = container
        .read(discoveryControllerProvider)
        .requireValue
        .sections
        .first
        .tracks
        .first
        .song
        .uri;
    final controller = container.read(discoveryControllerProvider.notifier);
    await controller.dismiss(uri);
    await controller.forgetDismissal(uri);

    final uris = {
      for (final section in container
          .read(discoveryControllerProvider)
          .requireValue
          .sections)
        for (final track in section.tracks) track.song.uri,
    };
    expect(uris, contains(uri));
  });

  test('clearing feedback leaves the favorites alone', () async {
    final container = createContainer(FakePersistenceService());
    await keepAlive(container);
    await container
        .read(favoritesControllerProvider.notifier)
        .mark('/music/0.mp3');
    final uri = container
        .read(discoveryControllerProvider)
        .requireValue
        .sections
        .first
        .tracks
        .first
        .song
        .uri;
    final controller = container.read(discoveryControllerProvider.notifier);
    await controller.dismiss(uri);
    await controller.clearFeedback();

    expect(
      container.read(favoritesControllerProvider).contains('/music/0.mp3'),
      isTrue,
    );
    final state = container.read(discoveryControllerProvider).requireValue;
    expect(
      state.sections.any(
        (section) => section.kind == DiscoverySectionKind.dailyMix,
      ),
      isTrue,
    );
  });
}

