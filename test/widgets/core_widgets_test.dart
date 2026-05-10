import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/widgets/empty_state.dart';
import 'package:tune/ui/widgets/modern_card.dart';

void main() {
  group('Song model', () {
    test('fromMap creates valid Song', () {
      final song = Song.fromMap({
        'id': 1,
        'title': 'Test',
        'artist': 'Artist',
        'album': 'Album',
        'duration': 240000,
      });
      expect(song.id, 1);
      expect(song.title, 'Test');
      expect(song.artist, 'Artist');
      expect(song.durationInMillis, 240000);
    });

    test('copyWith preserves unchanged fields', () {
      final song = Song.fromMap({'id': 1, 'title': 'A', 'artist': 'B'});
      final copy = song.copyWith(title: 'C');
      expect(copy.title, 'C');
      expect(copy.artist, 'B');
      expect(copy.id, 1);
    });

    test('named constructor with defaults', () {
      final song = Song(id: 42);
      expect(song.id, 42);
      expect(song.title, '');
      expect(song.isFavorite, false);
    });

    test('equality by id', () {
      final a = Song.fromMap({'id': 1, 'title': 'X'});
      final b = Song.fromMap({'id': 1, 'title': 'Y'});
      expect(a, b);
    });

    test('toJson roundtrip', () {
      final original = Song.fromMap({
        'id': 1, 'title': 'T', 'artist': 'A', 'album': 'B',
        'duration': 1000, 'uri': '/path', 'bitrate': 320,
      });
      final json = original.toJson();
      final restored = Song.fromMap(json);
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.bitrate, original.bitrate);
    });
  });

  group('EmptyState widget', () {
    testWidgets('renders title properly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EmptyState(icon: Icons.music_note, title: '暂无数据'),
            ),
          ),
        ),
      );
      expect(find.text('暂无数据'), findsOneWidget);
    });
  });

  group('ModernCard widget', () {
    testWidgets('responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ModernCard(
                onTap: () => tapped = true,
                child: const Text('Tap me'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tap me'));
      expect(tapped, true);
    });
  });
}
