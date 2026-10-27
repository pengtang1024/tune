import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/radio_station.dart';
import 'package:tune/data/services/music_sources/source_request_headers.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';

/// The open directory of internet radio stations.
///
/// The directory publishes the stations of thousands of broadcasters with
/// the information a listener needs: the working stream address, the codec,
/// the bitrate, the country, the language and the station logo.
class RadioBrowserProvider extends RadioStationProvider {
  static const _base = 'https://all.api.radio-browser.info/json';

  final Dio _dio;

  RadioBrowserProvider({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: sourceRequestHeaders(
                extra: const {'Accept': 'application/json'},
              ),
            ),
          );

  @override
  String get id => 'browser';

  @override
  String get displayName => 'Radio Browser';

  @override
  Future<List<RadioStation>> fetch({
    required String query,
    required int limit,
    String? country,
  }) async {
    final trimmed = query.trim();
    final code = country?.trim() ?? '';
    final stations = <RadioStation>[];

    if (code.isNotEmpty) {
      stations.addAll(
        await _read('/stations/search', {
          'countrycode': code,
          if (trimmed.isNotEmpty) 'name': trimmed,
          'limit': '$limit',
          'order': 'votes',
          'reverse': 'true',
        }),
      );
      if (trimmed.isNotEmpty) {
        stations.addAll(
          await _read('/stations/search', {
            'countrycode': code,
            'tagname': trimmed,
            'limit': '$limit',
            'order': 'votes',
            'reverse': 'true',
          }),
        );
      }
    } else if (trimmed.isEmpty) {
      stations.addAll(await _read('/stations/topclick/$limit'));
    } else {
      final byName = await _read('/stations/search', {
        'name': trimmed,
        'limit': '$limit',
        'order': 'votes',
        'reverse': 'true',
      });
      final byTag = await _read('/stations/search', {
        'tagname': trimmed,
        'limit': '$limit',
        'order': 'votes',
        'reverse': 'true',
      });
      stations.addAll(byName);
      stations.addAll(byTag);
    }

    final seen = <String>{};
    return stations
        .where((station) => seen.add(station.id))
        .take(limit)
        .toList(growable: false);
  }

