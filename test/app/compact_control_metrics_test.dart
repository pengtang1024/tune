import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/presentation/library_track_card.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';

/// The metrics of the shell have to mean what they say.
///
/// A token that names a height is only worth something if the widget paints
/// at that height. Two things used to break that: the compact density of the
/// desktop takes eight pixels off the height of a button, so a token of
/// thirty four painted a button of twenty six, and the three kinds of
/// button had three heights, so a row of them was never level.
void main() {
  testWidgets('the three kinds of button share one height', (tester) async {
    await onLinux(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CompactTheme.light,
          home: const Scaffold(
            body: Row(
              children: [
                FilledButton(onPressed: null, child: Text('a')),
                OutlinedButton(onPressed: null, child: Text('b')),
                TextButton(onPressed: null, child: Text('c')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final heights = <String, double>{
        'filled': tester.getSize(find.byType(FilledButton).first).height,
        'outlined': tester.getSize(find.byType(OutlinedButton).first).height,
        'text': tester.getSize(find.byType(TextButton).first).height,
      };

      for (final entry in heights.entries) {
        expect(
          entry.value,
          CompactTokens.controlDefault,
          reason:
              'the ${entry.key} button has to paint at the height of the token',
        );
      }
      expect(heights.values.toSet().length, 1);
    });
  });

  testWidgets('a row of a track list is as tall as the token', (tester) async {
    await onLinux(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CompactTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: LibraryTrackCard(
                song: Song(
                  id: 1,
                  title: 'A title',
                  artist: 'An artist',
                  duration: 1000,
                  uri: '/music/a.mp3',
                ),
                index: 0,
                selected: false,
                playing: false,
                isFavorite: false,
                onTap: _noop,
                onDoubleTap: _noop,
                waitsForDoubleClick: false,
                onAddToQueue: _noop,
                onToggleFavorite: _noop,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = find.byType(LibraryTrackCard);
      expect(tester.getSize(card.first).height, CompactTokens.libraryRowHeight);
      expect(
        tester.getSize(card.first).height,
        CompactTokens.libraryArtwork + 2 * CompactTokens.libraryRowPadding,
        reason:
            'the row is the artwork plus the room the token keeps around it',
      );

      final artwork = find.byType(ArtworkThumb);
      expect(
        tester.getSize(artwork.first).height,
        CompactTokens.libraryArtwork,
      );
    });
  });

  test('the smallest step of the scale still carries a Chinese character', () {
    // A Chinese glyph packs a dozen strokes into the space of a letter.
    // Below eleven pixels the strokes fall on top of each other and the
    // character turns into a blot, which is what the eyebrow of a page used
    // to look like on a screen that is not scaled up.
    expect(CompactTypeScale.mark, greaterThanOrEqualTo(11));
    expect(CompactTypeScale.label, greaterThan(CompactTypeScale.mark));
    expect(CompactTypeScale.body, greaterThan(CompactTypeScale.label));
    expect(CompactTypeScale.strong, greaterThan(CompactTypeScale.body));
    expect(CompactTypeScale.title, greaterThan(CompactTypeScale.strong));
    expect(CompactTypeScale.heading, greaterThan(CompactTypeScale.title));
  });

  test('every role of the theme is a step of the scale', () {
    final steps = <double>[
      CompactTypeScale.mark,
      CompactTypeScale.label,
      CompactTypeScale.body,
      CompactTypeScale.strong,
      CompactTypeScale.title,
      CompactTypeScale.heading,
      CompactTypeScale.displaySmall,
      CompactTypeScale.displayMedium,
      CompactTypeScale.displayLarge,
    ];
    final theme = CompactTheme.light.textTheme;
    final roles = <String, TextStyle?>{
      'displayLarge': theme.displayLarge,
      'displayMedium': theme.displayMedium,
      'displaySmall': theme.displaySmall,
      'headlineLarge': theme.headlineLarge,
      'headlineMedium': theme.headlineMedium,
      'headlineSmall': theme.headlineSmall,
      'titleLarge': theme.titleLarge,
      'titleMedium': theme.titleMedium,
      'titleSmall': theme.titleSmall,
      'bodyLarge': theme.bodyLarge,
      'bodyMedium': theme.bodyMedium,
      'bodySmall': theme.bodySmall,
      'labelLarge': theme.labelLarge,
      'labelMedium': theme.labelMedium,
      'labelSmall': theme.labelSmall,
    };

    for (final entry in roles.entries) {
      final size = entry.value?.fontSize;
      expect(
        size,
        isNotNull,
        reason: 'the role ${entry.key} of the theme has no size of its own',
      );
      expect(
        steps,
        contains(size),
        reason:
            'the role ${entry.key} of the theme writes ${size}px, '
            'which is not a step of the scale',
      );
    }
  });
}

void _noop() {}

/// Runs [body] as if the app ran on the desktop.
///
/// The test suite pretends to be Android, and Android draws with another
/// density and a padded tap target, so the numbers of a button taken
/// without this would not be the numbers the app paints.
Future<void> onLinux(Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}
