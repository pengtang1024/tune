import 'dart:async';

import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/audius_source.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/ccmixter_source.dart';
import 'package:tune/data/services/music_sources/direct_url_source.dart';
import 'package:tune/data/services/music_sources/graphql_source.dart';
import 'package:tune/data/services/music_sources/internet_archive_source.dart';
import 'package:tune/data/services/music_sources/json_api_source.dart';
import 'package:tune/data/services/music_sources/itunes_source.dart';
import 'package:tune/data/services/music_sources/jamendo_source.dart';
import 'package:tune/data/services/music_sources/jellyfin_source.dart';
import 'package:tune/data/services/music_sources/local_directory_source.dart';
import 'package:tune/data/services/music_sources/m3u_source.dart';
import 'package:tune/data/services/music_sources/lrclib_lyrics_provider.dart';
import 'package:tune/data/services/music_sources/lyrics_provider.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/music_sources/netease_cloud_music_source.dart';
import 'package:tune/data/services/music_sources/openverse_source.dart';
import 'package:tune/data/services/music_sources/podcast_rss_source.dart';
import 'package:tune/data/services/music_sources/source_type_catalogue.dart';
import 'package:tune/data/services/music_sources/radio_source.dart';
import 'package:tune/data/services/music_sources/subsonic_source.dart';
import 'package:tune/data/services/music_sources/wikimedia_source.dart';
import 'package:tune/data/services/stream_url_resolver.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/utils/logger.dart';

/// Scans every enabled source and isolates failures per source.
///
/// The service is intentionally independent from Riverpod; the library
/// controller owns progress and state, while this class only orchestrates I/O.
class MusicSourceService implements StreamUrlResolver {
  final MusicSourceStore _store;
  final LyricsProvider _lyricsProvider;
  final Map<String, MusicSourceAdapter> _adapters;

  MusicSourceService({
    required CrossPlatformMusicScanner scanner,
    required MusicSourceStore store,
    Dio? dio,
    LyricsProvider? lyricsProvider,
    Map<String, MusicSourceAdapter>? adapters,
  }) : _store = store,
       _lyricsProvider = lyricsProvider ?? LrclibLyricsProvider(dio: dio),
       _adapters = adapters ?? _registryOf(scanner, dio);

  /// The types the app serves out of the box.
  ///
  /// The registry is data, not code: a caller that serves other types hands
  /// its own map in instead of this one.
  static Map<String, MusicSourceAdapter> _registryOf(
    CrossPlatformMusicScanner scanner,
    Dio? dio,
  ) {
    return {
      'local': LocalDirectorySourceAdapter(scanner),
      'openverse': OpenverseSourceAdapter(dio: dio),
      'jamendo': JamendoSourceAdapter(dio: dio),
      'internet_archive': InternetArchiveSourceAdapter(dio: dio),
      'netease': NeteaseCloudMusicSourceAdapter(dio: dio),
      'ccmixter': CcMixterSourceAdapter(dio: dio),
      'itunes': ITunesSourceAdapter(dio: dio),
      'podcast_rss': PodcastRssSourceAdapter(dio: dio),
      'subsonic': SubsonicSourceAdapter(dio: dio),
      'audius': AudiusSourceAdapter(dio: dio),
      'radio': RadioSourceAdapter(dio: dio),
      'wikimedia': WikimediaSourceAdapter(dio: dio),
      'jellyfin': JellyfinSourceAdapter(dio: dio),
      'direct_url': DirectUrlSourceAdapter(),
      'm3u': M3uSourceAdapter(dio: dio),
      'json_api': JsonApiSourceAdapter(dio: dio),
      'graphql': GraphqlSourceAdapter(dio: dio),
    };
  }

  List<MusicSourceAdapter> get adapters => List.unmodifiable(_adapters.values);

  /// The adapter of a type, when the registry knows it.
  MusicSourceAdapter? adapterFor(String sourceType) => _adapters[sourceType];

  /// Whether a type is served by an adapter of the registry.
  bool supports(String sourceType) => _adapters.containsKey(sourceType);

  bool supportsConfig(MusicSourceConfig config) {
    return supports(config.sourceType);
  }

  /// Whether the source belongs to the top of the list.
  ///
  /// The type says where it belongs; an instance the reader added is never
  /// at the top, it is in the group of the ones they added.
  bool isFeatured(MusicSourceConfig config) {
    if (!config.builtIn) return false;
    return _adapters[config.sourceType]?.featured ?? false;
  }

  /// Persists scan timestamps after the library controller has saved songs.
  ///
  /// Marking inside [_scanOne] would let a crash leave a "scanned" timestamp
  /// without the corresponding songs, causing the next startup to skip them.
  Future<void> commitSuccessfulScans(Iterable<SourceScanResult> results) async {
    for (final result in results) {
      if (!result.isSuccess) continue;
      try {
        await _store.markScanned(result.sourceId, result.scannedAt);
      } catch (error, stackTrace) {
        Log.error('记录音源扫描时间失败: $error\n$stackTrace');
      }
    }
  }

