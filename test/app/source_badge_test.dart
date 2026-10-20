import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/shared/ui/source_badge.dart';
import 'package:tune/shared/ui/source_mark.dart';

void main() {
  testWidgets('the mark of a source is an icon and names the source', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const SourceLabel(
          name: 'Openverse',
          localizedName: '开放版权聚合',
          id: 'openverse',
        ),
      ),
    );

    // The name of the source waits in the tooltip: the mark itself is an
    // icon, so the row keeps its shape whatever the source is called.
    expect(find.byType(SourceBadge), findsOneWidget);
    expect(find.textContaining('Openverse'), findsNothing);
    expect(find.byTooltip('Openverse · 开放版权聚合'), findsOneWidget);
  });

  testWidgets('the mark of a source keeps its size whatever the name is', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const SourceLabel(name: 'Wikimedia Commons', id: 'wikimedia'),
      ),
    );
    final wide = tester.getSize(find.byType(SourceBadge));

    await tester.pumpWidget(
      _app(const SourceLabel(name: 'iTunes', id: 'itunes')),
    );
    final narrow = tester.getSize(find.byType(SourceBadge));

    expect(wide, narrow);
  });

  test('every built-in source has an icon of its own', () {
    const ids = [
      'local',
      'openverse',
      'jamendo',
      'internet_archive',
      'netease',
      'ccmixter',
      'itunes',
      'podcast_rss',
      'subsonic',
      'audius',
      'radio',
      'wikimedia',
      'jellyfin',
    ];

    final icons = ids
        .map((id) => sourceIconOf(id, MusicSourceKind.openCatalog))
        .toSet();

    expect(icons.length, ids.length);
  });

  test('the colour of a source says what kind of source it is', () {
    // The kind paints the mark, the icon names the source.
    expect(
      sourceToneOf(MusicSourceKind.openCatalog),
      sourceToneOf(MusicSourceKind.openCatalog),
    );
    expect(
      sourceToneOf(MusicSourceKind.openCatalog),
      isNot(sourceToneOf(MusicSourceKind.openApi)),
    );
    expect(
      sourceToneOf(MusicSourceKind.plugin),
      isNot(sourceToneOf(MusicSourceKind.localDirectory)),
    );
  });

  test('a source the user brought along falls back to the icon of its kind', () {
    expect(
      sourceIconOf('my_own_source', MusicSourceKind.plugin),
      sourceIconOf('another_one', MusicSourceKind.plugin),
    );
    expect(
      sourceIconOf('my_own_source', MusicSourceKind.plugin),
      isNot(sourceIconOf('another_one', MusicSourceKind.openApi)),
    );
  });
}

Widget _app(SourceLabel label) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: SourceBadge(label: label)),
    ),
  );
}
