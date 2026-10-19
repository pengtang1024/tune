import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart' show rootBundle;
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_limits.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_runtime.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_worker.dart';
import 'package:tune/utils/logger.dart';

const bool isPlatformRuntimeSupported = true;

const _shimsAsset = 'assets/js/music_plugin_shims.js';
const _bootstrapAsset = 'assets/js/music_plugin_bootstrap.js';
const _fetchPolyfillAsset = 'packages/flutter_js/assets/js/fetch.js';

/// Longest grace period the application waits before it kills a stuck
/// sandbox.
///
/// The sandbox reports a timeout on its own when a promise never settles; the
/// grace period only covers a script that blocks the engine itself.
const _maxKillGrace = Duration(seconds: 10);

Future<MusicPluginRuntime> createPlatformMusicPluginRuntime() async {
  return IoMusicPluginRuntime.create();
}

/// Runs a MusicFree plugin inside a sandbox isolate.
///
/// The JavaScript engine lives in its own isolate, so a plugin that hangs or
/// allocates endlessly can be killed without freezing the application. The
/// application isolate only exchanges JSON messages with it.
class IoMusicPluginRuntime implements MusicPluginRuntime {
  final MusicPluginLimits _limits;
  Isolate? _worker;
  late final ReceivePort _inbox;
  late final ReceivePort _lifecycle;
  final Completer<void> _ready = Completer<void>();
  final Map<int, Completer<dynamic>> _pending = {};

  SendPort? _commands;
  MusicPluginMetadata _metadata = const MusicPluginMetadata(platform: '');
  final DateTime _startedAt = DateTime.now();
  int _nextId = 0;
  bool _disposed = false;
  bool _broken = false;
  String? _failureReason;

  IoMusicPluginRuntime._(this._limits) {
    _inbox = ReceivePort();
    _lifecycle = ReceivePort();
    _lifecycle.listen(_handleLifecycle);
  }

  /// Builds a runtime and waits until the sandbox is ready to take commands.
  static Future<IoMusicPluginRuntime> create({
    MusicPluginLimits limits = const MusicPluginLimits(),
  }) async {
    final shims = await rootBundle.loadString(_shimsAsset);
    final bootstrap = await rootBundle.loadString(_bootstrapAsset);
    final fetchPolyfill = await rootBundle.loadString(_fetchPolyfillAsset);

    final runtime = IoMusicPluginRuntime._(limits);
    await runtime._start(shims, bootstrap, fetchPolyfill);
    return runtime;
  }

  /// Spawns the sandbox and waits for its handshake.
  Future<void> _start(
    String shims,
    String bootstrap,
    String fetchPolyfill,
  ) async {
    try {
      _worker = await Isolate.spawn(
        musicPluginWorkerMain,
        MusicPluginWorkerSetup(
          replyTo: _inbox.sendPort,
          shims: shims,
          bootstrap: bootstrap,
          fetchPolyfill: fetchPolyfill,
          limits: _limits,
        ),
        onError: _lifecycle.sendPort,
        onExit: _lifecycle.sendPort,
        errorsAreFatal: true,
        debugName: 'tune-music-plugin',
      );
    } catch (error) {
      final message = AppStrings.instance.pluginSandboxStartFailed('$error');
      _breakRuntime(message);
      throw MusicPluginException(message);
    }

    _inbox.listen(_handleInbox);

    try {
      await _ready.future.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      _breakRuntime(AppStrings.instance.pluginSandboxStartTimeout);
      await dispose();
      throw MusicPluginException(AppStrings.instance.pluginSandboxStartTimeout);
    }
  }

  @override
  MusicPluginMetadata get metadata => _metadata;

  @override
  bool get isUsable {
    if (_disposed || _broken) return false;
    return DateTime.now().difference(_startedAt) <= _limits.runtimeBudget;
  }

