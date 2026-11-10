import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/app_shortcuts.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/side_panel_host.dart';

import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

/// Guards the keys that play the player from anywhere.
///
/// The shortcuts sit above the router, so what the tests must prove is the
/// opposite side: the keys step aside when the reader is typing, when a
/// dialog is open and when a panel owns the keyboard.
const song = Song(
  id: 1,
  title: 'Song',
  artist: 'Artist',
  duration: 60000,
  uri: '/music/song.mp3',
);

const secondSong = Song(
  id: 2,
  title: 'Second',
  artist: 'Artist',
  duration: 60000,
  uri: '/music/second.mp3',
);

Future<PlaybackController> _pumpApp(
  WidgetTester tester,
  Widget home, {
  List<Song> queue = const [song],
}) async {
  final audio = FakeAudioPlayerService();
  addTearDown(audio.dispose);
  final playback = PlaybackController(
    audio,
    FakeSongDownloadService(),
    FakeStreamUrlResolver(),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(audio),
        playbackControllerProvider.overrideWith((ref) => playback),
      ],
      child: MaterialApp(
        theme: CompactTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            AppShortcuts(child: child ?? const SizedBox.shrink()),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await playback.playQueue(queue);
  await tester.pumpAndSettle();
  return playback;
}

void main() {
  testWidgets('the space bar pauses and resumes the track', (tester) async {
    final playback = await _pumpApp(
      tester,
      const Scaffold(body: SizedBox.expand()),
    );

    expect(playback.state.isPlaying, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(playback.state.isPlaying, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(playback.state.isPlaying, isTrue);
  });

  testWidgets('a space typed into the search box does not pause', (
    tester,
  ) async {
    final playback = await _pumpApp(
      tester,
      const Scaffold(
        body: Center(child: SizedBox(width: 320, child: TextField())),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>(),
      isNotNull,
      reason: 'the tap puts the focus in the field, not on the shortcuts',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(playback.state.isPlaying, isTrue);
  });

  testWidgets('a dialog keeps the keys while it is open', (tester) async {
    final playback = await _pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => const AlertDialog(
                  content: Focus(
                    autofocus: true,
                    child: SizedBox(width: 20, height: 20),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(playback.state.isPlaying, isTrue);
  });

  testWidgets('a panel over the page keeps the keys', (tester) async {
    final playback = await _pumpApp(
      tester,
      Scaffold(
        body: SidePanelHost(
          open: true,
          onClose: () {},
          barrierLabel: 'close',
          child: const SizedBox.expand(),
          panelBuilder: (context) => const SizedBox.expand(),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(playback.state.isPlaying, isTrue);
  });

  testWidgets('the arrows skip through the queue', (tester) async {
    final playback = await _pumpApp(
      tester,
      const Scaffold(body: SizedBox.expand()),
      queue: const [song, secondSong],
    );

    expect(playback.state.currentUri, song.uri);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(playback.state.currentUri, secondSong.uri);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(playback.state.currentUri, song.uri);
  });

  testWidgets('a slider keeps the arrows while it has the focus', (
    tester,
  ) async {
    final sliderFocus = FocusNode();
    addTearDown(sliderFocus.dispose);

    final playback = await _pumpApp(
      tester,
      Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: Slider(
              value: 0.5,
              focusNode: sliderFocus,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
      queue: const [song, secondSong],
    );

    sliderFocus.requestFocus();
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<Slider>(),
      isNotNull,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    expect(playback.state.currentUri, song.uri);
  });

  testWidgets('the M key mutes and unmutes', (tester) async {
    final playback = await _pumpApp(
      tester,
      const Scaffold(body: SizedBox.expand()),
    );

    expect(playback.state.volume, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pumpAndSettle();
    expect(playback.state.volume, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pumpAndSettle();
    expect(playback.state.volume, 1);
  });
}
