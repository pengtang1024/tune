import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/application/hidden_sources_provider.dart';
import 'package:tune/features/library/application/library_controller.dart';

import 'fake_library_storage.dart';

Song _song(int id, String sourceId) => Song(
  id: id,
  title: 'Track $id',
  artist: 'Artist',
  uri: 'tune://$sourceId/$id',
  sourceId: sourceId,
  externalId: '$id',
  streamUrl: 'https://example.com/$id.mp3',
  dateAdded: id,
  duration: 180000,
);

Future<ProviderContainer> _container(
  FakeLibraryStorage storage, {
  Set<String> hidden = const {},
}) async {
  final container = ProviderContainer(
    overrides: [
      libraryStorageProvider.overrideWithValue(storage),
      libraryHiddenSourcesProvider.overrideWithValue(hidden),
    ],
  );
  addTearDown(container.dispose);
  await container.read(libraryControllerProvider.future);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a hidden source leaves both the rows and the count', () async {
    final storage = FakeLibraryStorage([
      _song(1, 'weak'),
      _song(2, 'weak'),
      _song(3, 'strong'),
    ]);
    final container = await _container(storage, hidden: {'weak'});
    final state = container.read(libraryControllerProvider).requireValue;

    expect(state.hiddenSources, {'weak'});
    expect(state.songs.map((song) => song.uri), ['tune://strong/3']);
    expect(state.matching, 1);
    expect(state.total, 3);
  });

  test('no gate means every row shows', () async {
    final storage = FakeLibraryStorage([
      _song(1, 'weak'),
      _song(2, 'strong'),
    ]);
    final container = await _container(storage);
    final state = container.read(libraryControllerProvider).requireValue;

    expect(state.hiddenSources, isEmpty);
    expect(state.songs.length, 2);
    expect(state.matching, 2);
  });
}