  /// The fields the form of a type renders.
  ///
  /// The fields come from the type, so the interface knows no setting of any
  /// source: it only shows what the type declares.
  List<MusicSourceField> fieldsForType(String type) {
    final adapter = _adapters[type];
    if (adapter == null) return const [];
    return [
      if (adapter.browseModes.isNotEmpty) _browseField(adapter),
      ...adapter.configurationFields,
    ];
  }

  List<MusicSourceField> fieldsFor(MusicSourceConfig config) {
    return fieldsForType(config.sourceType);
  }

  /// The types the reader can add an instance of.
  ///
  /// The registry says which types are served; the catalogue says how they
  /// are named and whether they can be repeated. The local music folder is
  /// not among them: it is a setting of the app, not an instance.
  List<SourceTypeDescriptor> get addableTypes {
    final catalogue = SourceTypeCatalogue.byType(AppStrings.instance);
    final result = <SourceTypeDescriptor>[];
    for (final adapter in _adapters.values) {
      final descriptor = catalogue[adapter.sourceType];
      if (descriptor == null || !descriptor.addable) continue;
      result.add(descriptor);
    }
    return result;
  }

  /// The field that picks the browse stream of an instance.
  ///
  /// The options come from the type, so the interface knows no stream of any
  /// source: it only shows what the type declares.
  MusicSourceField _browseField(MusicSourceAdapter adapter) {
    final strings = AppStrings.instance;
    return MusicSourceField(
      'browse',
      strings.fieldBrowse,
      strings.fieldBrowseHint,
      choices: [
        for (final mode in adapter.browseModes)
          MusicSourceChoice(mode, BrowseMode.labelOf(mode, strings)),
      ],
    );
  }

  bool isConfigured(MusicSourceConfig config) {
    return _adapters[config.sourceType]?.isConfigured(config) ?? false;
  }

  String configurationHint(MusicSourceConfig config) {
    return _adapters[config.sourceType]?.configurationHint ??
        AppStrings.instance.sourceErrorUnsupported;
  }

  Future<MusicSourceAdapter?> _adapterFor(MusicSourceConfig config) async {
    return _adapters[config.sourceType];
  }

  /// Asks the owning source for a fresh address of [song].
  ///
  /// Only remote tracks can expire, so local files never reach the source.
  /// Errors are swallowed on purpose: the player reports the failure and the
  /// user decides what to do next.
  @override
  Future<Song?> refresh(Song song) async {
    final sourceId = song.sourceId;
    if (sourceId == null || sourceId.isEmpty) return null;
    if (!song.isRemote) return null;

    try {
      final config = _configFor(sourceId);
      if (config == null) return null;
      final adapter = await _adapterFor(config);
      if (adapter == null) return null;
      return await adapter.refreshStream(config, song);
    } catch (error, stackTrace) {
      Log.error('刷新播放地址失败: $error\n$stackTrace');
      return null;
    }
  }

  /// Looks up the persisted configuration that owns [sourceId].
  MusicSourceConfig? _configFor(String sourceId) {
    for (final config in _store.loadConfigs()) {
      if (config.id == sourceId) return config;
    }
    return null;
  }

  /// Fetches the lyrics of [song] from the source that owns it.
  ///
  /// The lyrics of a track are only needed when the user asks for them, so
  /// they are fetched on demand instead of during a scan. A song that already
  /// carries lyrics keeps them. A source without lyrics falls back to the
  /// shared lyrics database, so a track of the local music folder can be read
  /// along with its words.
  ///
  /// A source that fails is not the end of the road: the shared database is
  /// asked anyway. The failure of the shared database reaches the caller,
  /// because a network that is down is not the same as a track without
  /// lyrics.
  Future<String?> fetchLyrics(Song song) async {
    final stored = song.lyrics;
    if (stored != null && stored.trim().isNotEmpty) return stored;

    final fromSource = await _lyricsFromSource(song);
    if (fromSource != null) return fromSource;

    return _lyricsProvider.lookup(song);
  }

  /// The lyrics the source that owns [song] publishes.
  ///
  /// A source without lyrics answers with `null`, and a source that fails
  /// answers with `null` as well, so the shared database still gets its turn.
  Future<String?> _lyricsFromSource(Song song) async {
    final sourceId = song.sourceId;
    if (sourceId == null || sourceId.isEmpty) return null;

    try {
      final config = _configFor(sourceId);
      if (config == null) return null;
      final adapter = await _adapterFor(config);
      if (adapter == null) return null;

      final text = await adapter.fetchLyrics(config, song);
      if (text == null || text.trim().isEmpty) return null;
      return text;
    } catch (error, stackTrace) {
      Log.error('读取音源歌词失败: $error', stackTrace);
      return null;
    }
  }

