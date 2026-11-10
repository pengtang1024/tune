import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/presentation/library_row_metrics.dart';
import 'package:tune/features/library/presentation/library_track_card.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/hint_layer.dart';
import 'package:tune/shared/ui/icon_glyph.dart';

const song = Song(
  id: 1,
  title: 'Track title',
  artist: 'Artist',
  album: 'Album',
  duration: 200000,
  uri: '/music/track.mp3',
);

/// Guards the row that a keyboard can reach.
///
/// The two extra actions of the tail appear under the pointer. A reader who
/// walks the list with Tab has no pointer, so the row has to show the same
/// actions while its focus is inside — and keep them while the focus walks
/// into them.
void main() {
  testWidgets('a row reached by Tab shows its actions and keeps them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: CompactTheme.light,
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => HintLayer(child: child!),
          home: Scaffold(
            body: LibraryTrackCard(
              song: song,
              index: 0,
              selected: false,
              playing: false,
              isFavorite: false,
              metrics: LibraryRowMetrics.at(width: 1800, textScale: 1),
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

    // At rest the tail says the facts, not the actions.
    expect(_mark(Icons.info_outline_rounded), findsNothing);
    expect(_mark(Icons.add_rounded), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(_mark(Icons.info_outline_rounded), findsOneWidget);
    expect(_mark(Icons.add_rounded), findsOneWidget);

    // The focus moves into the actions: they stay, so the keyboard can reach
    // them instead of losing the stop it just found.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(_mark(Icons.info_outline_rounded), findsOneWidget);
    expect(_mark(Icons.add_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// The dense actions draw their mark with [IconGlyph], not with [Icon].
Finder _mark(IconData icon) {
  return find.byWidgetPredicate(
    (widget) => widget is IconGlyph && widget.icon == icon,
  );
}

void _noop() {}
