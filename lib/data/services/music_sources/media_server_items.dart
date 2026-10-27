import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/song.dart';

/// The items of a self-hosted media server and the tracks they become.
///
/// Jellyfin and Emby describe one track with the same fields and hand the
/// audio file out behind one address; only the prefix of the addresses
/// differs between the two. One read of an item therefore serves both
/// servers, and a scan of one asks the other for almost nothing.
class MediaServerItems {
  const MediaServerItems._();

  /// The name the server shows in its logs.
  static const clientName = 'Tune';

  /// The version the server shows in its logs.
  static const clientVersion = '1.1.0';

  /// A stable device id, so the server keeps the session of the app.
  static const deviceId = 'tune';

  /// The header both servers expect on a login.
  static String get authorizationHeader =>
      'MediaBrowser Client="$clientName", Device="$clientName", '
      'DeviceId="$deviceId", Version="$clientVersion"';

  /// The server address without a trailing slash.
  ///
  /// A bare host is accepted, because the address of a self-hosted server
  /// is often typed as `192.168.1.10:8096` and plain HTTP is the default
  /// there.
  static String? trimServerAddress(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;

    final withScheme = trimmed.contains('://') ? trimmed : 'http://$trimmed';
    final server = withScheme.replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(server);
    if (uri == null || uri.host.isEmpty) return null;
    return server;
  }

  /// The token of an answered login.
  static String? parseToken(Map<String, dynamic>? data) {
    final token = data?['AccessToken']?.toString().trim() ?? '';
    return token.isEmpty ? null : token;
  }

  /// The lyrics of a track.
  ///
  /// Older servers answer with a single text, newer ones with a list of
  /// texts that carry their language.
  static String? parseLyrics(Map<String, dynamic>? data) {
    if (data == null) return null;

    final raw = data['Lyrics'];
    if (raw is String) {
      final text = raw.trim();
      return text.isEmpty ? null : text;
    }
    if (raw is! List) return null;

    final parts = <String>[];
    for (final item in raw) {
      final text = item is String
          ? item.trim()
          : (item is Map ? item['Text']?.toString().trim() ?? '' : '');
      if (text.isNotEmpty) parts.add(text);
    }
    return parts.isEmpty ? null : parts.join('\n');
  }

  /// The length of a track in milliseconds.
  ///
  /// The server counts time in ticks of 100 nanoseconds, so a tick is a
  /// hundredth of a millisecond.
  static int durationFromTicks(Object? raw) {
    final ticks = SourceSongFactory.parseInt(raw);
    return ticks > 0 ? ticks ~/ 10000 : 0;
  }

  /// The playable address of a track.
  static String streamUrlFor(String server, String prefix, String itemId) =>
      '$server$prefix/Audio/${Uri.encodeComponent(itemId)}/stream?static=true';

  /// The cover of a track.
  ///
  /// The player loads the cover without the headers of the song, so the
  /// token travels in the query of the address.
  static String artworkUrlFor(
    String server,
    String prefix,
    String itemId, {
    String? token,
  }) {
    final base =
        '$server$prefix/Items/${Uri.encodeComponent(itemId)}/Images/Primary';
    if (token == null || token.isEmpty) return base;
    return '$base?api_key=${Uri.encodeComponent(token)}';
  }

  /// The tracks a page of items holds.
  static List<Song> parseItems(
    Map<String, dynamic> data, {
    required String sourceId,
    required String server,
    required String prefix,
    String? token,
    int limit = 50,
  }) {
    final rawItems = data['Items'];
    if (rawItems is! List) return const [];

    final songs = <Song>[];
    final seen = <String>{};
    for (final raw in rawItems) {
      if (raw is! Map) continue;
      if (songs.length >= limit) break;

      final id = raw['Id']?.toString() ?? '';
      final title = raw['Name']?.toString().trim() ?? '';
      if (id.isEmpty || title.isEmpty || !seen.add(id)) continue;

      final media = mediaSourceOf(raw);
      final genres = genresOf(raw);
      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: id,
          title: title,
          artist: artistOf(raw),
          album: raw['Album']?.toString() ?? '',
          duration: durationFromTicks(raw['RunTimeTicks']),
          streamUrl: streamUrlFor(server, prefix, id),
          artworkUrl: artworkUrlFor(server, prefix, id, token: token),
          genre: genres?.first,
          genres: genres,
          year: yearOf(raw),
          bitrate: kbpsOf(raw, media),
          sampleRate: khzOf(raw, media),
          trackNumber: positiveInt(raw['IndexNumber']),
          discNumber: positiveInt(raw['ParentIndexNumber']),
          size: sizeOf(media),
          httpHeaders: token == null || token.isEmpty
              ? null
              : {'X-Emby-Token': token},
        ),
      );
    }
    return songs;
  }

  /// The file behind a track, which holds the technical details.
  static Map<dynamic, dynamic> mediaSourceOf(Map<dynamic, dynamic> raw) {
    final sources = raw['MediaSources'];
    if (sources is! List || sources.isEmpty) return const {};
    final first = sources.first;
    return first is Map ? first : const {};
  }

  /// The artist of a track.
  ///
  /// The album artist names the band, the list of artists names the guests,
  /// so the album artist is the better choice.
  static String artistOf(Map<dynamic, dynamic> raw) {
    final albumArtist = raw['AlbumArtist']?.toString().trim() ?? '';
    if (albumArtist.isNotEmpty) return albumArtist;

    final artists = raw['Artists'];
    if (artists is List) {
      for (final artist in artists) {
        final name = artist?.toString().trim() ?? '';
        if (name.isNotEmpty) return name;
      }
    }
    return '';
  }

  static List<String>? genresOf(Map<dynamic, dynamic> raw) {
    final genres = raw['Genres'];
    if (genres is! List) return null;

    final names = genres
        .map((genre) => genre?.toString().trim() ?? '')
        .where((genre) => genre.isNotEmpty)
        .toList(growable: false);
    return names.isEmpty ? null : names;
  }

  static int? yearOf(Map<dynamic, dynamic> raw) {
    final year = SourceSongFactory.parseInt(
      raw['Year'] ?? raw['ProductionYear'],
    );
    return year > 0 ? year : null;
  }

  /// The bitrate in kbit/s.
  ///
  /// The server counts bits per second, the library stores kilobits.
  static int? kbpsOf(Map<dynamic, dynamic> raw, Map<dynamic, dynamic> media) {
    final bitrate = SourceSongFactory.parseInt(
      raw['Bitrate'] ?? media['Bitrate'],
    );
    return bitrate > 0 ? bitrate ~/ 1000 : null;
  }

  /// The sample rate in kHz.
  static int? khzOf(Map<dynamic, dynamic> raw, Map<dynamic, dynamic> media) {
    final rate = SourceSongFactory.parseInt(
      raw['SampleRate'] ?? media['SampleRate'],
    );
    return rate > 0 ? rate ~/ 1000 : null;
  }

  static int? positiveInt(Object? raw) {
    final value = SourceSongFactory.parseInt(raw);
    return value > 0 ? value : null;
  }

  static int? sizeOf(Map<dynamic, dynamic> media) {
    final size = SourceSongFactory.parseInt(media['Size']);
    return size > 0 ? size : null;
  }
}
