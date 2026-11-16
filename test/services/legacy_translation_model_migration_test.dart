import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/impl/legacy_translation_model_migration.dart';
import 'package:tune/domain/models/localization_config.dart';

import 'fake_persistence.dart';

void main() {
  Map<String, dynamic> document() => <String, dynamic>{
    'enabled': true,
    'showOriginal': true,
    'privacyAccepted': true,
    'backendId': 'deepseek',
    'localTier': '',
    'credentials': <String, dynamic>{
      'deepseek': <String, dynamic>{
        'apiKey': '',
        'model': 'deepseek-chat',
        'baseUrl': '',
      },
      'openai': <String, dynamic>{
        'apiKey': '',
        'model': 'gpt-4o-mini',
        'baseUrl': '',
      },
      'custom': <String, dynamic>{
        'apiKey': '',
        'model': 'my-endpoint-model',
        'baseUrl': 'https://example.test/v1',
      },
    },
  };

  FakePersistenceService storeWith(Map<String, dynamic> value) {
    final store = FakePersistenceService();
    store.values[LegacyTranslationModelMigration.configKey] = jsonEncode(value);
    return store;
  }

  Map<String, dynamic> documentOf(FakePersistenceService store) =>
      jsonDecode(
            store.getString(LegacyTranslationModelMigration.configKey)!,
          )
          as Map<String, dynamic>;

  Map<String, dynamic> credentialsOf(FakePersistenceService store) =>
      documentOf(store)['credentials'] as Map<String, dynamic>;

  test('drops only the names the old table filled in', () async {
    final store = storeWith(document());

    await LegacyTranslationModelMigration.migrateInto(store);

    final credentials = credentialsOf(store);
    expect((credentials['deepseek'] as Map)['model'], '');
    expect((credentials['openai'] as Map)['model'], '');
    expect((credentials['custom'] as Map)['model'], 'my-endpoint-model');
    expect(
      documentOf(store)['schema'],
      LocalizationConfig.schemaVersion,
    );
  });

  test('keeps a model the reader typed', () async {
    final value = document();
    (value['credentials'] as Map)['deepseek'] = <String, dynamic>{
      'apiKey': 'sk-test',
      'model': 'deepseek-flash',
      'baseUrl': '',
    };
    final store = storeWith(value);

    await LegacyTranslationModelMigration.migrateInto(store);

    expect(
      (credentialsOf(store)['deepseek'] as Map)['model'],
      'deepseek-flash',
    );
  });

  test('runs once: a name picked afterwards is kept', () async {
    final store = storeWith(document());
    await LegacyTranslationModelMigration.migrateInto(store);

    final raw = documentOf(store);
    ((raw['credentials'] as Map)['deepseek'] as Map)['model'] =
        'deepseek-chat';
    store.values[LegacyTranslationModelMigration.configKey] = jsonEncode(raw);

    await LegacyTranslationModelMigration.migrateInto(store);

    expect((credentialsOf(store)['deepseek'] as Map)['model'], 'deepseek-chat');
  });

  test('leaves a broken document alone', () async {
    final store = FakePersistenceService();
    store.values[LegacyTranslationModelMigration.configKey] = 'not json';

    await LegacyTranslationModelMigration.migrateInto(store);

    expect(
      store.getString(LegacyTranslationModelMigration.configKey),
      'not json',
    );
  });

  test('a document without a localisation section is left alone', () async {
    final store = FakePersistenceService();

    await LegacyTranslationModelMigration.migrateInto(store);

    expect(store.getKeys(), isEmpty);
  });
}