  Future<List<RadioStation>> _read(
    String path, [
    Map<String, String> queryParameters = const {},
  ]) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base$path',
      queryParameters: {'hideuuid': 'true', ...queryParameters},
    );
    final data = response.data;
    if (data is! List) return const [];
    return parseStations(data);
  }

  /// Kept static so the mapping can be tested without network access.
  static List<RadioStation> parseStations(List<dynamic> data) {
    final stations = <RadioStation>[];

    for (final raw in data) {
      if (raw is! Map) continue;

      // A station that failed its last check is usually gone for good.
      if (raw['lastcheckok'] == 0) continue;

      final streamUrl = SourceSongFactory.normalizeUrl(
        raw['url_resolved']?.toString() ?? raw['url']?.toString(),
      );
      final name = raw['name']?.toString().trim() ?? '';
      final id = raw['stationuuid']?.toString() ?? '';
      if (streamUrl == null || name.isEmpty || id.isEmpty) continue;

      final tags = _split(raw['tags']);
      final languages = _split(raw['language']);

      stations.add(
        RadioStation(
          provider: 'browser',
          id: id,
          name: name,
          streamUrl: streamUrl,
          artworkUrl: SourceSongFactory.normalizeUrl(
            raw['favicon']?.toString(),
          ),
          genre: tags.isEmpty ? null : tags.take(3).join(' / '),
          language: languages.isEmpty ? null : languages.take(2).join(' / '),
          country: _text(raw['country']),
          codec: _text(raw['codec']),
          bitrate: SourceSongFactory.parseInt(raw['bitrate']),
          listeners: SourceSongFactory.parseInt(raw['clickcount']),
          homepage: SourceSongFactory.normalizeUrl(raw['homepage']?.toString()),
        ),
      );
    }

    return stations;
  }

  static List<String> _split(Object? value) {
    if (value is! String || value.trim().isEmpty) return const [];
    return value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

/// The curated channels of SomaFM.
///
/// Every channel states its genre, its host and what it plays, and the
/// directory keeps the track that is on air.
class SomaFmProvider extends RadioStationProvider {
  static const _channelsUrl = 'https://somafm.com/channels.json';
  static const _streamTemplate = 'https://ice1.somafm.com/{id}-128-mp3';

  final Dio _dio;

  SomaFmProvider({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: sourceRequestHeaders(
                extra: const {'Accept': 'application/json'},
              ),
            ),
          );

  @override
  String get id => 'somafm';

  @override
  String get displayName => 'SomaFM';

  @override
  Future<List<RadioStation>> fetch({
    required String query,
    required int limit,
    String? country,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(_channelsUrl);
    final data = response.data;
    if (data == null) {
      throw MusicSourceFailure(AppStrings.instance.radioNoChannelList);
    }

    final stations = parseChannels(data);
    final trimmed = query.trim().toLowerCase();
    final filtered = trimmed.isEmpty
        ? stations
        : stations.where((station) => _matches(station, trimmed)).toList();

    return filtered.take(limit).toList(growable: false);
  }

  static bool _matches(RadioStation station, String query) {
    final haystack = [
      station.name,
      station.genre ?? '',
      station.description ?? '',
      station.nowPlayingArtist ?? '',
      station.nowPlayingTitle ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  /// Kept static so the mapping can be tested without network access.
  static List<RadioStation> parseChannels(Map<String, dynamic> data) {
    final rawChannels = data['channels'];
    if (rawChannels is! List) return const [];

    final stations = <RadioStation>[];

    for (final raw in rawChannels) {
      if (raw is! Map) continue;

      final id = raw['id']?.toString() ?? '';
      final name = raw['title']?.toString().trim() ?? '';
      if (id.isEmpty || name.isEmpty) continue;

      final onAir = _splitOnAir(raw['lastPlaying']?.toString());

      stations.add(
        RadioStation(
          provider: 'somafm',
          id: id,
          name: name,
          streamUrl: _streamTemplate.replaceAll('{id}', id),
          artworkUrl: SourceSongFactory.normalizeUrl(
            raw['largeimage']?.toString() ?? raw['image']?.toString(),
          ),
          genre: _text(raw['genre']),
          description: _text(raw['description']),
          nowPlayingArtist: onAir.artist,
          nowPlayingTitle: onAir.title,
          listeners: SourceSongFactory.parseInt(raw['listeners']),
          homepage: 'https://somafm.com/$id/',
        ),
      );
    }

    return stations;
  }

  /// Splits `Artist - Title` into its two parts.
  static ({String? artist, String? title}) _splitOnAir(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return (artist: null, title: null);

    final separator = text.indexOf(' - ');
    if (separator <= 0) return (artist: null, title: text);
    return (
      artist: text.substring(0, separator).trim(),
      title: text.substring(separator + 3).trim(),
    );
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

/// The curated stations of Radio Paradise.
///
/// The directory reports the track that is on air together with its cover, so
/// a station shows what it plays before it is started.
class RadioParadiseProvider extends RadioStationProvider {
  static const _nowPlayingUrl = 'https://api.radioparadise.com/api/now_playing';

  /// The stations of the network and the address of their stream.
  static const _stations = <String, ({String code, String name, String url})>{
    'main': (code: 'rp-main', name: 'Radio Paradise Main', url: 'mp3-32'),
    'mellow': (
      code: 'rp-mellow',
      name: 'Radio Paradise Mellow',
      url: 'mellow-32',
    ),
    'eclectic': (
      code: 'rp-eclectic',
      name: 'Radio Paradise Eclectic',
      url: 'eclectic-32',
    ),
    'rock': (code: 'rp-rock', name: 'Radio Paradise Rock', url: 'rock-32'),
    'world': (code: 'rp-world', name: 'Radio Paradise World', url: 'world-32'),
  };

  final Dio _dio;

  RadioParadiseProvider({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: sourceRequestHeaders(
                extra: const {'Accept': 'application/json'},
              ),
            ),
          );

  @override
  String get id => 'paradise';

  @override
  String get displayName => 'Radio Paradise';

  @override
  Future<List<RadioStation>> fetch({
    required String query,
    required int limit,
    String? country,
  }) async {
    final trimmed = query.trim().toLowerCase();
    final selected = _stations.entries
        .where(
          (entry) =>
              trimmed.isEmpty ||
              entry.value.name.toLowerCase().contains(trimmed) ||
              entry.key.contains(trimmed),
        )
        .take(limit)
        .toList(growable: false);

    final stations = <RadioStation>[];
    for (final entry in selected) {
      stations.add(await _readStation(entry.key, entry.value));
    }
    return stations;
  }

  Future<RadioStation> _readStation(
    String key,
    ({String code, String name, String url}) station,
  ) async {
    var artist = '';
    var title = '';
    var album = '';
    var year = '';
    var cover = '';

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _nowPlayingUrl,
        queryParameters: {'station': station.code, 'api_key': 'nosec'},
      );
      final data = response.data;
      if (data != null) {
        artist = data['artist']?.toString() ?? '';
        title = data['title']?.toString() ?? '';
        album = data['album']?.toString() ?? '';
        year = data['year']?.toString() ?? '';
        cover = data['cover_med']?.toString() ?? '';
      }
    } catch (error) {
      // A station without its current track is still worth playing.
    }

    return RadioStation(
      provider: 'paradise',
      id: key,
      name: station.name,
      streamUrl: 'https://stream.radioparadise.com/${station.url}',
      artworkUrl: SourceSongFactory.normalizeUrl(cover),
      genre: 'eclectic',
      nowPlayingArtist: artist.isEmpty ? null : artist,
      nowPlayingTitle: title.isEmpty ? null : title,
      nowPlayingYear: int.tryParse(year),
      description: album.isEmpty ? null : album,
      homepage: 'https://radioparadise.com/',
    );
  }
}
