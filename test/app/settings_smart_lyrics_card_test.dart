import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/smart_lyrics/whisper_model_store.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_batch_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_ledger_provider.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_sample_provider.dart';
import 'package:tune/features/smart_lyrics/data/smart_lyrics_sample_store.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_ledger.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_sample.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_task.dart';
import 'package:tune/features/smart_lyrics/presentation/settings_smart_lyrics_card.dart';
import 'package:tune/features/smart_lyrics/presentation/settings_smart_lyrics_local_section.dart';
import 'package:tune/l10n/app_localizations.dart';

import '../services/fake_persistence.dart';

/// The store that counts the draws and answers a fixed account, so the
/// card test never opens a database.
class _RecordingStore extends SmartLyricsSampleStore {
  _RecordingStore() : super(database: () => throw UnimplementedError());

  int draws = 0;

  @override
  Future<int> draw({int perLayer = 200, int seed = defaultSampleSeed}) async {
    draws++;
    return 0;
  }

  @override
  Future<SmartLyricsSampleAccount> read() async =>
      SmartLyricsSampleAccount.empty;
}

/// The store the local section downloads through: it records the call and
/// answers the checksum the home would publish, without a network.
class _FakeModelStore extends WhisperModelStore {
  _FakeModelStore() : super(root: Directory('/does/not/exist'));

  final List<String> downloaded = [];

  @override
  Future<String?> checksumOf(String name) async => 'fake-checksum';

  @override
  Future<void> download(
    String name, {
    required String checksum,
    void Function(double progress)? onProgress,
  }) async {
    downloaded.add(name);
  }
}

/// The batch with the presses on record; the figures come from the
/// provider the test hands in.
class _FakeBatchController extends SmartLyricsBatchController {
  int starts = 0;
  int retries = 0;

  @override
  SmartLyricsBatchProgress build() => SmartLyricsBatchProgress.idle;

  @override
  Future<void> start() async {
    starts++;
  }

  @override
  Future<void> retryFailed() async {
    retries++;
  }
}

/// A batch that is on its way right now.
class _RunningBatchController extends SmartLyricsBatchController {
  @override
  SmartLyricsBatchProgress build() => const SmartLyricsBatchProgress(
    running: true,
    currentSongId: 1,
    counts: {SmartLyricsTaskStatus.pending: 1},
  );
}

