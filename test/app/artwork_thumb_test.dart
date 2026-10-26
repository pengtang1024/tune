import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/providers/artwork_cache_provider.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/icon_glyph.dart';

import '../services/fake_artwork_cache.dart';

/// The cover of a track is fetched through the cache, so the same cover is
/// not fetched again after a restart.
void main() {
  testWidgets('the cover comes from the cache', (tester) async {
    final cache = FakeArtworkCache();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [artworkCacheProvider.overrideWithValue(cache)],
        child: const MaterialApp(
          home: ArtworkThumb(
            path: null,
            imageUrl: 'https://example.com/cover.png',
            size: 48,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(cache.asked, ['https://example.com/cover.png']);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('a cover without an address shows the fallback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ArtworkThumb(path: null, imageUrl: null, size: 48),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is IconGlyph && widget.icon == Icons.album_rounded,
      ),
      findsOneWidget,
    );
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('a cover that cannot be fetched shows the fallback', (
    tester,
  ) async {
    final cache = FakeArtworkCache(bytes: Uint8List.fromList([1, 2, 3]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [artworkCacheProvider.overrideWithValue(cache)],
        child: const MaterialApp(
          home: ArtworkThumb(
            path: null,
            imageUrl: 'https://example.com/cover.png',
            size: 48,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is IconGlyph && widget.icon == Icons.album_rounded,
      ),
      findsOneWidget,
    );
  });
}
