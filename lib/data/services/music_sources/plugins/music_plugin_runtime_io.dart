import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_js/extensions/fetch.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_runtime.dart';
import 'package:tune/utils/logger.dart';

const bool isPlatformRuntimeSupported = true;

const _shimsAsset = 'assets/js/music_plugin_shims.js';
const _bootstrapAsset = 'assets/js/music_plugin_bootstrap.js';
const _invokeTimeout = Duration(seconds: 60);

Future<MusicPluginRuntime> createPlatformMusicPluginRuntime() async {
  final runtime = await IoMusicPluginRuntime.create();
  return runtime;
}

/// QuickJS-backed MusicFree plugin runtime.
class IoMusicPluginRuntime implements MusicPluginRuntime {
  final JavascriptRuntime _runtime;
  MusicPluginMetadata _metadata = const MusicPluginMetadata(platform: '');

  /// QuickJS can only run one script at a time, so every public call is queued.
  Future<void> _queue = Future<void>.value();
  bool _disposed = false;

  IoMusicPluginRuntime._(this._runtime);

  static Future<IoMusicPluginRuntime> create() async {
    final runtime = getJavascriptRuntime(xhr: false);
    await runtime.enableFetch();
    runtime.enableHandlePromises();

    final instance = IoMusicPluginRuntime._(runtime);
    try {
      await instance._evaluate(
        await rootBundle.loadString(_shimsAsset),
        label: '插件兼容库',
      );
      await instance._evaluate(
        await rootBundle.loadString(_bootstrapAsset),
        label: '插件桥接脚本',
      );
      return instance;
    } catch (_) {
      runtime.dispose();
      rethrow;
    }
  }

  @override
  MusicPluginMetadata get metadata => _metadata;

  @override
  Future<void> load(
    String script, {
    Map<String, String> userVariables = const {},
  }) {
    return _serialized(() async {
      _metadata = const MusicPluginMetadata(platform: '');
      await _evaluate(
        'globalThis.module = { exports: {} }; '
        'globalThis.exports = globalThis.module.exports; '
        'globalThis.__TUNE_USER_VARIABLES = ${jsonEncode(userVariables)}; '
        'true',
        label: '插件初始化',
      );
      await _evaluate(script, label: '插件脚本');
      await _evaluate(
        'globalThis.__tune_plugin = globalThis.module.exports; '
        'globalThis.__tune_metadata();',
        label: '插件导出',
      );

      final raw = _runtime.evaluate('globalThis.__tune_metadata()');
      if (raw.isError) {
        throw MusicPluginException(raw.stringResult);
      }
      final decoded = jsonDecode(raw.stringResult);
      if (decoded is! Map) {
        throw const MusicPluginException('插件没有导出有效的 module.exports');
      }
      _metadata = MusicPluginMetadata.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (!_metadata.isValid) {
        throw MusicPluginException('插件不完整：需要 platform 和 search 方法');
      }
    });
  }

  @override
  Future<List<Map<String, dynamic>>> search(String query, {int page = 1}) {
    return _serialized(() async {
      final value = await _invoke('search', [query, page, 'music']);
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
    });
  }

  @override
  Future<Map<String, dynamic>> getMediaSource(
    Map<String, dynamic> item, {
    String quality = 'standard',
  }) {
    return _serialized(() async {
      if (!_metadata.hasMediaSource) {
        final direct = item['url'];
        if (direct is String && direct.isNotEmpty) return {'url': direct};
        throw const MusicPluginException('插件未实现 getMediaSource');
      }

      final value = await _invoke('getMediaSource', [item, quality]);
      if (value is String && value.isNotEmpty) return {'url': value};
      if (value is Map && value['url'] is String) {
        return Map<String, dynamic>.from(value);
      }
      throw const MusicPluginException('插件没有返回可播放地址');
    });
  }

  @override
  Future<Map<String, dynamic>?> getLyric(Map<String, dynamic> item) {
    return _serialized(() async {
      if (!_metadata.hasLyric) return null;
      final value = await _invoke('getLyric', [item]);
      if (value is String) return {'rawLrc': value};
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    });
  }

  @override
  Future<Map<String, dynamic>?> getMusicInfo(Map<String, dynamic> item) {
    return _serialized(() async {
      if (!_metadata.hasMusicInfo) return null;
      final value = await _invoke('getMusicInfo', [item]);
      return value is Map ? Map<String, dynamic>.from(value) : null;
    });
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _queue;
    } catch (_) {
      // A failed call must not prevent the runtime from being released.
    }
    try {
      _runtime.dispose();
    } catch (error, stackTrace) {
      Log.error('释放音乐插件运行时失败: $error\n$stackTrace');
    }
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _queue = _queue.then((_) async {
      if (_disposed) {
        completer.completeError(const MusicPluginException('插件运行时已关闭'));
        return;
      }
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> _evaluate(String code, {required String label}) async {
    final result = _runtime.evaluate(code);
    if (result.isError) {
      throw MusicPluginException('$label 失败：${result.stringResult}');
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

    JsEvalResult resolved;
    try {
      resolved = await _runtime.handlePromise(pending, timeout: _invokeTimeout);
    } on TimeoutException {
      throw const MusicPluginException('插件调用超时');
    }

    var payload = jsonDecode(resolved.stringResult);
    if (payload is String) payload = jsonDecode(payload);
    if (payload is! Map) {
      throw const MusicPluginException('插件返回了无法识别的数据');
    }
    if (payload['ok'] != true) {
      throw MusicPluginException(payload['error']?.toString() ?? '插件调用失败');
    }
    return payload['value'];
  }
}
