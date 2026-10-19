import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_runtime.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Adapts one MusicFree-compatible JavaScript plugin to the source contract.
///
/// Playback URLs are resolved during the scan because the rest of the player
/// only needs a plain [Song] with a `streamUrl`. Failed lookups are skipped so
/// a single broken track cannot poison the whole source.
class MusicPluginSourceAdapter implements MusicSourceAdapter {
  static const _maxTracks = 12;
  static const _parallelism = 4;

  final MusicSourceConfig config;
  final MusicPluginRuntime runtime;

  MusicPluginSourceAdapter({required this.config, required this.runtime});

  @override
  String get sourceId => config.id;

  @override
  bool isConfigured(MusicSourceConfig config) =>
      config.setting('query') != null;

  @override
  String get configurationHint => '填写一个搜索关键词，例如 周杰伦、piano 或 jazz';

  @override
  List<MusicSourceField> get configurationFields => const [
    MusicSourceField('query', '搜索关键词', '例如 周杰伦、piano、jazz', required: true),
  ];

  @override
  Duration get autoScanInterval => const Duration(hours: 6);

  @override
  Duration get scanTimeout => const Duration(seconds: 90);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final query = request.config.setting('query');
    if (query == null) {
      return SourceScanResult(
        sourceId: sourceId,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    try {
      final items = await runtime.search(query);
      if (items.isEmpty) {
        return SourceScanResult(
          sourceId: sourceId,
          status: SourceScanStatus.success,
          songs: const [],
          message: '没有找到匹配的歌曲',
        );
      }

      final sliced = items.take(_maxTracks).toList(growable: false);
      final songs = <Song>[];
      var completed = 0;
      var next = 0;

      Future<void> worker() async {
        while (true) {
          final index = next++;
          if (index >= sliced.length) return;
          final item = sliced[index];
          final song = await _resolveSong(item);
          if (song != null) songs.add(song);
          completed++;
          request.onProgress?.call(completed / sliced.length);
        }
      }

      final workers = sliced.length < _parallelism
          ? sliced.length
          : _parallelism;
      await Future.wait([for (var i = 0; i < workers; i++) worker()]);

      if (songs.isEmpty) {
        return SourceScanResult(
          sourceId: sourceId,
          status: SourceScanStatus.failed,
          message: '插件返回了 ${items.length} 个结果，但没有可播放地址',
        );
      }

      songs.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
      return SourceScanResult(
        sourceId: sourceId,
        status: SourceScanStatus.success,
        songs: songs,
      );
    } catch (error) {
      return failedResult(sourceId, error);
    }
  }

  Future<Song?> _resolveSong(Map<String, dynamic> item) async {
    final externalId = item['id']?.toString() ?? '';
    final title = item['title']?.toString().trim() ?? '';
    if (externalId.isEmpty || title.isEmpty) return null;

    try {
      final media = await runtime.getMediaSource(item);
      final url = SourceSongFactory.normalizeUrl(media['url']?.toString());
      if (url == null) return null;

      final headers = <String, String>{};
      final rawHeaders = media['headers'];
      if (rawHeaders is Map) {
        rawHeaders.forEach((key, value) {
          if (key != null && value != null) {
            headers[key.toString()] = value.toString();
          }
        });
      }
      final userAgent = media['userAgent']?.toString();
      if (userAgent != null && userAgent.isNotEmpty) {
        headers.putIfAbsent('User-Agent', () => userAgent);
      }

      final durationSeconds = SourceSongFactory.parseInt(item['duration']);
      return SourceSongFactory.create(
        sourceId: sourceId,
        externalId: externalId,
        title: title,
        artist: item['artist']?.toString() ?? '',
        album: item['album']?.toString() ?? '',
        duration: durationSeconds > 0 ? durationSeconds * 1000 : 0,
        streamUrl: url,
        artworkUrl: item['artwork']?.toString(),
        sourceData: item,
        httpHeaders: headers.isEmpty ? null : Map.unmodifiable(headers),
        lyrics: item['rawLrc']?.toString(),
      );
    } catch (_) {
      // A broken item is skipped; the rest of the plugin results stay usable.
      return null;
    }
  }
}
