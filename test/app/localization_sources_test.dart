import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/built_in_music_sources.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';

import '../services/fake_persistence.dart';

/// The names of the sources follow the language of the app.
///
/// The catalogue of the built-in sources is a function of the translations, so
/// a source never keeps the language of the first call.
void main() {
  final chinese = AppStrings.of(const Locale('zh', 'CN'));
  final english = AppStrings.of(const Locale('en'));

  group('built-in source names', () {
    test('a built-in source is named in the language of the app', () {
      expect(
        BuiltInMusicSources.nameOf(BuiltInMusicSources.local, chinese),
        '本地音乐',
      );
      expect(
        BuiltInMusicSources.nameOf(BuiltInMusicSources.local, english),
        'Local music',
      );
    });

    test('the description of a built-in source follows the language', () {
      final inChinese = BuiltInMusicSources.descriptionOf(
        BuiltInMusicSources.radio,
        chinese,
      );
      final inEnglish = BuiltInMusicSources.descriptionOf(
        BuiltInMusicSources.radio,
        english,
      );

      expect(inChinese, isNotEmpty);
      expect(inEnglish, isNotEmpty);
      expect(inChinese, isNot(inEnglish));
    });

    test('an imported source keeps the name it was given', () {
      const imported = MusicSourceConfig(
        id: 'my_own_source',
        name: 'My Own Source',
        description: 'A source the user brought along',
        kind: MusicSourceKind.openCatalog,
      );

      expect(BuiltInMusicSources.nameOf(imported, english), 'My Own Source');
      expect(
        BuiltInMusicSources.descriptionOf(imported, english),
        'A source the user brought along',
      );
    });
  });

  group('source names of the interface', () {
    test('every source is named after the catalogue of the app', () {
      final labels = sourceLabelsOf(english, BuiltInMusicSources.defaults);

      expect(labels['local']?.name, 'Local music');
      expect(labels['radio']?.name, 'Internet radio');
    });

    test('a source named after a brand also says what it is', () {
      final labels = sourceLabelsOf(english, BuiltInMusicSources.defaults);

      expect(labels['openverse']?.name, 'Openverse');
      expect(labels['openverse']?.localizedName, 'Open audio');
      expect(labels['subsonic']?.localizedName, 'Self-hosted');
    });

    test('a source named in the language of the reader has no second name', () {
      final labels = sourceLabelsOf(english, BuiltInMusicSources.defaults);

      expect(labels['local']?.name, 'Local music');
      expect(labels['local']?.localizedName, isEmpty);
    });

    test('the list of the sources carries the names of the app', () {
      final sources = localizedSources(english, BuiltInMusicSources.defaults);

      expect(sources.first.name, 'Local music');
      expect(sources.first.description, isNotEmpty);
    });
  });

  group('source failures', () {
    test('a failure of a source is shown as it is written', () {
      const failure = MusicSourceFailure('SomaFM did not return a list');

      expect(describeSourceError(failure), 'SomaFM did not return a list');
    });

    test('a failure of the network keeps the frame of the interface', () {
      final described = describeSourceError(StateError('socket closed'));

      expect(described, contains('socket closed'));
      expect(described, isNot(startsWith('socket closed')));
    });
  });

  group('the field vocabulary of the sources', () {
    test(
      'the sources share the messages of the fields they have in common',
      () {
        final service = _service();
        final strings = AppStrings.instance;

        // A field that means the same thing everywhere reads the same message.
        final shared = <String, Set<String>>{
          'query': {
            strings.fieldQuery,
            strings.fieldQueryOptional,
            // These three ask for something else than a keyword.
            strings.ccmixterFieldQuery,
            strings.internetArchiveFieldQuery,
            strings.radioFieldQuery,
          },
          'limit': {
            strings.fieldLimit,
            strings.fieldLimitFiles,
            strings.fieldLimitEpisodes,
            strings.fieldLimitStations,
          },
          'server': {strings.fieldServer},
          'user': {strings.fieldUser},
          'password': {strings.fieldPassword},
          'format': {strings.fieldFormat},
        };

        for (final adapter in service.adapters) {
          for (final field in adapter.configurationFields) {
            final messages = shared[field.key];
            if (messages == null) continue;

            expect(
              messages,
              contains(field.label),
              reason: '${adapter.sourceId} names its own ${field.key} field',
            );
          }
        }
      },
    );

    test('the hint of the limit names the numbers the source counts', () {
      final service = _service();
      final strings = AppStrings.instance;

      for (final adapter in service.adapters) {
        final limit = adapter.scanLimit;
        if (limit == null) continue;

        final fields = adapter.configurationFields
            .where((field) => field.key == 'limit')
            .toList(growable: false);
        expect(fields, hasLength(1), reason: adapter.sourceId);

        expect(
          fields.single.hint,
          strings.fieldLimitHint(limit.count, limit.max),
          reason: '${adapter.sourceId} shows other numbers than it counts',
        );
      }
    });
  });
}

/// The registry of the built-in sources.
MusicSourceService _service() {
  return MusicSourceService(
    scanner: CrossPlatformMusicScannerImpl(),
    store: MusicSourceStore(FakePersistenceService()),
  );
}
