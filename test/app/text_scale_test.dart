import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/presentation/library_track_card.dart';
import 'package:tune/features/settings/presentation/settings_card_shell.dart';
import 'package:tune/l10n/app_localizations.dart';

/// The screens have to survive the text scale of the desktop.
///
/// The shell is a Linux one, and Linux has a text scale of its own: the
/// desktop reads the `text-scaling-factor` of GNOME and hands it to the
/// framework, which multiplies every size of the interface with it. A user
/// who finds the text too small raises that number, and the whole
/// interface grows with it.
///
/// The sizes of the scale are logical pixels, so a floor of eleven pixels
/// is a floor at a hundred percent and lifts with the setting. What the
/// setting does not lift is the room the text is given: a row of fifty six
/// pixels holds a title of fourteen pixels and an artist of twelve, and a
/// quarter more of both asks for more room than the row has.
///
/// A row grows with its text, so the height is never the problem. The width
/// is: the row of a track keeps the number of the position, the name, the
/// source and the time in one line, and a wide text in a narrow window has
/// to give way somewhere. These are the two places that have no room to
/// give, so they are the two places to watch.
void main() {
  const song = Song(
    id: 1,
    title: 'A very long song title that should be ellipsized',
    artist: 'A very long artist name that should be ellipsized',
    duration: 240000,
    uri: '/music/a.mp3',
  );

  testWidgets('a row of the library holds the text of a big scale', (
    tester,
  ) async {
    for (final scale in const [1.25, 1.5, 2.0]) {
      for (final width in const [1400.0, 760.0, 420.0]) {
        await _drawAt(
          tester,
          scale,
          width,
          const LibraryTrackCard(
            song: song,
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
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'a row of the library does not hold the text at $scale in $width',
        );
      }
    }
  });

  testWidgets('a card of the settings holds the text of a big scale', (
    tester,
  ) async {
    for (final scale in const [1.25, 1.5, 2.0]) {
      for (final width in const [1400.0, 760.0, 420.0]) {
        await _drawAt(
          tester,
          scale,
          width,
          SettingsCard(
            index: '01',
            eyebrow: '界面',
            title: '主题',
            description: '选择界面的明暗气质和显示语言。',
            child: const Text('内容'),
          ),
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'a card of the settings does not hold the text at $scale in $width',
        );
      }
    }
  });
}

/// Draws [child] with the text scale of the desktop set to [scale], in a
/// window of [width] pixels.
Future<void> _drawAt(
  WidgetTester tester,
  double scale,
  double width,
  Widget child,
) async {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: CompactTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _noop() {}
