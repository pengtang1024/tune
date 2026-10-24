// Benchmark: how many widgets one playback position tick rebuilds, and how
// long that frame takes. Run with:
// flutter test tool/perf/rebuild_bench_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/presentation/now_playing_page.dart';
import 'package:tune/features/shell/presentation/compact_shell.dart';

import '../../test/app/fake_audio_player_service.dart';
import '../../test/app/fake_song_download_service.dart';
import '../../test/app/fake_stream_url_resolver.dart';

const song = Song(
  id: 1,
  title: 'Alpha',
  artist: 'Artist A',
  album: 'Album A',
  duration: 180000,
  uri: '/music/a.mp3',
);

/// Counts the elements that were rebuilt during the frames.
class RebuildCounter {
  final List<String> rebuilt = [];
  bool active = false;

  void call(Element element, bool builtOnce) {
    if (!active) return;
    rebuilt.add(element.widget.runtimeType.toString());
  }
}

Future<PlaybackController> pumpApp(
  WidgetTester tester, {
  required Widget home,
  required FakeAudioPlayerService audio,
}) async {
  final controller = PlaybackController(
    audio,
    FakeSongDownloadService(),
    FakeStreamUrlResolver(),
  );
  await controller.playQueue([song]);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(audio),
        playbackControllerProvider.overrideWith((ref) => controller),
      ],
      child: MaterialApp(
        theme: CompactTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('one position tick rebuilds the shell', (tester) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final counter = RebuildCounter();
    debugOnRebuildDirtyWidget = counter.call;

    await pumpApp(
      tester,
      home: const CompactShell(
        currentPath: '/library',
        child: SizedBox.shrink(),
      ),
      audio: audio,
    );

    counter.active = true;
    audio.emitPosition(const Duration(seconds: 12));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
    await tester.pump();
    counter.active = false;

    final groups = <String, int>{};
    for (final type in counter.rebuilt) {
      groups[type] = (groups[type] ?? 0) + 1;
    }
    final summary = groups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // ignore: avoid_print
    print('shell: rebuilt elements = ${counter.rebuilt.length}');
    for (final entry in summary.take(12)) {
      // ignore: avoid_print
      print('  ${entry.key} x${entry.value}');
    }
    debugOnRebuildDirtyWidget = null;
  });

  testWidgets('one position tick rebuilds the now playing page', (
    tester,
  ) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final counter = RebuildCounter();
    debugOnRebuildDirtyWidget = counter.call;

    await pumpApp(
      tester,
      home: const NowPlayingPage(),
      audio: audio,
    );

    counter.active = true;
    audio.emitPosition(const Duration(seconds: 12));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
    await tester.pump();
    counter.active = false;

    final groups = <String, int>{};
    for (final type in counter.rebuilt) {
      groups[type] = (groups[type] ?? 0) + 1;
    }
    final summary = groups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // ignore: avoid_print
    print('now playing: rebuilt elements = ${counter.rebuilt.length}');
    for (final entry in summary.take(12)) {
      // ignore: avoid_print
      print('  ${entry.key} x${entry.value}');
    }
    debugOnRebuildDirtyWidget = null;
  });

  testWidgets('how long does a position tick frame take', (tester) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);

    await pumpApp(
      tester,
      home: const CompactShell(
        currentPath: '/library',
        child: SizedBox.shrink(),
      ),
      audio: audio,
    );

    // Warm up, then measure 50 ticks, which is what ten seconds of playback
    // costs the app.
    for (var i = 0; i < 5; i++) {
      audio.emitPosition(Duration(seconds: i + 1));
      await tester.pump();
    }

    final sw = Stopwatch()..start();
    for (var i = 0; i < 50; i++) {
      audio.emitPosition(Duration(seconds: 10 + i));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
      await tester.pump();
    }
    sw.stop();
    // ignore: avoid_print
    print(
      '50 position ticks: ${sw.elapsedMilliseconds}ms total, '
      '${(sw.elapsedMicroseconds / 50 / 1000).toStringAsFixed(2)}ms per tick',
    );
  });
}
