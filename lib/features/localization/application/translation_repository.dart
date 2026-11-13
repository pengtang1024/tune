import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:tune/domain/models/translation_cache.dart';
import 'package:tune/features/localization/data/translation_store.dart';
import 'package:tune/features/localization/domain/text_language.dart';
import 'package:tune/domain/models/translation_engine.dart';

/// Reads and writes translations behind one in-memory map.
///
/// A row that appears on screen asks for its text; the rows that appear
/// together are collected into one batch, so a viewport does not start one
/// model process per line. The map is filled from the database once per
/// target language, which keeps the first frame of a cached row synchronous.
class TranslationRepository {
  TranslationRepository({
    required this.store,
    required this.engine,
    this.onUsage,
  });

  final TranslationStore store;
  final TranslationEngine engine;

  /// Called after a batch reported tokens, so the settings page can refresh
  /// the ledger without polling the database.
  final void Function()? onUsage;

  static const int batchSize = 12;

  final Map<String, String> _cache = {};
  final Map<String, Future<void>> _loading = {};
  final Set<String> _loaded = {};
  final Map<String, Completer<String?>> _waiting = {};
  final List<_PendingText> _queue = [];
  Timer? _timer;
  bool _flushing = false;
  bool _unavailable = false;

  /// The translation of [text], or `null` when it needs none or none arrived.
  Future<String?> translate(String text, String targetLanguage) async {
    final normalized = normalizeTranslatableText(text);
    if (!needsTranslation(normalized, targetLanguage)) return null;
    if (_unavailable) return null;

    final hash = _hash(normalized);
    final key = _key(targetLanguage, hash);
    final cached = _cache[key];
    if (cached != null) return cached;

    await _load(targetLanguage);
    final loaded = _cache[key];
    if (loaded != null) return loaded;

    final pending = _waiting[key];
    if (pending != null) return pending.future;

    final completer = Completer<String?>();
    _waiting[key] = completer;
    _queue.add(
      _PendingText(
        key: key,
        hash: hash,
        text: normalized,
        targetLanguage: targetLanguage,
        completer: completer,
      ),
    );
    _schedule();
    return completer.future;
  }

  /// Stops waiting on the queue; the rows that were pending show the original.
  void dispose() {
    _timer?.cancel();
    _timer = null;
    for (final item in _queue) {
      item.completer.complete(null);
    }
    for (final completer in _waiting.values) {
      if (!completer.isCompleted) completer.complete(null);
    }
    _queue.clear();
    _waiting.clear();
  }

  Future<void> _load(String targetLanguage) {
    if (_loaded.contains(targetLanguage)) return Future.value();
    final running = _loading[targetLanguage];
    if (running != null) return running;
    final future = _read(targetLanguage);
    _loading[targetLanguage] = future;
    return future;
  }

  Future<void> _read(String targetLanguage) async {
    final rows = store.readHashes(
      targetLanguage: targetLanguage,
      engine: engine.id,
    );
    rows.forEach((hash, value) {
      _cache[_key(targetLanguage, hash)] = value;
    });
    _loaded.add(targetLanguage);
    _loading.remove(targetLanguage);
  }

  void _schedule() {
    _timer ??= Timer(const Duration(milliseconds: 40), () {
      _timer = null;
      unawaited(_flush());
    });
  }

  Future<void> _flush() async {
    if (_flushing || _queue.isEmpty) return;
    _flushing = true;
    try {
      while (_queue.isNotEmpty) {
        final target = _queue.first.targetLanguage;
        final batch = <_PendingText>[];
        for (final item in _queue) {
          if (item.targetLanguage == target && batch.length < batchSize) {
            batch.add(item);
          }
        }
        _queue.removeWhere(batch.contains);
        await _runBatch(batch, target);
      }
    } finally {
      _flushing = false;
      if (_queue.isNotEmpty) _schedule();
    }
  }

  Future<void> _runBatch(List<_PendingText> batch, String target) async {
    if (batch.isEmpty) return;
    try {
      final result = await engine.translate([
        for (final item in batch) item.text,
      ], targetLanguage: target);
      final entries = <TranslationCacheEntry>[];
      for (final item in batch) {
        final value = result.translations[item.text];
        if (value == null || value.trim().isEmpty) {
          item.completer.complete(null);
          continue;
        }
        _cache[item.key] = value;
        entries.add(
          TranslationCacheEntry(
            hash: item.hash,
            source: item.text,
            value: value,
          ),
        );
        item.completer.complete(value);
        _waiting.remove(item.key);
      }
      store.writeBatch(
        targetLanguage: target,
        engine: engine.id,
        entries: entries,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      store.addUsage(
        engine: engine.id,
        promptTokens: result.promptTokens,
        completionTokens: result.completionTokens,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      if (result.promptTokens > 0 || result.completionTokens > 0) {
        onUsage?.call();
      }
    } catch (error) {
      if (error is TranslationException && error.unavailable) {
        _unavailable = true;
      }
      for (final item in batch) {
        item.completer.complete(null);
        _waiting.remove(item.key);
      }
    }
  }

  static String _hash(String text) =>
      sha1.convert(utf8.encode(text)).toString();

  static String _key(String targetLanguage, String hash) =>
      '$targetLanguage\u0000$hash';
}

class _PendingText {
  final String key;
  final String hash;
  final String text;
  final String targetLanguage;
  final Completer<String?> completer;

  const _PendingText({
    required this.key,
    required this.hash,
    required this.text,
    required this.targetLanguage,
    required this.completer,
  });
}