  @override
  Future<void> load(
    String script, {
    Map<String, String> userVariables = const {},
  }) async {
    if (script.length > _limits.maxScriptBytes) {
      throw MusicPluginException(
        AppStrings.instance.pluginScriptTooLarge(
          '${_limits.maxScriptBytes ~/ 1024}',
        ),
      );
    }

    final value = await _request('load', {
      'script': script,
      'userVariables': userVariables,
    });
    if (value is! Map) {
      throw MusicPluginException(AppStrings.instance.pluginNoExports);
    }

    _metadata = MusicPluginMetadata.fromJson(Map<String, dynamic>.from(value));
    if (!_metadata.isValid) {
      throw MusicPluginException(AppStrings.instance.pluginIncomplete);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> search(
    String query, {
    int page = 1,
  }) async {
    final value = await _request('search', {'query': query, 'page': page});
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> getMediaSource(
    Map<String, dynamic> item, {
    String quality = 'standard',
  }) async {
    final value = await _request('getMediaSource', {
      'item': item,
      'quality': quality,
    });
    if (value is! Map) {
      throw MusicPluginException(AppStrings.instance.pluginNoStream);
    }
    return Map<String, dynamic>.from(value);
  }

  @override
  Future<Map<String, dynamic>?> getLyric(Map<String, dynamic> item) async {
    final value = await _request('getLyric', {'item': item});
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  @override
  Future<Map<String, dynamic>?> getMusicInfo(Map<String, dynamic> item) async {
    final value = await _request('getMusicInfo', {'item': item});
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _failPending(MusicPluginException(AppStrings.instance.pluginRuntimeClosed));
    if (!_ready.isCompleted) {
      _ready.completeError(
        MusicPluginException(AppStrings.instance.pluginRuntimeClosed),
      );
    }
    _commands?.send({'method': 'dispose'});
    _worker?.kill(priority: Isolate.immediate);
    _inbox.close();
    _lifecycle.close();
  }

  /// Sends one command to the sandbox and waits for its answer.
  Future<dynamic> _request(String method, Map<String, dynamic> payload) {
    if (_disposed) {
      return Future.error(
        MusicPluginException(AppStrings.instance.pluginRuntimeClosed),
      );
    }
    if (_broken) {
      return Future.error(
        MusicPluginException(
          _failureReason ?? AppStrings.instance.pluginRuntimeTerminated,
        ),
      );
    }
    if (DateTime.now().difference(_startedAt) > _limits.runtimeBudget) {
      _breakRuntime(AppStrings.instance.pluginRuntimeTimeLimit);
      return Future.error(MusicPluginException(_failureReason!));
    }

    final commands = _commands;
    if (commands == null) {
      return Future.error(
        MusicPluginException(AppStrings.instance.pluginSandboxNotReady),
      );
    }

    final id = _nextId++;
    final completer = Completer<dynamic>();
    _pending[id] = completer;
    commands.send({'id': id, 'method': method, ...payload});

    final timer = Timer(_limits.callTimeout + _killGrace, () {
      if (!_pending.containsKey(id)) return;
      _breakRuntime(
        AppStrings.instance.pluginCallTimeoutDetailed(
          _limits.callTimeout.inSeconds,
        ),
      );
      _worker?.kill(priority: Isolate.immediate);
    });

    return completer.future.whenComplete(timer.cancel);
  }

  /// Time the application waits before it kills a stuck sandbox.
  ///
  /// The grace period only covers a script that blocks the engine itself; a
  /// promise that never settles is reported by the sandbox on its own.
  Duration get _killGrace {
    final limit = _limits.callTimeout;
    return limit < _maxKillGrace ? limit : _maxKillGrace;
  }

  /// Reads one message of the sandbox: the handshake, a fatal notice or the
  /// answer of a command.
  void _handleInbox(Object? message) {
    if (message is! Map) return;

    final commands = message['commands'];
    if (commands is SendPort) {
      _commands = commands;
      if (!_ready.isCompleted) _ready.complete();
      return;
    }

    final fatal = message['fatal'];
    if (fatal is String) {
      _breakRuntime(fatal);
      return;
    }

    final id = message['id'];
    if (id is! int) return;
    final completer = _pending.remove(id);
    if (completer == null || completer.isCompleted) return;

    if (message['ok'] == true) {
      completer.complete(message['value']);
    } else {
      completer.completeError(
        MusicPluginException(
          message['error']?.toString() ?? AppStrings.instance.pluginCallError,
        ),
      );
    }
  }

  /// Reacts to a crash or to an unexpected end of the sandbox.
  void _handleLifecycle(Object? message) {
    if (_disposed) return;
    final reason = message is List && message.isNotEmpty
        ? message.first.toString()
        : AppStrings.instance.pluginRuntimeCrashed;
    _breakRuntime(reason);
  }

  /// Marks the runtime as dead and fails every waiting command.
  void _breakRuntime(String reason) {
    if (_broken) return;
    _broken = true;
    _failureReason = reason;
    Log.error('音乐插件运行时已终止：$reason');
    if (!_ready.isCompleted) {
      _ready.completeError(MusicPluginException(reason));
    }
    _failPending(MusicPluginException(reason));
    _worker?.kill(priority: Isolate.immediate);
  }

  void _failPending(Object error) {
    if (_pending.isEmpty) return;
    final pending = Map<int, Completer<dynamic>>.from(_pending);
    _pending.clear();
    for (final completer in pending.values) {
      if (!completer.isCompleted) completer.completeError(error);
    }
  }
}
