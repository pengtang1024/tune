import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/built_in_music_sources.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/music_sources/source_type_catalogue.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/shared/ui/source_mark.dart';

import 'fake_persistence.dart';

/// A source has a type and instances of that type.
///
/// The type says how the tracks are fetched; the instance says which one.
/// Several instances may share a type, so the registry answers by type and
/// the name and the icon belong to the type as well.
void main() {
  final english = AppStrings.of(const Locale('en'));

  group('a source knows its type', () {
    test('a configuration carries the type it was written with', () {
      const config = MusicSourceConfig(
        id: 'jamendo:1',
        type: 'jamendo',
        name: 'Jamendo',
        kind: MusicSourceKind.openCatalog,
      );

      expect(config.sourceType, 'jamendo');
      expect(config.id, 'jamendo:1');
    });

    test('a configuration written before the split falls back to its id', () {
      const config = MusicSourceConfig(
        id: 'subsonic',
        name: 'Subsonic',
        kind: MusicSourceKind.openApi,
      );

      expect(config.sourceType, 'subsonic');
    });

    test('the id of a retired plugin carries a hash, so its type is known', () {
      const config = MusicSourceConfig(
        id: 'plugin_1a2b3c',
        name: 'Demo',
        kind: MusicSourceKind.custom,
      );

      expect(config.sourceType, retiredPluginType);
    });

    test('the type survives a round trip through the storage', () {
      const config = MusicSourceConfig(
        id: 'jamendo:1',
        type: 'jamendo',
        name: 'Jamendo',
        kind: MusicSourceKind.openCatalog,
      );

      final restored = MusicSourceConfig.fromJson(config.toJson());

      expect(restored.sourceType, 'jamendo');
      expect(restored.builtIn, isFalse);
    });

    test('the built-in sources are marked as built-in', () {
      for (final source in BuiltInMusicSources.defaults) {
        expect(
          source.builtIn,
          isTrue,
          reason: '${source.id} comes with the app',
        );
        expect(source.sourceType, source.id);
      }
    });
  });

  group('the registry answers by type', () {
    test('two instances of one type share the adapter of that type', () {
      final service = MusicSourceService(
        scanner: CrossPlatformMusicScannerImpl(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      const first = MusicSourceConfig(
        id: 'jamendo:1',
        type: 'jamendo',
        name: 'Jamendo',
        kind: MusicSourceKind.openCatalog,
      );
      const second = MusicSourceConfig(
        id: 'jamendo:2',
        type: 'jamendo',
        name: 'Jamendo',
        kind: MusicSourceKind.openCatalog,
      );

      expect(service.supportsConfig(first), isTrue);
      expect(service.supportsConfig(second), isTrue);
      expect(
        service.adapterFor(first.sourceType),
        same(service.adapterFor(second.sourceType)),
      );
    });

    test('an instance of an unknown type is not supported', () {
      final service = MusicSourceService(
        scanner: CrossPlatformMusicScannerImpl(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      const config = MusicSourceConfig(
        id: 'made_up:1',
        type: 'made_up',
        name: 'Made up',
        kind: MusicSourceKind.openApi,
      );

      expect(service.supportsConfig(config), isFalse);
    });
  });

  group('the name and the icon belong to the type', () {
    test('an instance of a built-in type keeps the name of the type', () {
      const instance = MusicSourceConfig(
        id: 'jamendo:1',
        type: 'jamendo',
        name: 'Jamendo',
        kind: MusicSourceKind.openCatalog,
      );

      final localized = localizedSources(english, [instance]);

      expect(localized.single.name, 'Jamendo');
      expect(localized.single.localizedName, isNotEmpty);
    });

    test('a source the reader added keeps the name they gave it', () {
      const instance = MusicSourceConfig(
        id: 'subsonic:1',
        type: 'subsonic',
        name: 'My server',
        kind: MusicSourceKind.custom,
      );

      final localized = localizedSources(english, [instance]);

      expect(localized.single.name, 'My server');
      expect(localized.single.localizedName, isNotEmpty);
    });

    test('an instance of a built-in type keeps the icon of the type', () {
      const instance = MusicSourceConfig(
        id: 'jamendo:1',
        type: 'jamendo',
        name: 'Jamendo',
        kind: MusicSourceKind.openCatalog,
      );

      expect(
        sourceIconOf(instance.sourceType, instance.kind),
        sourceIconOf('jamendo', MusicSourceKind.openCatalog),
      );
    });
  });

  group('the catalogue of the types', () {
    test('every type the app serves is named', () {
      final service = MusicSourceService(
        scanner: CrossPlatformMusicScannerImpl(),
        store: MusicSourceStore(FakePersistenceService()),
      );
      final catalogue = SourceTypeCatalogue.byType(english);

      for (final adapter in service.adapters) {
        expect(
          catalogue.containsKey(adapter.sourceType),
          isTrue,
          reason: '${adapter.sourceType} is served but the catalogue does not name it',
        );
      }
    });

    test('the type the reader adds is the one the type says', () {
      final service = MusicSourceService(
        scanner: CrossPlatformMusicScannerImpl(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      final addable = service.addableTypes;

      // The local folder is a setting of the app, not an instance the reader
      // adds.
      expect(
        addable.where((type) => type.type == 'local'),
        isEmpty,
      );
      expect(
        addable.where((type) => type.type == 'direct_url'),
        hasLength(1),
      );
      expect(
        addable.where((type) => type.type == 'm3u'),
        hasLength(1),
      );
      expect(
        addable.where((type) => type.type == 'json_api'),
        hasLength(1),
      );
    });
  });

  group('where a source belongs in the list', () {
    test('the type says whether it stands at the top', () {
      final service = MusicSourceService(
        scanner: CrossPlatformMusicScannerImpl(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      for (final id in [
        'local',
        'radio',
        'openverse',
        'jamendo',
        'internet_archive',
        'ccmixter',
        'audius',
        'wikimedia',
      ]) {
        expect(
          service.isFeatured(_builtIn(id)),
          isTrue,
          reason: '$id asks nothing of the reader, so it stands at the top',
        );
      }

      for (final id in [
        'itunes',
        'podcast_rss',
        'netease',
        'subsonic',
        'jellyfin',
      ]) {
        expect(
          service.isFeatured(_builtIn(id)),
          isFalse,
          reason: '$id needs a key or a decision, so it waits in the folded group',
        );
      }
    });

    test('a source the reader added is never at the top', () {
      final service = MusicSourceService(
        scanner: CrossPlatformMusicScannerImpl(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      const added = MusicSourceConfig(
        id: 'jamendo:1',
        type: 'jamendo',
        name: '我的 Jamendo',
        kind: MusicSourceKind.custom,
      );

      expect(service.isFeatured(added), isFalse);
    });
  });
}

/// A built-in source of the given type.
MusicSourceConfig _builtIn(String type) {
  return MusicSourceConfig(
    id: type,
    type: type,
    name: type,
    kind: MusicSourceKind.openCatalog,
    builtIn: true,
  );
}
