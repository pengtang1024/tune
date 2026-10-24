import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/music_sources/built_in_music_sources.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/application/source_health_reports.dart';
import 'package:tune/features/sources/domain/music_sources_state.dart';
import 'package:tune/features/sources/domain/source_health.dart';
import 'package:tune/features/sources/presentation/music_sources_section.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';
import '../services/fake_persistence.dart';

void main() {
  late FakePersistenceService persistence;

  setUp(() {
    // The page renders in Chinese, so the settings that drive the language
    // of the app have to be in Chinese too. Every test gets its own
    // preferences, so one test does not fold the group for the next.
    persistence = FakePersistenceService()..values['language_code'] = 'zh';
  });

  Widget app(
    FakeMusicSourcesController controller, {
    Map<String, SourceHealthReport>? health,
  }) {
    return ProviderScope(
      overrides: [
        persistenceServiceProvider.overrideWithValue(persistence),
        musicSourcesControllerProvider.overrideWith(() => controller),
        if (health != null)
          sourceHealthReportsProvider.overrideWithValue(health),
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
    );
  }

  /// Opens the group of the sources that need a key.
  Future<void> openMoreSources(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('sources-more-toggle')));
    await tester.pumpAndSettle();
  }

  testWidgets('unconfigured source only enables after saving settings', (
    tester,
  ) async {
    final controller = FakeMusicSourcesController(
      MusicSourcesState(sources: [BuiltInMusicSources.jamendo]),
    );

    await tester.pumpWidget(app(controller));
    await tester.pumpAndSettle();

    // An unconfigured source is unhealthy, so it waits in the folded group.
    await openMoreSources(tester);

    final sourceSwitch = find.byKey(const ValueKey('source-switch-jamendo'));
    expect(tester.widget<Switch>(sourceSwitch).value, isFalse);

    await tester.tap(sourceSwitch);
    await tester.pumpAndSettle();
    expect(find.text('配置 Jamendo'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(controller.enabledChanges, isEmpty);
    expect(tester.widget<Switch>(sourceSwitch).value, isFalse);

    await tester.tap(sourceSwitch);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'client-id');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(controller.settingsChanges['jamendo']?['clientId'], 'client-id');
    expect(controller.enabledChanges, [true]);
    expect(tester.widget<Switch>(sourceSwitch).value, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the new sources render and mask the Subsonic password', (
    tester,
  ) async {
    final controller = FakeMusicSourcesController(
      MusicSourcesState(
        sources: [
          BuiltInMusicSources.ccmixter,
          BuiltInMusicSources.itunes,
          BuiltInMusicSources.podcastRss,
          BuiltInMusicSources.subsonic,
        ],
      ),
    );

    await tester.pumpWidget(app(controller));
    await tester.pumpAndSettle();

    // The sources that need a key wait in the folded group.
    await openMoreSources(tester);

    // Every new source is listed with its own switch.
    for (final id in ['ccmixter', 'itunes', 'podcast_rss', 'subsonic']) {
      expect(
        find.byKey(ValueKey('source-switch-$id')),
        findsOneWidget,
        reason: '$id is missing from the sources list',
      );
    }
    expect(find.text('ccMixter'), findsOneWidget);
    expect(find.text('iTunes'), findsOneWidget);
    expect(find.text('Subsonic'), findsOneWidget);
    expect(find.text('播客订阅'), findsOneWidget);

    // An unconfigured source asks for its settings before it can be enabled.
    final subsonicSwitch = find.byKey(const ValueKey('source-switch-subsonic'));
    await tester.ensureVisible(subsonicSwitch);
    await tester.pumpAndSettle();
    await tester.tap(subsonicSwitch);
    await tester.pumpAndSettle();

    expect(find.text('配置 Subsonic'), findsOneWidget);
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();

    // server, user, password, query, limit
    expect(fields, hasLength(5));

    Finder fieldWithLabel(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );

    // The password is masked, the other fields stay readable.
    expect(tester.widget<TextField>(fieldWithLabel('密码')).obscureText, isTrue);
    expect(
      tester.widget<TextField>(fieldWithLabel('服务器地址')).obscureText,
      isFalse,
    );
    expect(
      tester.widget<TextField>(fieldWithLabel('用户名')).obscureText,
      isFalse,
    );

    // Typing a password keeps it masked.
    await tester.enterText(fieldWithLabel('密码'), 'secret');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(fieldWithLabel('密码')).obscureText, isTrue);
    expect(
      tester.widget<TextField>(fieldWithLabel('密码')).controller?.text,
      'secret',
    );

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the new sources render their own fields', (tester) async {
    final controller = FakeMusicSourcesController(
      MusicSourcesState(
        sources: [
          BuiltInMusicSources.audius,
          BuiltInMusicSources.radio,
          BuiltInMusicSources.wikimedia,
          BuiltInMusicSources.jellyfin,
        ],
      ),
    );

    await tester.pumpWidget(app(controller));
    await tester.pumpAndSettle();

    // Jellyfin asks for an account, so it waits in the folded group.
    await openMoreSources(tester);

    for (final id in ['audius', 'radio', 'wikimedia', 'jellyfin']) {
      expect(
        find.byKey(ValueKey('source-switch-$id')),
        findsOneWidget,
        reason: '$id is missing from the sources list',
      );
    }
    expect(find.text('Audius'), findsOneWidget);
    expect(find.text('网络电台'), findsOneWidget);
    expect(find.text('Wikimedia Commons'), findsOneWidget);
    expect(find.text('Jellyfin'), findsOneWidget);

    // The self-hosted library asks for its address and its account.
    final jellyfinConfig = find.byKey(const ValueKey('source-config-jellyfin'));
    await tester.ensureVisible(jellyfinConfig);
    await tester.pumpAndSettle();
    await tester.tap(jellyfinConfig);
    await tester.pumpAndSettle();

    expect(find.text('配置 Jellyfin'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the radio source picks its directory in a dropdown', (
    tester,
  ) async {
    final controller = FakeMusicSourcesController(
      MusicSourcesState(sources: [BuiltInMusicSources.radio]),
    );

    await tester.pumpWidget(app(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('source-config-radio')));
    await tester.pumpAndSettle();

    expect(find.text('配置 网络电台'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.text('全部目录'), findsOneWidget);

    await tester.tap(find.text('全部目录'));
    await tester.pumpAndSettle();

    expect(find.text('Radio Browser'), findsOneWidget);
    expect(find.text('SomaFM'), findsOneWidget);
    expect(find.text('Radio Paradise'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the quality of a source is picked in a dropdown', (
    tester,
  ) async {
    final controller = FakeMusicSourcesController(
      MusicSourcesState(sources: [BuiltInMusicSources.subsonic]),
    );

    await tester.pumpWidget(app(controller));
    await tester.pumpAndSettle();

    await openMoreSources(tester);

    await tester.tap(find.byKey(const ValueKey('source-config-subsonic')));
    await tester.pumpAndSettle();

    expect(find.text('配置 Subsonic'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.text('原始音质'), findsOneWidget);

    await tester.tap(find.text('原始音质'));
    await tester.pumpAndSettle();

    expect(find.text('MP3'), findsOneWidget);
    expect(find.text('Opus'), findsOneWidget);
    expect(find.text('FLAC'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the sources that need no key stand at the top', (tester) async {
    final controller = FakeMusicSourcesController(
      MusicSourcesState(
        sources: [
          BuiltInMusicSources.ccmixter,
          BuiltInMusicSources.itunes,
          BuiltInMusicSources.subsonic,
        ],
      ),
    );

    await tester.pumpWidget(app(controller));
    await tester.pumpAndSettle();

    // The source that asks nothing of the reader is there; the ones that
    // need a key wait in the folded group.
    expect(
      find.byKey(const ValueKey('source-switch-ccmixter')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('source-switch-itunes')), findsNothing);
    expect(find.byKey(const ValueKey('source-switch-subsonic')), findsNothing);
    expect(find.text('更多音源'), findsOneWidget);
    expect(find.text('我添加的'), findsNothing);
  });

  testWidgets('the folded group opens once and stays open', (tester) async {
    final controller = FakeMusicSourcesController(
      MusicSourcesState(
        sources: [BuiltInMusicSources.ccmixter, BuiltInMusicSources.itunes],
      ),
    );

    await tester.pumpWidget(app(controller));
    await tester.pumpAndSettle();

    await openMoreSources(tester);

    expect(
      find.byKey(const ValueKey('source-switch-ccmixter')),
      findsOneWidget,
    );
    expect(persistence.getBool('sources_more_expanded'), isTrue);
  });

  testWidgets('a source the reader added joins the weighted list', (
    tester,
  ) async {
    final controller = FakeMusicSourcesController(
      MusicSourcesState(
        sources: [
          BuiltInMusicSources.ccmixter,
          const MusicSourceConfig(
            id: 'podcast_rss:1',
            type: 'podcast_rss',
            name: '我的播客',
            kind: MusicSourceKind.custom,
            settings: {'feed': 'https://example.com/feed'},
          ),
        ],
      ),
    );

    await tester.pumpWidget(app(controller));
    await tester.pumpAndSettle();

    expect(find.text('我添加的'), findsNothing);
    expect(find.text('我的播客'), findsOneWidget);

    // The source of the reader is not folded away with the ones that need
    // a key.
    expect(find.text('更多音源'), findsNothing);
  });

  testWidgets('a higher health band stands before a higher weight', (
    tester,
  ) async {
    final controller = FakeMusicSourcesController(
      MusicSourcesState(
        sources: [
          BuiltInMusicSources.ccmixter.copyWith(weight: 800),
          BuiltInMusicSources.openverse.copyWith(weight: 700),
        ],
      ),
    );
    SourceHealthReport report(int score) => SourceHealthReport(
      availability: 100,
      configuration: 100,
      scan: 100,
      freshness: 100,
      output: 100,
      speed: 100,
      reliability: 100,
      stability: 100,
      playable: 100,
      artwork: 100,
      metadata: 100,
      activity: 100,
      score: score,
      healthy: score >= SourceHealth.threshold,
    );

    await tester.pumpWidget(
      app(
        controller,
        health: {'ccmixter': report(65), 'openverse': report(90)},
      ),
    );
    await tester.pumpAndSettle();

    final high = tester
        .getTopLeft(find.byKey(const ValueKey('source-switch-openverse')))
        .dy;
    final low = tester
        .getTopLeft(find.byKey(const ValueKey('source-switch-ccmixter')))
        .dy;

    // openverse has the lower weight but the higher health band.
    expect(high, lessThan(low));
  });

  testWidgets('the weight decides which group a source joins', (tester) async {
    final controller = FakeMusicSourcesController(
      MusicSourcesState(
        sources: [
          BuiltInMusicSources.openverse.copyWith(weight: 400),
          BuiltInMusicSources.ccmixter.copyWith(weight: 800),
        ],
      ),
    );

    await tester.pumpWidget(app(controller));
    await tester.pumpAndSettle();

    // The high weight stands in the main list, the low one waits folded.
    expect(
      find.byKey(const ValueKey('source-switch-ccmixter')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('source-switch-openverse')), findsNothing);
    expect(find.text('更多音源'), findsOneWidget);

    await openMoreSources(tester);
    expect(
      find.byKey(const ValueKey('source-switch-openverse')),
      findsOneWidget,
    );

    // The menu of a built-in source offers the order actions, but no delete.
    await tester.tap(find.byKey(const ValueKey('source-menu-ccmixter')));
    await tester.pumpAndSettle();
    expect(find.text('上移'), findsOneWidget);
    expect(find.text('下移'), findsOneWidget);
    expect(find.text('移到更多音源'), findsOneWidget);
    expect(find.text('删除'), findsNothing);
  });
}

class FakeMusicSourcesController extends MusicSourcesController {
  FakeMusicSourcesController(this.seed);

  final MusicSourcesState seed;
  final List<bool> enabledChanges = [];
  final Map<String, Map<String, String>> settingsChanges = {};

  @override
  Future<MusicSourcesState> build() async => seed;

  @override
  Future<void> setEnabled(String sourceId, bool enabled) async {
    enabledChanges.add(enabled);
    final current = state.valueOrNull ?? seed;
    state = AsyncData(
      current.copyWith(
        sources: [
          for (final source in current.sources)
            source.id == sourceId ? source.copyWith(enabled: enabled) : source,
        ],
      ),
    );
  }

  @override
  Future<void> updateSettings(
    String sourceId,
    Map<String, String> settings, {
    String? name,
  }) async {
    settingsChanges[sourceId] = Map.of(settings);
    final current = state.valueOrNull ?? seed;
    state = AsyncData(
      current.copyWith(
        sources: [
          for (final source in current.sources)
            source.id == sourceId
                ? source.copyWith(settings: Map.unmodifiable(settings))
                : source,
        ],
      ),
    );
  }
}
