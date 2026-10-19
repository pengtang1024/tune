import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_runtime.dart';

/// Downloads a MusicFree plugin script from a URL.
///
/// The downloader is the only place that reaches the network for plugins, so
/// the size limit and the URL check live in one spot.
class MusicPluginDownloader {
  /// Largest script the app accepts.
  static const int maxBytes = 2 * 1024 * 1024;

  final Dio _dio;

  MusicPluginDownloader({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              responseType: ResponseType.plain,
              followRedirects: true,
            ),
          );

  /// Fetches the script behind [url] and returns its text.
  Future<String> download(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw MusicPluginException(AppStrings.instance.pluginUrlInvalid);
    }

    final response = await _dio.get<String>(uri.toString());
    final script = response.data ?? '';
    if (script.trim().isEmpty) {
      throw MusicPluginException(AppStrings.instance.pluginUrlEmpty);
    }
    if (script.length > maxBytes) {
      throw MusicPluginException(AppStrings.instance.pluginUrlTooLarge);
    }
    return script;
  }

  /// Suggests a file name for a plugin that was downloaded from [url].
  static String fileNameFor(String url) {
    final uri = Uri.tryParse(url.trim());
    final segments = uri?.pathSegments ?? const <String>[];
    final name = segments.isEmpty ? 'plugin.js' : segments.last;
    return name.endsWith('.js') ? name : '$name.js';
  }
}
