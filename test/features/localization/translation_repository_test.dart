import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/features/localization/application/translation_repository.dart';
import 'package:tune/features/localization/data/translation_store.dart';
import 'package:tune/features/localization/domain/translation_engine.dart';

void main() {
  test('rows that appear together travel as one batch', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final engine = _FakeEngine();
    final repository = TranslationRepository(
      store: TranslationStore(database),
      engine: engine,
    );
    addTearDown(repository.dispose);

    final results = await Future.wait([
      repository.translate('Blue in Green', 'zh-CN'),
      repository.translate('Kind of Blue', 'zh-CN'),
    ]);

    expect(results, ['译:Blue in Green', '译:Kind of Blue']);
    expect(engine.batches, hasLength(1));
    expect(engine.batches.single, ['Blue in Green', 'Kind of Blue']);
  });

  test('a text asked for twice is translated once', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final engine = _FakeEngine();
    final repository = TranslationRepository(
      store: TranslationStore(database),
      engine: engine,
    );
    addTearDown(repository.dispose);

    final results = await Future.wait([
      repository.translate('Blue in Green', 'zh-CN'),
      repository.translate('Blue in Green', 'zh-CN'),
    ]);

    expect(results, ['译:Blue in Green', '译:Blue in Green']);
    expect(engine.batches.single, ['Blue in Green']);
  });

  test('a text already in the target language is not sent', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final engine = _FakeEngine();
    final repository = TranslationRepository(
      store: TranslationStore(database),
      engine: engine,
    );
    addTearDown(repository.dispose);

    expect(await repository.translate('晴天', 'zh-CN'), isNull);
    expect(engine.calls, 0);
  });

  test('a second session reads the cache instead of the engine', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final first = _FakeEngine();
    final repository = TranslationRepository(
      store: TranslationStore(database),
      engine: first,
    );
    addTearDown(repository.dispose);

    expect(
      await repository.translate('Blue in Green', 'zh-CN'),
      '译:Blue in Green',
    );

    final second = _FakeEngine();
    final reopened = TranslationRepository(
      store: TranslationStore(database),
      engine: second,
    );
    addTearDown(reopened.dispose);

    expect(
      await reopened.translate('Blue in Green', 'zh-CN'),
      '译:Blue in Green',
    );
    expect(second.calls, 0);
  });

  test('an engine that cannot run is not started again', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final engine = _FakeEngine(
      failure: const TranslationException('missing model', unavailable: true),
    );
    final repository = TranslationRepository(
      store: TranslationStore(database),
      engine: engine,
    );
    addTearDown(repository.dispose);

    expect(await repository.translate('Blue in Green', 'zh-CN'), isNull);
    expect(await repository.translate('Kind of Blue', 'zh-CN'), isNull);
    expect(engine.calls, 1);
  });

  test('a failed batch keeps the row on the original text', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final engine = _FakeEngine(failure: const TranslationException('offline'));
    final repository = TranslationRepository(
      store: TranslationStore(database),
      engine: engine,
    );
    addTearDown(repository.dispose);

    expect(await repository.translate('Blue in Green', 'zh-CN'), isNull);
    expect(await repository.translate('Blue in Green', 'zh-CN'), isNull);
    expect(engine.calls, 2);
  });

  test('the tokens of a batch reach the ledger', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    var reported = 0;
    final engine = _FakeEngine(promptTokens: 7, completionTokens: 3);
    final repository = TranslationRepository(
      store: TranslationStore(database),
      engine: engine,
      onUsage: () => reported++,
    );
    addTearDown(repository.dispose);

    await repository.translate('Blue in Green', 'zh-CN');

    final usage = TranslationStore(database).usageSince(0);
    expect(usage.promptTokens, 7);
    expect(usage.completionTokens, 3);
    expect(usage.total, 10);
    expect(reported, 1);
  });
}

class _FakeEngine implements TranslationEngine {
  _FakeEngine({this.failure, this.promptTokens = 0, this.completionTokens = 0});

  final TranslationException? failure;
  final int promptTokens;
  final int completionTokens;

  int calls = 0;
  final List<List<String>> batches = [];

  @override
  String get id => 'fake';

  @override
  Future<TranslationBatch> translate(
    List<String> texts, {
    required String targetLanguage,
  }) async {
    calls++;
    batches.add(List.of(texts));
    final fail = failure;
    if (fail != null) throw fail;
    return TranslationBatch(
      translations: {for (final text in texts) text: '译:$text'},
      promptTokens: promptTokens,
      completionTokens: completionTokens,
    );
  }
}
