import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/radio_station.dart';
import 'package:tune/data/services/music_sources/radio_station_providers.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Internet radio: the streams of public stations.
///
/// The source reads three directories and lets the user pick one of them:
/// the open station directory, the curated channels of SomaFM and the
/// curated stations of Radio Paradise. A station is a live stream, so it is
/// played straight from the network and never stored on disk.
class RadioSourceAdapter extends MusicSourceAdapter {
  static const _allProviders = 'all';

  final List<RadioStationProvider> _providers;

  RadioSourceAdapter({Dio? dio, List<RadioStationProvider>? providers})
    : _providers =
          providers ??
          [
            RadioBrowserProvider(dio: dio),
            SomaFmProvider(dio: dio),
            RadioParadiseProvider(dio: dio),
          ];

  @override
  String get sourceId => 'radio';

  @override
  bool isConfigured(MusicSourceConfig config) => true;

  @override
  String get configurationHint => AppStrings.instance.radioHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'provider',
      AppStrings.instance.radioFieldProvider,
      AppStrings.instance.radioFieldProviderHint,
      choices: [
        MusicSourceChoice(_allProviders, AppStrings.instance.radioProviderAll),
        for (final provider in _providers)
          MusicSourceChoice(provider.id, provider.displayName),
      ],
    ),
    MusicSourceField(
      'query',
      AppStrings.instance.radioFieldQuery,
      AppStrings.instance.radioFieldQueryHint,
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.radioFieldLimit,
      AppStrings.instance.radioFieldLimitHint,
      numeric: true,
    ),
  ];

  @override
  Duration get autoScanInterval => const Duration(hours: 12);

  @override
  Duration get scanTimeout => const Duration(seconds: 60);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final query = request.config.setting('query') ?? '';
    final limit = _readLimit(request.config);
    final selected = _selectedProviders(request.config);

    final stations = <RadioStation>[];
    final failures = <Object>[];

    for (final provider in selected) {
      try {
        stations.addAll(await provider.fetch(query: query, limit: limit));
      } catch (error) {
        failures.add(error);
      }
    }

    if (stations.isEmpty && failures.isNotEmpty) {
      return failedResult(sourceId, failures.first);
    }

    final songs = buildSongs(stations, sourceId: sourceId);
    return SourceScanResult(
      sourceId: sourceId,
      status: SourceScanStatus.success,
      songs: songs,
      message: songs.isEmpty ? AppStrings.instance.radioNoMatch : null,
    );
  }

  int _readLimit(MusicSourceConfig config) {
    final parsed = SourceSongFactory.parseInt(config.setting('limit'));
    if (parsed <= 0) return 20;
    return parsed.clamp(1, 100);
  }

  /// The directories the user picked, or all of them.
  List<RadioStationProvider> _selectedProviders(MusicSourceConfig config) {
    final selected = config.setting('provider');
    if (selected == null || selected == _allProviders) return _providers;
    return _providers.where((provider) => provider.id == selected).toList();
  }

  /// Turns stations into tracks.
  ///
  /// The station is the track: its name is the title, the track on air is the
  /// album and its artist is the performer. The stream never ends, so the
  /// tracks are marked as live.
  static List<Song> buildSongs(
    List<RadioStation> stations, {
    required String sourceId,
  }) {
    final songs = <Song>[];
    final seen = <String>{};

    for (final station in stations) {
      final externalId = '${station.provider}/${station.id}';
      if (!seen.add(externalId)) continue;

      final nowPlaying = [
        if (station.nowPlayingArtist != null) station.nowPlayingArtist!,
        if (station.nowPlayingTitle != null) station.nowPlayingTitle!,
      ].join(' - ');

      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: externalId,
          title: station.name,
          artist: station.nowPlayingArtist ?? station.country ?? '',
          album: station.nowPlayingTitle ?? '',
          streamUrl: station.streamUrl,
          artworkUrl: station.artworkUrl,
          genre: station.genre,
          language: station.language,
          year: station.nowPlayingYear,
          description: station.description,
          isLiveStream: true,
          sourceData: {
            'provider': station.provider,
            'stationId': station.id,
            'codec': station.codec,
            'bitrate': station.bitrate,
            'listeners': station.listeners,
            'homepage': station.homepage,
            'nowPlaying': nowPlaying,
          },
        ),
      );
    }

    return songs;
  }
}
