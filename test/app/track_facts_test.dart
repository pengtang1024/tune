import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/music_sources/built_in_music_sources.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/domain/music_sources_state.dart';
import 'package:tune/features/sources/presentation/music_sources_section.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/shared/ui/meta_chip.dart';
import 'package:tune/shared/ui/track_facts.dart';
import 'package:tune/shared/ui/track_meta.dart';

import '../services/fake_persistence.dart';
import 'compact_layout_test.dart' show FakeLibraryController;
import 'music_sources_section_test.dart' show FakeMusicSourcesController;

/// The facts of a track tell the reader what the track is.
///
/// The row shows the format and the quality of a track at a glance, and the
/// details sheet names every fact the source published.
void main() {
  const lossless = Song(
    id: 1,
    title: '夜曲',
    artist: '某歌手',
    album: '夜曲专辑',
    duration: 245000,
    uri: '/music/night.flac',
    year: 2024,
    genre: '流行',
    bitrate: 980,
    sampleRate: 96000,
    trackNumber: 3,
    trackTotal: 12,
    license: 'CC-BY',
    language: 'zh',
    size: 38000000,
    lyrics: '[00:00.00] 歌词',
    dateAdded: 1700000000000,
  );

  const remote = Song(
    id: 2,
    title: '远方的歌',
    artist: '远方歌手',
    duration: 10000,
    uri: 'tune://openverse/abc',
    sourceId: 'openverse',
    externalId: 'abc',
    streamUrl: 'https://example.com/a.mp3',
    bitrate: 192,
  );

  Widget app(Widget home) {
    return MaterialApp(
      theme: CompactTheme.light,
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: home),
    );
  }

  testWidgets('a row names the format and the bitrate of a track', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const TrackMeta(song: lossless, index: 0),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('格式 · FLAC'), findsOneWidget);
    expect(find.byTooltip('码率 · 980 kbps'), findsOneWidget);
    expect(find.text('夜曲'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a row keeps the words of a fact in the tooltip', (tester) async {
    await tester.pumpWidget(
      app(
        const TrackMeta(song: lossless, index: 0),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FLAC'), findsNothing);
    expect(find.text('980 kbps'), findsNothing);
    expect(find.byIcon(Icons.audio_file_rounded), findsOneWidget);
    expect(find.byIcon(Icons.speed_rounded), findsOneWidget);
  });

  testWidgets('a row keeps the state of a live stream', (tester) async {
    const live = Song(
      id: 3,
      title: '电台',
      artist: '电台',
      uri: 'tune://radio/one',
      sourceId: 'radio',
      isLiveStream: true,
    );

    await tester.pumpWidget(
      app(
        const TrackMeta(song: live, index: 0),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('直播中'), findsOneWidget);
    expect(find.byIcon(Icons.podcasts_rounded), findsOneWidget);
  });

  testWidgets('the details sheet names every fact of a track', (tester) async {
    await tester.pumpWidget(
      app(
        const TrackMeta(song: lossless, index: 0),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('查看详情'));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    expect(find.descendant(of: sheet, matching: find.text('格式')), findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('码率')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('采样率')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('专辑')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('许可')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('FLAC')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('980 kbps')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('96 kHz')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.text('/music/night.flac'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the details sheet tells a remote track from a local one', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const TrackMeta(song: remote, index: 0),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('查看详情'));
    await tester.pumpAndSettle();

    expect(find.text('在线'), findsOneWidget);
    expect(find.text('位置'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a track that was fetched is marked local and remote', (
    tester,
  ) async {
    // The copy on the disk keeps the identity of the track it belongs to, so
    // the row says both: the track comes from a source and it is here.
    const copy = Song(
      id: 2,
      title: '远方的歌',
      artist: '远方歌手',
      uri: 'tune://openverse/abc',
      sourceId: 'openverse',
      externalId: 'abc',
      streamUrl: 'https://example.com/a.mp3',
      localPath: '/music/远方歌手/远方的歌/远方的歌.mp3',
    );

    await tester.pumpWidget(
      app(
        const TrackMeta(song: copy, index: 0),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('位置 · 本地 · 在线'), findsOneWidget);
    expect(find.byIcon(Icons.sd_storage_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the details of a fetched track name the file and the address', (
    tester,
  ) async {
    // The track knows the file of its copy and the address of its source, so
    // the details sheet writes both down.
    const copy = Song(
      id: 2,
      title: '远方的歌',
      artist: '远方歌手',
      uri: 'tune://openverse/abc',
      sourceId: 'openverse',
      externalId: 'abc',
      streamUrl: 'https://example.com/a.mp3',
      localPath: '/music/远方歌手/远方的歌/远方的歌.mp3',
    );

    await tester.pumpWidget(
      app(
        const TrackMeta(song: copy, index: 0),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('查看详情'));
    await tester.pumpAndSettle();

    expect(find.text('文件路径'), findsOneWidget);
    expect(find.text('/music/远方歌手/远方的歌/远方的歌.mp3'), findsOneWidget);
    expect(find.text('地址'), findsOneWidget);
    expect(find.text('https://example.com/a.mp3'), findsOneWidget);
    // The identity of the track names the track, it is not a path of a file,
    // so it gets a row of its own.
    expect(find.text('身份'), findsOneWidget);
    expect(find.text('tune://openverse/abc'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the details sheet name how long a track lasts', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const TrackMeta(song: lossless, index: 0),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('查看详情'));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('时长')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('4:05')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the details sheet name the number of a track in its source', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const TrackMeta(song: remote, index: 0),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('查看详情'));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('来源编号')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('abc')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the details sheet write the cover of a track out', (
    tester,
  ) async {
    const withCover = Song(
      id: 4,
      title: '有封面的歌',
      artist: '某歌手',
      uri: 'tune://openverse/cover',
      sourceId: 'openverse',
      externalId: 'cover',
      streamUrl: 'https://example.com/cover.mp3',
      artworkUrl: 'https://example.com/cover.jpg',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: app(
          const TrackMeta(song: withCover, index: 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('查看详情'));
    await tester.pumpAndSettle();

    expect(find.text('封面'), findsOneWidget);
    expect(find.text('https://example.com/cover.jpg'), findsOneWidget);
    expect(find.text('身份'), findsOneWidget);
    expect(find.text('tune://openverse/cover'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the details sheet write the words of the lyrics out', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const TrackMeta(song: lossless, index: 0),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('查看详情'));
    await tester.pumpAndSettle();

    // The mark says that the lyrics are there, the words are written out.
    expect(find.text('已包含'), findsOneWidget);
    expect(find.text('[00:00.00] 歌词'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the details sheet write the payload of the source out', (
    tester,
  ) async {
    const withPayload = Song(
      id: 5,
      title: '带数据的歌',
      artist: '某歌手',
      uri: 'tune://subsonic/one',
      sourceId: 'subsonic',
      externalId: 'one',
      streamUrl: 'https://example.com/one.mp3',
      sourceData: {'id': 'one', 'suffix': 'mp3'},
    );

    await tester.pumpWidget(
      app(
        const TrackMeta(song: withPayload, index: 0),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('查看详情'));
    await tester.pumpAndSettle();

    expect(find.text('原始数据'), findsOneWidget);
    expect(find.text('id: one\nsuffix: mp3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the details sheet keep a secret header out of sight', (
    tester,
  ) async {
    const withHeaders = Song(
      id: 6,
      title: '带请求头的歌',
      artist: '某歌手',
      uri: 'tune://jellyfin/one',
      sourceId: 'jellyfin',
      externalId: 'one',
      streamUrl: 'https://example.com/one.mp3',
      httpHeaders: {'Referer': 'https://example.com/', 'X-Emby-Token': 'secret'},
    );

    await tester.pumpWidget(
      app(
        const TrackMeta(song: withHeaders, index: 0),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('查看详情'));
    await tester.pumpAndSettle();

    expect(find.text('请求头'), findsOneWidget);
    expect(
      find.text('Referer: https://example.com/\nX-Emby-Token: •••'),
      findsOneWidget,
    );
    expect(find.textContaining('secret'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the details of a fetched track know the format of the file', (
    tester,
  ) async {
    // The file on this machine knows its own format, even when the identity
    // of the track is the address of a source.
    const copy = Song(
      id: 2,
      title: '远方的歌',
      artist: '远方歌手',
      uri: 'tune://openverse/abc',
      sourceId: 'openverse',
      externalId: 'abc',
      streamUrl: 'https://example.com/a.mp3',
      localPath: '/music/远方歌手/远方的歌/远方的歌.mp3',
    );

    await tester.pumpWidget(
      app(
        const TrackMeta(song: copy, index: 0),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('查看详情'));
    await tester.pumpAndSettle();

    expect(find.text('格式'), findsOneWidget);
    expect(find.text('MP3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the details sheet closes when the reader taps outside it', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const TrackMeta(song: lossless, index: 0),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('查看详情'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);

    // The room above the sheet belongs to the barrier, so a tap there closes
    // the sheet instead of being swallowed by the empty part of it.
    await tester.tapAt(const Offset(400, 40));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tap on the details sheet keeps it open', (tester) async {
    await tester.pumpWidget(
      app(
        const TrackMeta(song: lossless, index: 0),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('查看详情'));
    await tester.pumpAndSettle();

    final title = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text('夜曲'),
    );
    await tester.tapAt(tester.getCenter(title));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a chip that shows a value keeps the name of the fact away', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const MetaChip(value: 'FLAC', tooltip: '格式 · FLAC')),
    );
    await tester.pumpAndSettle();

    expect(find.text('FLAC'), findsOneWidget);
    expect(find.text('格式'), findsNothing);
    expect(find.byTooltip('格式 · FLAC'), findsOneWidget);
  });

  testWidgets('a chip that names a fact shows the name and the value', (
    tester,
  ) async {
    await tester.pumpWidget(app(const MetaChip(label: '格式', value: 'FLAC')));
    await tester.pumpAndSettle();

    expect(find.text('格式'), findsOneWidget);
    expect(find.text('FLAC'), findsOneWidget);
  });

  testWidgets('the state of a source is a chip and its numbers wait in the tip', (
    tester,
  ) async {
    final scannedAt = DateTime(2024, 5, 4, 14, 30);
    // A scan of another day is written out with its date, the same way the
    // tile writes it.
    final clock =
        '${DateFormat.yMMMd('zh_CN').format(scannedAt)} '
        '${DateFormat.jm('zh_CN').format(scannedAt)}';
    final persistence = FakePersistenceService()..values['language_code'] = 'zh';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          persistenceServiceProvider.overrideWithValue(persistence),
          musicSourcesControllerProvider.overrideWith(
            () => FakeMusicSourcesController(
              MusicSourcesState(
                sources: [BuiltInMusicSources.openverse],
                lastScanAt: {'openverse': scannedAt},
              ),
            ),
          ),
          libraryControllerProvider.overrideWith(
            () => FakeLibraryController(
              LibraryState(
                sourceSummaries: {
                  'openverse': SourceScanSummary(
                    sourceId: 'openverse',
                    status: SourceScanStatus.success,
                    songCount: 12,
                    scannedAt: scannedAt,
                  ),
                },
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: CompactTheme.light,
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: MusicSourcesSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The state is an icon like every other mark of a row; the words wait
    // in the tooltip.
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    expect(find.byTooltip(RegExp('已扫描')), findsOneWidget);
    expect(find.byTooltip('曲目 · 12'), findsOneWidget);
    expect(find.byTooltip('上次扫描 · $clock'), findsOneWidget);
    expect(find.text('曲目'), findsNothing);
    expect(find.text('已扫描'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('the format of a track is the format of its file', () {
    // A scanned file says only that it is audio; the name of the file says
    // what it is.
    const scanned = Song(
      id: 1,
      uri: '/music/night.flac',
      type: 'audio',
    );
    const fetched = Song(
      id: 2,
      uri: 'tune://openverse/abc',
      streamUrl: 'https://example.com/a.mp3',
      localPath: '/music/远方歌手/远方的歌/远方的歌.mp3',
    );

    expect(formatOf(scanned), 'FLAC');
    expect(formatOf(fetched), 'MP3');
    // A track of a source without a file has no format of its own.
    expect(formatOf(remote), isNull);
  });
}
