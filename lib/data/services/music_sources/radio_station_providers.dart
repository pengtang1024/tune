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
  /// The directory answers through any of its mirrors. The aggregate name is
  /// tried first, then two mirrors, so a network that cannot reach one of
  /// them (a broken IPv6 route, a blocked name) still reads the directory.
  static const _hosts = [
    'https://all.api.radio-browser.info/json',
    'https://de1.api.radio-browser.info/json',
    'https://de2.api.radio-browser.info/json',
  ];

  /// The mirror that answered last, tried first on the next request.
  String? _base;

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
  bool get supportsPaging => true;

  @override
  Future<List<RadioStation>> fetch({
    required String query,
    required int limit,
    String? country,
    int offset = 0,
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
          if (offset > 0) 'offset': '$offset',
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
            if (offset > 0) 'offset': '$offset',
            'order': 'votes',
            'reverse': 'true',
          }),
        );
      }
    } else if (trimmed.isEmpty) {
      stations.addAll(
        await _read('/stations/topclick/$limit', {
          if (offset > 0) 'offset': '$offset',
        }),
      );
    } else {
      final byName = await _read('/stations/search', {
        'name': trimmed,
        'limit': '$limit',
        if (offset > 0) 'offset': '$offset',
        'order': 'votes',
        'reverse': 'true',
      });
      final byTag = await _read('/stations/search', {
        'tagname': trimmed,
        'limit': '$limit',
        if (offset > 0) 'offset': '$offset',
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
    DioException? failure;
    final preferred = _base;
    final hosts = preferred == null
        ? _hosts
        : [preferred, ..._hosts.where((host) => host != preferred)];

    for (final host in hosts) {
      try {
        final response = await _dio.get<List<dynamic>>(
          '$host$path',
          queryParameters: {'hideuuid': 'true', ...queryParameters},
        );
        _base = host;
        final data = response.data;
        if (data is! List) return const [];
        return parseStations(data);
      } on DioException catch (error) {
        failure = error;
        if (!_isUnreachable(error)) rethrow;
      }
    }
    throw failure!;
  }

  /// Whether a mirror could not be reached at all, as opposed to answering
  /// with an error of its own. Only the former is worth trying elsewhere.
  static bool _isUnreachable(DioException error) =>
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.unknown;

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
    int offset = 0,
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
    int offset = 0,
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

/// The live channels of NTS.
///
/// The station publishes what is on air right now: the show, its genres, its
/// moods and the picture of the show. A live answer names a show rather than a
/// track, so the show stands where the performer stands in a station that
/// knows its record.
class NtsProvider extends RadioStationProvider {
  static const _liveUrl = 'https://www.nts.live/api/v2/live';

  /// The address of the stream of each channel.
  static const _streams = <String, String>{
    '1': 'https://stream-relay-geo.ntslive.net/stream',
    '2': 'https://stream-relay-geo.ntslive.net/stream2',
  };

  final Dio _dio;

  NtsProvider({Dio? dio})
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
  String get id => 'nts';

  @override
  String get displayName => 'NTS';

  @override
  Future<List<RadioStation>> fetch({
    required String query,
    required int limit,
    String? country,
    int offset = 0,
  }) async {
    // Both channels are broadcast from London; a scan of another country has
    // nothing to take from them.
    final code = country?.trim().toUpperCase() ?? '';
    if (code.isNotEmpty && code != 'GB' && code != 'UK') return const [];

    final response = await _dio.get<Map<String, dynamic>>(_liveUrl);
    final data = response.data;
    if (data == null) {
      throw MusicSourceFailure(AppStrings.instance.radioNoChannelList);
    }

    final stations = parseLive(data);
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
      station.country ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  /// Kept static so the mapping can be tested without network access.
  static List<RadioStation> parseLive(Map<String, dynamic> data) {
    final results = data['results'];
    if (results is! List) return const [];

    final stations = <RadioStation>[];

    for (final raw in results) {
      if (raw is! Map) continue;

      final channel = raw['channel_name']?.toString().trim() ?? '';
      final streamUrl = _streams[channel];
      if (streamUrl == null) continue;

      final now = raw['now'];
      final nowMap = now is Map ? now : const <dynamic, dynamic>{};
      final embeds = nowMap['embeds'];
      final embedsMap = embeds is Map ? embeds : const <dynamic, dynamic>{};
      final details = embedsMap['details'];
      final detailsMap = details is Map
          ? details
          : const <dynamic, dynamic>{};
      final media = detailsMap['media'];
      final mediaMap = media is Map ? media : const <dynamic, dynamic>{};

      final show =
          _text(detailsMap['name']) ?? _text(nowMap['broadcast_title']);
      final genres = _values(detailsMap['genres']);

      stations.add(
        RadioStation(
          provider: 'nts',
          id: channel,
          name: 'NTS $channel',
          streamUrl: streamUrl,
          artworkUrl: SourceSongFactory.normalizeUrl(
            _text(mediaMap['background_large']) ??
                _text(mediaMap['background_medium']),
          ),
          genre: genres.isEmpty ? null : genres.take(3).join(' / '),
          language: 'English',
          country: 'United Kingdom',
          description: _text(detailsMap['description']),
          nowPlayingArtist: show,
          codec: 'MP3',
          homepage: 'https://www.nts.live/',
        ),
      );
    }

    return stations;
  }

  static List<String> _values(Object? value) {
    if (value is! List) return const [];
    return value
        .map((entry) => entry is Map ? _text(entry['value']) : null)
        .whereType<String>()
        .toList(growable: false);
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

/// The music stations of Radio France.
///
/// FIP, France Musique and Mouv' broadcast a fixed set of channels, each of
/// them a direct icecast stream. There is no directory request and no key, so
/// the channel list lives in the code and a scan is a local operation.
class RadioFranceProvider extends RadioStationProvider {
  static const _streamBase = 'https://icecast.radiofrance.fr';

  /// The channels of the network, in the order the network lists them.
  static const List<_RadioFranceChannel> _channels = [
    _RadioFranceChannel(
      'fip',
      'FIP',
      'eclectic',
      'Jazz, rock, electronic and world music',
      'https://www.radiofrance.fr/fip',
    ),
    _RadioFranceChannel(
      'fipjazz',
      'FIP Jazz',
      'jazz',
      'Jazz of every era',
      'https://www.radiofrance.fr/fip/radio-jazz',
    ),
    _RadioFranceChannel(
      'fipgroove',
      'FIP Groove',
      'soul',
      'Soul, funk and groove',
      'https://www.radiofrance.fr/fip/radio-groove',
    ),
    _RadioFranceChannel(
      'fiprock',
      'FIP Rock',
      'rock',
      'Rock of every decade',
      'https://www.radiofrance.fr/fip/radio-rock',
    ),
    _RadioFranceChannel(
      'fipelectro',
      'FIP Electro',
      'electronic',
      'Electronic music and club sounds',
      'https://www.radiofrance.fr/fip/radio-electro',
    ),
    _RadioFranceChannel(
      'fipreggae',
      'FIP Reggae',
      'reggae',
      'Reggae, dub and roots',
      'https://www.radiofrance.fr/fip/radio-reggae',
    ),
    _RadioFranceChannel(
      'fipmetal',
      'FIP Metal',
      'metal',
      'Metal and its neighbours',
      'https://www.radiofrance.fr/fip/radio-metal',
    ),
    _RadioFranceChannel(
      'fiphiphop',
      'FIP Hip-Hop',
      'hip hop',
      'Hip-hop and rap',
      'https://www.radiofrance.fr/fip/radio-hip-hop',
    ),
    _RadioFranceChannel(
      'fippop',
      'FIP Pop',
      'pop',
      'Pop songs and their writers',
      'https://www.radiofrance.fr/fip/radio-pop',
    ),
    _RadioFranceChannel(
      'fipworld',
      'FIP World',
      'world',
      'Music from every continent',
      'https://www.radiofrance.fr/fip/radio-world',
    ),
    _RadioFranceChannel(
      'fipnouveautes',
      'FIP Nouveautés',
      'new releases',
      'The records of the moment',
      'https://www.radiofrance.fr/fip/radio-nouveautes',
    ),
    _RadioFranceChannel(
      'fipsacrefrancais',
      'FIP Sacré Français',
      'chanson',
      'French song of every generation',
      'https://www.radiofrance.fr/fip/radio-sacre-francais',
    ),
    _RadioFranceChannel(
      'francemusique',
      'France Musique',
      'classical',
      'Classical music, concerts and opera',
      'https://www.radiofrance.fr/francemusique',
    ),
    _RadioFranceChannel(
      'francemusiquebaroque',
      'France Musique Baroque',
      'baroque',
      'Baroque music from its sources',
      'https://www.radiofrance.fr/francemusique/radio-baroque',
    ),
    _RadioFranceChannel(
      'francemusiqueopera',
      'France Musique Opéra',
      'opera',
      'Opera and its voices',
      'https://www.radiofrance.fr/francemusique/radio-opera',
    ),
    _RadioFranceChannel(
      'francemusiquelajazz',
      'France Musique La Jazz',
      'jazz',
      'Jazz heard by France Musique',
      'https://www.radiofrance.fr/francemusique/radio-jazz',
    ),
    _RadioFranceChannel(
      'francemusiquelacontemporaine',
      'France Musique Contemporaine',
      'contemporary classical',
      'Music written today',
      'https://www.radiofrance.fr/francemusique/radio-contemporaine',
    ),
    _RadioFranceChannel(
      'mouv',
      'Mouv\'',
      'hip hop',
      'Hip-hop and youth culture',
      'https://www.radiofrance.fr/mouv',
    ),
  ];

  @override
  String get id => 'radiofrance';

  @override
  String get displayName => 'Radio France';

  @override
  Future<List<RadioStation>> fetch({
    required String query,
    required int limit,
    String? country,
    int offset = 0,
  }) async {
    // Every channel is broadcast from Paris; a scan of another country has
    // nothing to take from the network.
    final code = country?.trim().toUpperCase() ?? '';
    if (code.isNotEmpty && code != 'FR' && code != 'FRA' && code != 'FRANCE') {
      return const [];
    }

    final trimmed = query.trim().toLowerCase();
    final selected = trimmed.isEmpty
        ? _channels
        : _channels
              .where((channel) => _matches(channel, trimmed))
              .toList(growable: false);

    return selected
        .skip(offset)
        .take(limit)
        .map(_station)
        .toList(growable: false);
  }

  static bool _matches(_RadioFranceChannel channel, String query) {
    final haystack = [
      channel.name,
      channel.genre,
      channel.description,
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  static RadioStation _station(_RadioFranceChannel channel) {
    return RadioStation(
      provider: 'radiofrance',
      id: channel.slug,
      name: channel.name,
      streamUrl: '$_streamBase/${channel.slug}-midfi.mp3',
      genre: channel.genre,
      language: 'French',
      country: 'France',
      description: channel.description,
      codec: 'MP3',
      homepage: channel.homepage,
    );
  }
}

/// One channel of Radio France.
///
/// The fields are positional on purpose: the catalogue is data a broadcaster
/// publishes, not interface text, so it stays out of the translated strings.
class _RadioFranceChannel {
  const _RadioFranceChannel(
    this.slug,
    this.name,
    this.genre,
    this.description,
    this.homepage,
  );

  final String slug;
  final String name;
  final String genre;
  final String description;
  final String homepage;
}
