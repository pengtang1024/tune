import 'package:tune/core/l10n/app_strings.dart';

import 'music_plugin_runtime.dart';

const bool isPlatformRuntimeSupported = false;

Future<MusicPluginRuntime> createPlatformMusicPluginRuntime() async {
  throw MusicPluginException(AppStrings.instance.pluginRuntimeUnsupported);
}