/// The ledger of the lyrics the library carries, and the key hole the
/// reader pastes theirs into (docs/smart-lyrics.md §7.1, M0+M1).
void main() {
  Future<SettingsController> pumpCard(
    WidgetTester tester, {
    required Future<SmartLyricsLedger> ledger,
    List<Override> extra = const [],
  }) async {
    // The provider owns the controller: it disposes it when the scope
    // unmounts, so the test adds no teardown of its own.
    final controller = SettingsController(FakePersistenceService());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          smartLyricsLedgerProvider.overrideWith((ref) => ledger),
          settingsControllerProvider.overrideWith((ref) => controller),
          ...extra,
        ],
        child: MaterialApp(
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SingleChildScrollView(
            child: SettingsSmartLyricsCard(),
          )),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('the card shows the three counts of the ledger', (tester) async {
    await pumpCard(
      tester,
      ledger: Future.value(const SmartLyricsLedger(total: 400, resolved: 370)),
    );

    expect(find.text('400'), findsOneWidget, reason: 'the whole library');
    expect(find.text('370'), findsOneWidget, reason: 'the tracks with lyrics');
    expect(find.text('30'), findsOneWidget, reason: 'the gap the pipeline fills');
  });

  testWidgets('the card shows the second number of the double figures: the '
      'accuracy of the checked sample rows', (tester) async {
    await pumpCard(
      tester,
      ledger: Future.value(SmartLyricsLedger.empty),
      extra: [
        smartLyricsSampleProvider.overrideWith(
          (ref) => Future.value(
            const SmartLyricsSampleAccount(
              layers: [
                SmartLyricsSampleRow(
                  layer: SmartLyricsLayer.studio,
                  drawn: 400,
                  checked: 2,
                  correct: 1,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    expect(find.text('400'), findsOneWidget, reason: 'the drawn sample');
    expect(find.text('2'), findsOneWidget, reason: 'the checked rows');
    expect(find.text('50.0%'), findsOneWidget,
        reason: 'the rate counts only the checked rows');
  });

  testWidgets('an unchecked sample shows a dash, never a zero', (tester) async {
    await pumpCard(
      tester,
      ledger: Future.value(SmartLyricsLedger.empty),
      extra: [
        smartLyricsSampleProvider.overrideWith(
          (ref) => Future.value(SmartLyricsSampleAccount.empty),
        ),
      ],
    );

    expect(find.text('0.0%'), findsNothing,
        reason: 'nothing drawn is not zero: zero would pretend the question '
            'was asked');
    expect(find.text('-'), findsWidgets);
  });

  testWidgets('the draw button fills the sample through the store', (
    tester,
  ) async {
    final store = _RecordingStore();
    await pumpCard(
      tester,
      ledger: Future.value(SmartLyricsLedger.empty),
      extra: [
        smartLyricsSampleStoreProvider.overrideWithValue(store),
        smartLyricsSampleProvider.overrideWith((ref) => store.read()),
      ],
    );

    await tester.tap(find.text('开始抽样'));
    await tester.pumpAndSettle();

    expect(store.draws, 1);
  });

  testWidgets('a ledger that cannot be read shows itself as unavailable', (
    tester,
  ) async {
    final failing = Completer<SmartLyricsLedger>();
    // The provider listens as soon as the card mounts; `.ignore()` keeps the
    // moment before that from reading as an unhandled error.
    failing.future.ignore();
    failing.completeError(StateError('no database'));
    await pumpCard(tester, ledger: failing.future);

    expect(
      find.textContaining('-'),
      findsWidgets,
      reason: 'missing numbers are dashes, not zeros: zero would lie',
    );
  });

  testWidgets('a key pasted turns the pipeline on at once', (tester) async {
    final controller = await pumpCard(
      tester,
      ledger: Future.value(const SmartLyricsLedger(total: 0, resolved: 0)),
    );

    expect(controller.state.smartLyrics.isConfigured, isTrue,
        reason: 'the local engine ships on — a key is not a toll gate');

    await tester.enterText(
      find.byKey(const Key('smart-lyrics-api-key')),
      'sk-test',
    );

    expect(controller.state.smartLyrics.apiKey, 'sk-test');
    expect(controller.state.smartLyrics.isConfigured, isTrue);
  });

  testWidgets('a preset picked prefills its endpoint and models', (
    tester,
  ) async {
    final controller = await pumpCard(
      tester,
      ledger: Future.value(const SmartLyricsLedger(total: 0, resolved: 0)),
    );

    await tester.tap(find.byKey(const Key('smart-lyrics-preset')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Groq').last,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(controller.state.smartLyrics.presetId, 'groq');
    expect(
      controller.state.smartLyrics.baseUrl,
      'https://api.groq.com/openai/v1',
    );
  });

  testWidgets('the advanced fold keeps its configuration', (tester) async {
    final controller = await pumpCard(
      tester,
      ledger: Future.value(const SmartLyricsLedger(total: 0, resolved: 0)),
    );

    await tester.tap(find.byKey(const Key('smart-lyrics-advanced')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('smart-lyrics-asr-models')),
      'whisper-1, whisper-large-v3',
    );
    await tester.tap(find.byKey(const Key('smart-lyrics-advanced')));
    await tester.pumpAndSettle();

    expect(
      controller.state.smartLyrics.asrModels,
      ['whisper-1', 'whisper-large-v3'],
    );
  });

  testWidgets('the local engine dropdown names the model the channel votes '
      'with', (tester) async {
    final controller = await pumpCard(
      tester,
      ledger: Future.value(SmartLyricsLedger.empty),
    );

    await tester.tap(find.byKey(const Key('smart-lyrics-local-model')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('base'));
    await tester.pumpAndSettle();

    expect(controller.state.smartLyrics.localModel, 'base');
  });

  testWidgets('the download button brings the model home through the store', (
    tester,
  ) async {
    final store = _FakeModelStore();
    await pumpCard(
      tester,
      ledger: Future.value(SmartLyricsLedger.empty),
      extra: [
        whisperModelStoreProvider.overrideWith((ref) => Future.value(store)),
      ],
    );

    await tester.tap(find.byKey(const Key('smart-lyrics-local-model')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('small'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('smart-lyrics-local-download')));
    await tester.pumpAndSettle();

    expect(store.downloaded, ['small']);
    expect(find.text('模型已就绪'), findsOneWidget);
  });

  testWidgets('the batch line says the account and the presses run their '
      'actions', (tester) async {
    final batch = _FakeBatchController();
    await pumpCard(
      tester,
      ledger: Future.value(SmartLyricsLedger.empty),
      extra: [
        smartLyricsBatchControllerProvider.overrideWith(() => batch),
        smartLyricsBatchCountsProvider.overrideWith(
          (ref) => Future.value(const {
            SmartLyricsTaskStatus.pending: 3,
            SmartLyricsTaskStatus.done: 5,
            SmartLyricsTaskStatus.failed: 2,
          }),
        ),
        smartLyricsNewMissingProvider.overrideWith((ref) => Future.value(7)),
      ],
    );

    expect(find.text('待补 3 · 已完成 5 · 失败 2'), findsOneWidget);
    expect(find.textContaining('新增 7 首待补'), findsOneWidget,
        reason: 'a scan brought tracks in; the queue waits for the press');

    await tester.tap(find.byKey(const Key('smart-lyrics-batch-start')));
    await tester.pumpAndSettle();
    expect(batch.starts, 1);

    await tester.tap(find.byKey(const Key('smart-lyrics-batch-retry')));
    await tester.pumpAndSettle();
    expect(batch.retries, 1);
  });

  testWidgets('a batch that is on says so and offers the stop', (tester) async {
    await pumpCard(
      tester,
      ledger: Future.value(SmartLyricsLedger.empty),
      extra: [
        smartLyricsBatchControllerProvider
            .overrideWith(() => _RunningBatchController()),
        smartLyricsBatchCountsProvider.overrideWith(
          (ref) => Future.value(const {
            SmartLyricsTaskStatus.pending: 1,
          }),
        ),
        smartLyricsNewMissingProvider.overrideWith((ref) => Future.value(0)),
      ],
    );

    expect(find.text('正在补齐：待补 1 · 已完成 0'), findsOneWidget);
    expect(find.byKey(const Key('smart-lyrics-batch-stop')), findsOneWidget);
    expect(
      tester.widget<TextButton>(
        find.byKey(const Key('smart-lyrics-batch-start')),
      ).onPressed,
      isNull,
      reason: 'the queue runs; a second press would double it',
    );
  });

  testWidgets('the free check is on, and the reader may turn it off', (
    tester,
  ) async {
    final controller = await pumpCard(
      tester,
      ledger: Future.value(SmartLyricsLedger.empty),
      extra: [
        smartLyricsBatchControllerProvider
            .overrideWith(() => _FakeBatchController()),
        smartLyricsBatchCountsProvider.overrideWith(
          (ref) => Future.value(const {}),
        ),
        smartLyricsNewMissingProvider.overrideWith((ref) => Future.value(0)),
      ],
    );

    expect(controller.state.smartLyrics.gapCheckEnabled, isTrue,
        reason: 'the check converges the ledger on its own — it is on '
            'until the reader says otherwise');

    await tester.tap(find.byKey(const Key('smart-lyrics-gap-check')));
    await tester.pumpAndSettle();

    expect(controller.state.smartLyrics.gapCheckEnabled, isFalse);
  });
}
