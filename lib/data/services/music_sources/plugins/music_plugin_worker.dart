import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_js_runtime.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_limits.dart';

/// Everything the sandbox isolate needs to start.
class MusicPluginWorkerSetup {
  /// Port the sandbox answers on.
  ///
  /// The application owns the matching inbox, because a [SendPort] can only
  /// reach the [ReceivePort] that created it.
  final SendPort replyTo;
  final String shims;
  final String bootstrap;
  final String fetchPolyfill;
  final MusicPluginLimits limits;

  const MusicPluginWorkerSetup({
    required this.replyTo,
    required this.shims,
    required this.bootstrap,
    required this.fetchPolyfill,
    required this.limits,
  });
}

/// Entry point of the isolate that hosts the JavaScript engine.
///
/// The isolate is a sandbox: it can be killed at any moment without harming
/// the application isolate, which is what makes a runaway plugin harmless.
void musicPluginWorkerMain(MusicPluginWorkerSetup setup) {
  final commands = ReceivePort();
  setup.replyTo.send({'commands': commands.sendPort});

  final MusicPluginJsRuntime runtime;
  try {
    runtime = MusicPluginJsRuntime.create(
      shims: setup.shims,
      bootstrap: setup.bootstrap,
      fetchPolyfill: setup.fetchPolyfill,
    );
  } catch (error) {
    setup.replyTo.send({'fatal': error.toString()});
    return;
  }

  _startMemoryGuard(setup);

  commands.listen((message) async {
    if (message is! Map) return;
    final id = message['id'];
    final method = message['method'];
    if (method is! String) return;

    if (method == 'dispose') {
      // The reference to the inbox in this closure keeps the answer port
      // open for the whole life of the sandbox.
      commands.close();
      return;
    }

    try {
      final value = await runtime.handle(
        method,
        Map<String, dynamic>.from(message),
      );
      setup.replyTo.send({'id': id, 'ok': true, 'value': value});
    } catch (error) {
      setup.replyTo.send({'id': id, 'ok': false, 'error': error.toString()});
    }
  });
}

/// Stops the sandbox when the plugin allocates more memory than allowed.
///
/// The limit is a delta over the memory the process used when the sandbox
/// started, so the application itself never counts against the plugin.
void _startMemoryGuard(MusicPluginWorkerSetup setup) {
  final baseline = ProcessInfo.currentRss;
  Timer.periodic(const Duration(seconds: 1), (timer) {
    final used = ProcessInfo.currentRss - baseline;
    if (used <= setup.limits.memoryLimitBytes) return;

    timer.cancel();
    setup.replyTo.send({
      'fatal': AppStrings.instance.pluginMemoryLimitExceeded(
        setup.limits.memoryLimitLabel,
      ),
    });
    Isolate.exit();
  });
}