  /// Searches every enabled remote source without touching scan timestamps.
  ///
  /// This is intentionally separate from [scanAll]: an on-demand search must
  /// not make the startup auto-scan believe a source has already been refreshed.
  Future<List<SourceScanResult>> search({
    required List<MusicSourceConfig> sources,
    required String query,
    void Function(String sourceId, double progress)? onProgress,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final candidates = sources
        .where((config) => config.enabled && !config.isLocal)
        .toList(growable: false);
    if (candidates.isEmpty) return const [];

    return Future.wait(
      candidates.map((config) async {
        onProgress?.call(config.id, 0);
        final MusicSourceAdapter? adapter;
        try {
          adapter = await _adapterFor(config);
        } catch (error) {
          return SourceScanResult(
            sourceId: config.id,
            status: SourceScanStatus.failed,
            message: describeSourceError(error),
          );
        }
        if (adapter == null) {
          return SourceScanResult(
            sourceId: config.id,
            status: SourceScanStatus.failed,
            message: AppStrings.instance.sourceErrorUnsupported,
          );
        }

        final searchConfig = config.copyWith(
          settings: {...config.settings, 'query': trimmed, 'keywords': trimmed},
        );
        try {
          final result = await adapter.scan(
            MusicSourceScanRequest(
              config: searchConfig,
              onProgress: (progress) => onProgress?.call(config.id, progress),
            ),
          );
          onProgress?.call(config.id, 1);
          return result;
        } catch (error) {
          return failedResult(config.id, error);
        }
      }),
    );
  }

  Future<List<SourceScanResult>> scanAll({
    required List<MusicSourceConfig> sources,
    required List<String> localPaths,
    bool respectAutoScanInterval = false,
    void Function(String sourceId, double progress)? onProgress,
  }) async {
    final enabled = sources
        .where((config) => config.enabled)
        .toList(growable: false);
    if (enabled.isEmpty) return const [];

    for (final config in enabled) {
      onProgress?.call(config.id, 0);
    }

    final results = await Future.wait(
      enabled.map(
        (config) => _scanOne(
          config,
          localPaths: localPaths,
          respectAutoScanInterval: respectAutoScanInterval,
          onProgress: (progress) => onProgress?.call(config.id, progress),
        ),
      ),
    );

    for (final config in enabled) {
      onProgress?.call(config.id, 1);
    }
    return results;
  }

  Future<SourceScanResult> _scanOne(
    MusicSourceConfig config, {
    required List<String> localPaths,
    required bool respectAutoScanInterval,
    required void Function(double progress) onProgress,
  }) async {
    if (!isConfigured(config)) {
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint(config),
      );
    }

    final MusicSourceAdapter? adapter;
    try {
      adapter = await _adapterFor(config);
    } catch (error) {
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.failed,
        message: describeSourceError(error),
      );
    }

    if (adapter == null) {
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.failed,
        message: AppStrings.instance.sourceErrorUnsupported,
      );
    }

    if (respectAutoScanInterval && adapter.autoScanInterval > Duration.zero) {
      final lastScan = _store.lastScanAt(config.id);
      if (lastScan != null) {
        final age = DateTime.now().difference(lastScan);
        if (age >= Duration.zero && age < adapter.autoScanInterval) {
          return SourceScanResult(
            sourceId: config.id,
            status: SourceScanStatus.skipped,
            message: AppStrings.instance.sourceErrorScanInterval(
              _intervalLabel(adapter.autoScanInterval),
            ),
          );
        }
      }
    }

    final watch = Stopwatch()..start();
    try {
      final result = await adapter
          .scan(
            MusicSourceScanRequest(
              config: config,
              localPaths: localPaths,
              onProgress: (progress) => onProgress(progress.clamp(0.0, 1.0)),
            ),
          )
          .timeout(adapter.scanTimeout);
      watch.stop();

      return SourceScanResult(
        sourceId: config.id,
        status: result.status,
        songs: result.songs,
        message: result.message,
        scannedAt: result.scannedAt,
        elapsed: watch.elapsed,
      );
    } on TimeoutException {
      watch.stop();
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.failed,
        message: AppStrings.instance.sourceErrorScanTimeout(
          adapter.scanTimeout.inSeconds,
        ),
        elapsed: watch.elapsed,
      );
    } catch (error) {
      watch.stop();
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.failed,
        message: describeSourceError(error),
        elapsed: watch.elapsed,
      );
    }
  }

  String _intervalLabel(Duration interval) {
    if (interval.inHours > 0) {
      return AppStrings.instance.intervalHours(interval.inHours);
    }
    return AppStrings.instance.intervalMinutes(interval.inMinutes);
  }
}
