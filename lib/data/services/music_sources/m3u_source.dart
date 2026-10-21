import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// A source of tracks a playlist file names.
///
/// The reader gives the address of a playlist; every entry in it becomes a
/// track. An entry that is a relative path is read against the folder the
/// playlist lives in, so a playlist that travels with its music still works.
class M3uSourceAdapter extends MusicSourceAdapter {
  /// The most tracks one playlist may bring in.
  ///
  /// A playlist is a list the reader wrote down, so it is taken as it is;
  /// the ceiling only keeps a runaway file from filling the library.
  static const int maxEntries = 500;

  /// The key of a pls entry: `File1`, `File2` and the like.
  static final RegExp _plsFileKey = RegExp(
    r'^file\d+$',
    caseSensitive: false,
  );

  final Dio _dio;

  M3uSourceAdapter({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              responseType: ResponseType.plain,
            ),
          );

  @override
  String get sourceType => 'm3u';

  @override
  bool isConfigured(MusicSourceConfig config) =>
      config.setting('playlist') != null;

  @override
  String get configurationHint => AppStrings.instance.m3uHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'playlist',
      AppStrings.instance.m3uFieldPlaylist,
      AppStrings.instance.m3uFieldPlaylistHint,
      required: true,
    ),
  ];

  @override
  Duration get scanTimeout => const Duration(seconds: 30);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final playlist = request.config.setting('playlist');
    if (playlist == null) {
      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    if (!isHttpAddress(playlist)) {
      return failedResult(
        request.config.id,
        AppStrings.instance.sourceAddressNotHttp,
      );
    }

    try {
      final response = await _dio.get<String>(playlist);
      final body = response.data;
      if (body == null || body.trim().isEmpty) {
        return failedResult(
          request.config.id,
          AppStrings.instance.m3uEmptyPlaylist,
        );
      }

      final songs = parsePlaylist(
        body,
        sourceId: request.config.id,
        playlistUrl: playlist,
      );
      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.m3uNoEntries : null,
      );
    } catch (error) {
      return failedResult(request.config.id, error);
    }
  }

  /// The entries of a playlist, in the order they are written.
  ///
  /// Two shapes are read: the lines of an m3u and the `File1=` lines of a
  /// pls. A comment and a line that carries no address are dropped.
  static List<String> parseEntries(String body) {
    final lines = body.split('\n');
    final isPls = lines.any(
      (line) => line.trim().toLowerCase() == '[playlist]',
    );

    final entries = <String>[];
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      if (isPls) {
        final entry = _plsEntry(line);
        if (entry != null) entries.add(entry);
        continue;
      }

      if (line.startsWith('#')) continue;
      entries.add(line);
    }
    return entries;
  }

  /// The address of a `FileN=` line of a pls, when the line carries one.
  static String? _plsEntry(String line) {
    final separator = line.indexOf('=');
    if (separator < 0) return null;

    final key = line.substring(0, separator).trim();
    if (!_plsFileKey.hasMatch(key)) return null;

    final value = line.substring(separator + 1).trim();
    return value.isEmpty ? null : value;
  }

  /// The address of an entry, read against the playlist it came from.
  ///
  /// A relative entry points into the folder the playlist lives in, so it is
  /// resolved there. An entry that is already an address is kept as it is.
  static String? resolveEntry(String entry, String playlistUrl) {
    final trimmed = entry.trim();
    if (trimmed.isEmpty) return null;

    final direct = SourceSongFactory.normalizeUrl(trimmed);
    if (direct != null) return direct;

    final base = Uri.tryParse(playlistUrl);
    if (base == null) return null;

    return SourceSongFactory.normalizeUrl(base.resolve(trimmed).toString());
  }

  /// The tracks of a playlist.
  ///
  /// The same address twice is one track: a playlist that lists a song in
  /// two sections does not bring it in twice.
  static List<Song> parsePlaylist(
    String body, {
    required String sourceId,
    required String playlistUrl,
    int limit = maxEntries,
  }) {
    final songs = <Song>[];
    final seen = <String>{};

    for (final entry in parseEntries(body)) {
      if (songs.length >= limit) break;

      final address = resolveEntry(entry, playlistUrl);
      if (address == null) continue;
      if (!seen.add(address)) continue;

      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: address,
          title: SourceSongFactory.titleFromUrl(address),
          streamUrl: address,
        ),
      );
    }
    return songs;
  }
}
