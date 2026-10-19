import 'music_plugin_runtime_factory_stub.dart'
    if (dart.library.io) 'music_plugin_runtime_io.dart'
    as platform;
import 'music_plugin_runtime.dart';

/// Creates the platform JavaScript runtime.
///
/// Web builds get the stub implementation; desktop and mobile use QuickJS.
Future<MusicPluginRuntime> createMusicPluginRuntime() {
  return platform.createPlatformMusicPluginRuntime();
}

bool get isMusicPluginRuntimeSupported => platform.isPlatformRuntimeSupported;
