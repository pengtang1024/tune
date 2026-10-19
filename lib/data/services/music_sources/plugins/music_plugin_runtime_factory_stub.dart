import 'music_plugin_runtime.dart';

const bool isPlatformRuntimeSupported = false;

Future<MusicPluginRuntime> createPlatformMusicPluginRuntime() async {
  throw const MusicPluginException('当前平台不支持 JavaScript 音乐插件，请在桌面端或移动端导入');
}
