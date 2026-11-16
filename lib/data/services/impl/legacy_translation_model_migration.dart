import 'dart:convert';

import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/domain/models/localization_config.dart';
import 'package:tune/utils/logger.dart';

/// Drops the model names the vendor table used to fill in by itself.
///
/// Before the settings page asked the vendor for its model list, the catalog
/// carried one default per vendor and the page wrote it into the credential
/// when the reader opened or switched that vendor. A saved name was therefore
/// not always a choice: for most readers it was the table's stale guess (the
/// `deepseek-chat` of one release, the `gpt-4o-mini` of another).
///
/// This runs once, guarded by the schema of the document. The names below are
/// only what the old table put there, so a name the reader typed, or one
/// picked from a fetched list afterwards, is left alone.
class LegacyTranslationModelMigration {
  const LegacyTranslationModelMigration._();

  /// The settings key that holds the localisation document.
  static const String configKey = 'localization';

  /// What the old catalog filled in, by the id of the vendor.
  static const Map<String, String> _oldDefaults = {
    'openai': 'gpt-4o-mini',
    'anthropic': 'claude-3-5-haiku-latest',
    'gemini': 'gemini-2.0-flash',
    'deepseek': 'deepseek-chat',
    'moonshot': 'moonshot-v1-8k',
    'dashscope': 'qwen-turbo',
    'zhipu': 'glm-4-flash',
    'groq': 'llama-3.1-8b-instant',
    'openrouter': 'openai/gpt-4o-mini',
    'siliconflow': 'Qwen/Qwen2.5-7B-Instruct',
    'ollama': 'qwen2.5:3b',
  };

  /// Removes the old table's model names from [store] and stamps the document
  /// with the current schema, so the cleanup never runs again. A document
  /// that cannot be read is left as it is: a settings file written by a
  /// different version is not a reason to refuse to start.
  static Future<void> migrateInto(PersistenceService store) async {
    final raw = store.getString(configKey);
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final document = Map<String, dynamic>.from(decoded);
      if (document['schema'] == LocalizationConfig.schemaVersion) return;
      final cleaned = _withoutOldDefaults(document) ?? document;
      await store.setString(
        configKey,
        jsonEncode({
          ...cleaned,
          'schema': LocalizationConfig.schemaVersion,
        }),
      );
    } catch (error) {
      Log.debug('没有可清理的旧翻译模型: $error');
    }
  }

  static Map<String, dynamic>? _withoutOldDefaults(
    Map<String, dynamic> document,
  ) {
    final credentials = document['credentials'];
    if (credentials is! Map) return null;

    var changed = false;
    final next = <String, dynamic>{};
    for (final entry in credentials.entries) {
      final id = entry.key.toString();
      final value = entry.value;
      final old = _oldDefaults[id];
      if (value is Map) {
        final model = value['model'];
        if (old != null && model is String && model.trim() == old) {
          next[id] = <String, dynamic>{...value, 'model': ''};
          changed = true;
          continue;
        }
      }
      next[id] = value;
    }
    if (!changed) return null;

    return <String, dynamic>{...document, 'credentials': next};
  }
}
