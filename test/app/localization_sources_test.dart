import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/built_in_music_sources.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';

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
      final names = sourceNamesOf(english, BuiltInMusicSources.defaults);

      expect(names['local'], 'Local music');
      expect(names['radio'], 'Internet radio');
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
}
