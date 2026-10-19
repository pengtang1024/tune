import 'dart:async';
import 'dart:convert';

import 'package:flutter_js/extensions/xhr.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_runtime.dart';
import 'package:tune/core/l10n/app_strings.dart';

/// The JavaScript side of a plugin runtime.
///
/// It owns the QuickJS engine and runs inside the sandbox isolate. Every
/// public method answers with JSON safe values so they can travel back to the
/// application isolate.
class MusicPluginJsRuntime {
  final JavascriptRuntime _runtime;
  MusicPluginMetadata _metadata = const MusicPluginMetadata(platform: '');

  /// QuickJS executes one script at a time, so every call is queued.
  Future<void> _queue = Future<void>.value();

  MusicPluginJsRuntime._(this._runtime);

  /// Builds a runtime with the compatibility layer already evaluated.
  ///
  /// The sources are handed in instead of read from the asset bundle because
  /// the bundle is only reachable from the application isolate.
  static MusicPluginJsRuntime create({
    required String shims,
    required String bootstrap,
    required String fetchPolyfill,
  }) {
    final runtime = getJavascriptRuntime(xhr: false);
    runtime.enableXhr();

    final polyfill = runtime.evaluate(fetchPolyfill);
    if (polyfill.isError) {
      runtime.dispose();
      throw MusicPluginException(
        AppStrings.instance.pluginFetchShimFailed(polyfill.stringResult),
      );
    }

    final instance = MusicPluginJsRuntime._(runtime);
    instance._evaluate(shims, label: AppStrings.instance.pluginCompatLibrary);
    instance._evaluate(
      bootstrap,
      label: AppStrings.instance.pluginBridgeScript,
    );
    return instance;
  }

  MusicPluginMetadata get metadata => _metadata;

  /// Runs one plugin command and answers with its JSON safe result.
  Future<dynamic> handle(String method, Map<String, dynamic> payload) {
    switch (method) {
      case 'load':
        return _serialized(() => _load(payload));
      case 'search':
        return _serialized(() => _search(payload));
      case 'getMediaSource':
        return _serialized(() => _getMediaSource(payload));
      case 'getLyric':
        return _serialized(() => _getLyric(payload));
      case 'getMusicInfo':
        return _serialized(() => _getMusicInfo(payload));
      default:
        throw MusicPluginException(
          AppStrings.instance.pluginUnknownCall(method),
        );
    }
  }

  Future<Map<String, dynamic>> _load(Map<String, dynamic> payload) async {
    final script = payload['script'];
    final userVariables = payload['userVariables'];
    if (script is! String) {
      throw MusicPluginException(AppStrings.instance.pluginScriptMissing);
    }

    _metadata = const MusicPluginMetadata(platform: '');
    _evaluate(
      'globalThis.module = { exports: {} }; '
      'globalThis.exports = globalThis.module.exports; '
      'globalThis.__TUNE_USER_VARIABLES = '
      '${jsonEncode(userVariables is Map ? userVariables : const {})}; '
      'true',
      label: AppStrings.instance.pluginInit,
    );
    _evaluate(script, label: AppStrings.instance.pluginScript);
    _evaluate(
      'globalThis.__tune_plugin = globalThis.module.exports; '
      'globalThis.__tune_metadata();',
      label: AppStrings.instance.pluginExports,
    );

    final raw = _runtime.evaluate('globalThis.__tune_metadata()');
    if (raw.isError) {
      throw MusicPluginException(raw.stringResult);
    }
    final decoded = jsonDecode(raw.stringResult);
    if (decoded is! Map) {
      throw MusicPluginException(AppStrings.instance.pluginNoExports);
    }
    final metadata = Map<String, dynamic>.from(decoded);
    _metadata = MusicPluginMetadata.fromJson(metadata);
    return metadata;
  }

  Future<List<Map<String, dynamic>>> _search(
    Map<String, dynamic> payload,
  ) async {
    final value = await _invoke('search', [
      payload['query'],
      payload['page'] ?? 1,
      'music',
    ]);
    final rawItems = value is List
        ? value
        : value is Map
        ? value['data']
        : null;
    if (rawItems is! List) return const [];
    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _getMediaSource(
    Map<String, dynamic> payload,
  ) async {
    final item = Map<String, dynamic>.from(
      (payload['item'] as Map?) ?? const {},
    );
    if (!_metadata.hasMediaSource) {
      final direct = item['url'];
      if (direct is String && direct.isNotEmpty) return {'url': direct};
      throw MusicPluginException(AppStrings.instance.pluginNoMediaSource);
    }

    final value = await _invoke('getMediaSource', [
      item,
      payload['quality'] ?? 'standard',
    ]);
    if (value is String && value.isNotEmpty) return {'url': value};
    if (value is Map && value['url'] is String) {
      return Map<String, dynamic>.from(value);
    }
    throw MusicPluginException(AppStrings.instance.pluginNoStream);
  }

  Future<Map<String, dynamic>?> _getLyric(Map<String, dynamic> payload) async {
    if (!_metadata.hasLyric) return null;
    final item = Map<String, dynamic>.from(
      (payload['item'] as Map?) ?? const {},
    );
    final value = await _invoke('getLyric', [item]);
    if (value is String) return {'rawLrc': value};
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Future<Map<String, dynamic>?> _getMusicInfo(
    Map<String, dynamic> payload,
  ) async {
    if (!_metadata.hasMusicInfo) return null;
    final item = Map<String, dynamic>.from(
      (payload['item'] as Map?) ?? const {},
    );
    final value = await _invoke('getMusicInfo', [item]);
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  void _evaluate(String code, {required String label}) {
    final result = _runtime.evaluate(code);
    if (result.isError) {
      throw MusicPluginException(
        AppStrings.instance.pluginStepFailed(result.stringResult, label),
      );
    }
  }

  Future<dynamic> _invoke(String method, List<dynamic> args) async {
    final code =
        '''
(async () => {
  try {
    const value = await globalThis.__tune_invoke(
      ${jsonEncode(method)},
      ${jsonEncode(args)}
    );
    return JSON.stringify({
      ok: true,
      value: value === undefined ? null : value
    });
  } catch (error) {
    return JSON.stringify({
      ok: false,
      error: String((error && error.stack) || error)
    });
  }
})()
''';

    final pending = _runtime.evaluate(code);
    if (pending.isError) {
      throw MusicPluginException(pending.stringResult);
    }

    final resolved = await _runtime.handlePromise(pending);
    var payload = jsonDecode(resolved.stringResult);
    if (payload is String) payload = jsonDecode(payload);
    if (payload is! Map) {
      throw MusicPluginException(AppStrings.instance.pluginUnknownData);
    }
    if (payload['ok'] != true) {
      throw MusicPluginException(
        payload['error']?.toString() ?? AppStrings.instance.pluginCallError,
      );
    }
    return payload['value'];
  }
}
