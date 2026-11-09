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
/// The source reads four directories and lets the user pick one of them:
/// the open station directory, the curated channels of SomaFM, the curated
/// stations of Radio Paradise and the live channels of NTS. A station is a
/// live stream, so it is played straight from the network and never stored on
/// disk.
class RadioSourceAdapter extends MusicSourceAdapter {
  /// How many tracks a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(20, 100);

  static const _allProviders = 'all';

  final List<RadioStationProvider> _providers;

  RadioSourceAdapter({Dio? dio, List<RadioStationProvider>? providers})
    : _providers =
          providers ??
          [
            RadioBrowserProvider(dio: dio),
            SomaFmProvider(dio: dio),
            RadioParadiseProvider(dio: dio),
            NtsProvider(dio: dio),
            RadioFranceProvider(),
          ];

  @override
  String get sourceType => 'radio';

  /// The source asks nothing of the reader, so it belongs to the top
  /// of the list.
  @override
  bool get featured => true;

  @override
  bool isConfigured(MusicSourceConfig config) => true;

  @override
  String get configurationHint => AppStrings.instance.radioHint;



  /// The tongues the directory files the most stations under.
  ///
  /// The directory names them in English; the name is the whole filter, so the
  /// values are the names themselves. Every one of them was counted on the
  /// directory, and the ones that hold no station are left out.
  static const _languages = <String>[
    'english',
    'spanish',
    'german',
    'french',
    'chinese',
    'russian',
    'italian',
    'greek',
    'portuguese',
    'turkish',
    'japanese',
    'polish',
    'korean',
    'arabic',
    'hindi',
  ];

  /// The name of a tongue in the language of the app.
  static String _languageLabel(String language) {
    final strings = AppStrings.instance;
    return switch (language) {
      'english' => strings.languageNameEnglish,
      'spanish' => strings.languageNameSpanish,
      'german' => strings.languageNameGerman,
      'french' => strings.languageNameFrench,
      'chinese' => strings.languageNameChinese,
      'russian' => strings.languageNameRussian,
      'italian' => strings.languageNameItalian,
      'greek' => strings.languageNameGreek,
      'portuguese' => strings.languageNamePortuguese,
      'turkish' => strings.languageNameTurkish,
      'japanese' => strings.languageNameJapanese,
      'polish' => strings.languageNamePolish,
      'korean' => strings.languageNameKorean,
      'arabic' => strings.languageNameArabic,
      _ => strings.languageNameHindi,
    };
  }

  /// The bitrate floors the app offers, in kbit/s.
  ///
  /// The directory answers a floor it cannot read with the whole list, so the
  /// floors are a fixed few and every one of them was read back from it.
  static const _bitrateFloors = [64, 128, 192, 320];

  /// The reaches the directory files stations under, most used first.
  ///
  /// Every one of them was counted on the directory itself (with broken
  /// stations left out), and only the reaches that hold a few hundred
  /// stations are offered: a tag nothing is filed under would be an option
  /// that answers with nothing.
  static const _tags = <String>[
    'pop',
    'rock',
    'news',
    'talk',
    'dance',
    'classical',
    'jazz',
    'electronic',
    'oldies',
    '80s',
    '90s',
    'top 40',
    'house',
    'alternative',
    'country',
    'folk',
    'soul',
    'metal',
    'indie',
    'ambient',
    'gospel',
    'techno',
    'blues',
    'disco',
    'funk',
    'lounge',
    'chillout',
    'easy listening',
    'salsa',
    'reggae',
    'trance',
    'hiphop',
    // Verified against the directory's own tag list (station counts in
    // brackets); the ones below 200 stations stay out, an option that
    // answers with a handful is not worth a line in the list.
    'music', // 3642
    'hits', // 1426
    'classic rock', // 753
    'retro', // 268
    'edm', // 249
    'smooth jazz', // 234
    'latino', // 228
    'world music', // 223
    'deep house', // 211
  ];

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
      'country',
      AppStrings.instance.radioFieldCountry,
      AppStrings.instance.radioFieldCountryHint,
    ),
    MusicSourceField(
      'tag',
      AppStrings.instance.radioFieldTag,
      AppStrings.instance.radioFieldTagHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.radioTagAll),
        for (final tag in _tags) MusicSourceChoice(tag, tag),
      ],
    ),
    MusicSourceField(
      'language',
      AppStrings.instance.radioFieldLanguage,
      AppStrings.instance.radioFieldLanguageHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.languageNameAll),
        for (final language in _languages)
          MusicSourceChoice(language, _languageLabel(language)),
      ],
    ),
    MusicSourceField(
      'bitrate',
      AppStrings.instance.radioFieldBitrate,
      AppStrings.instance.radioFieldBitrateHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.radioBitrateAll),
        for (final floor in _bitrateFloors)
          MusicSourceChoice('$floor', AppStrings.instance.radioBitrateAtLeast('$floor')),
      ],
    ),
    MusicSourceField(
      'order',
      AppStrings.instance.radioFieldOrder,
      AppStrings.instance.radioFieldOrderHint,
      choices: [
        MusicSourceChoice('votes', AppStrings.instance.radioOrderVotes),
        MusicSourceChoice('clickcount', AppStrings.instance.radioOrderListened),
      ],
    ),
    MusicSourceField(
      'query',
      AppStrings.instance.radioFieldQuery,
      AppStrings.instance.radioFieldQueryHint,
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.fieldLimitStations,
      AppStrings.instance.fieldLimitHint(scanLimit.count, scanLimit.max),
      numeric: true,
    ),
  ];

  @override
  bool get supportsPaging => true;

  @override
  Duration get autoScanInterval => const Duration(hours: 12);

  @override
  Duration get scanTimeout => const Duration(seconds: 60);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final query = request.config.setting('query') ?? '';
    final country = request.config.setting('country');
    final tag = request.config.setting('tag');
    final language = request.config.setting('language');
    final order = request.config.setting('order');
    final bitrate = request.config.setting('bitrate');
    final limit = scanLimit.read(request.config.setting('limit'));
    final selected = _selectedProviders(request.config);

    final stations = <RadioStation>[];
    final failures = <Object>[];

    for (final provider in selected) {
      // A directory without pages would only answer with the same window.
      if (request.offset > 0 && !provider.supportsPaging) continue;
      try {
        stations.addAll(
          await provider.fetch(
            query: query,
            limit: limit,
            country: country,
            offset: request.offset,
            tag: tag,
            language: language,
            order: order,
            bitrate: bitrate,
          ),
        );
      } catch (error) {
        failures.add(error);
      }
    }

    if (stations.isEmpty && failures.isNotEmpty) {
      return failedResult(request.config.id, failures.first);
    }

    final songs = buildSongs(stations, sourceId: request.config.id);
    return SourceScanResult(
      sourceId: request.config.id,
      status: SourceScanStatus.success,
      songs: songs,
      message: songs.isEmpty ? AppStrings.instance.radioNoMatch : null,
    );
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
          genres: station.genres,
          language: station.language,
          year: station.nowPlayingYear,
          description: station.description,
          // The directory tells how fast a station streams; the track carries
          // it, so the bitrate a reader filters by is the one they see.
          bitrate: (station.bitrate ?? 0) > 0 ? station.bitrate : null,
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
