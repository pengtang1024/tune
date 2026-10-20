import 'package:dio/dio.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Internet Archive exposes a large collection of freely downloadable audio.
///
/// The advanced search returns item identifiers, and a second metadata request
/// resolves the first playable audio file inside each item.
class InternetArchiveSourceAdapter extends MusicSourceAdapter {
  /// How many tracks a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(8, 20);

  static const _audioExtensions = ['.mp3', '.ogg', '.m4a', '.flac'];

  final Dio _dio;

  InternetArchiveSourceAdapter({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: const {'Accept': 'application/json'},
            ),
          );

  @override
  String get sourceType => 'internet_archive';

  /// The archive serves the audio everybody downloaded most, so the source
  /// is ready as it is: a keyword is a choice, not a requirement.
  @override
  List<String> get browseModes => const [BrowseMode.charts];

  @override
  bool isConfigured(MusicSourceConfig config) => true;

  @override
  String get configurationHint => AppStrings.instance.internetArchiveHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'query',
      AppStrings.instance.internetArchiveFieldQuery,
      'collection:netlabels AND mediatype:audio',
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.fieldLimit,
      AppStrings.instance.fieldLimitHint(scanLimit.count, scanLimit.max),
      numeric: true,
    ),
  ];

  @override
  Duration get autoScanInterval => const Duration(hours: 12);

  @override
  Duration get scanTimeout => const Duration(minutes: 2);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final query = request.config.setting('query');

    try {
      final limit = scanLimit.read(request.config.setting('limit'));
      final response = await _dio.get<Map<String, dynamic>>(
        'https://archive.org/advancedsearch.php',
        queryParameters: {
          // Without a keyword the archive serves the audio everybody
          // downloaded most.
          'q': query ?? 'mediatype:audio',
          'fl[]': ['identifier', 'title', 'creator', 'date'],
          'rows': limit,
          'page': 1,
          'output': 'json',
          'sort[]': 'downloads desc',
        },
      );

      final data = response.data;
      final searchResponse = data?['response'];
      final docs = searchResponse is Map ? searchResponse['docs'] : null;
      if (docs is! List) {
        return failedResult(
          request.config.id,
          AppStrings.instance.internetArchiveInvalidResponse,
        );
      }

      final songs = <Song>[];
      const batchSize = 4;
      for (var start = 0; start < docs.length; start += batchSize) {
        final batch = docs.skip(start).take(batchSize).toList(growable: false);
        final tracks = await Future.wait(
          batch.map((doc) => _fetchTrack(doc, request.config)),
        );
        songs.addAll(tracks.whereType<Song>());
        request.onProgress?.call(
          docs.isEmpty ? 1 : ((start + batch.length) / docs.length).clamp(0, 1),
        );
      }

      final unique = <String, Song>{};
      for (final song in songs) {
        unique[song.uri] = song;
      }

      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.success,
        songs: unique.values.toList(growable: false),
        message: unique.isEmpty
            ? AppStrings.instance.internetArchiveNoMatch
            : null,
      );
    } catch (error) {
      return failedResult(request.config.id, error);
    }
  }

  Future<Song?> _fetchTrack(Object? rawDoc, MusicSourceConfig config) async {
    if (rawDoc is! Map) return null;

    final identifier = rawDoc['identifier']?.toString() ?? '';
    if (identifier.isEmpty) return null;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://archive.org/metadata/${Uri.encodeComponent(identifier)}',
        options: Options(receiveTimeout: const Duration(seconds: 15)),
      );
      final data = response.data;
      if (data == null) return null;

      final files = data['files'];
      final file = _pickAudioFile(files);
      if (file == null) return null;

      final fileName = file['name']?.toString() ?? '';
      if (fileName.isEmpty) return null;

      final metadata = data['metadata'];
      final metadataMap = metadata is Map
          ? metadata
          : const <dynamic, dynamic>{};
      final title =
          SourceSongFactory.readString(metadataMap['title']).trim().isNotEmpty
          ? SourceSongFactory.readString(metadataMap['title'])
          : SourceSongFactory.readString(rawDoc['title']);
      if (title.trim().isEmpty) return null;

      final artist =
          SourceSongFactory.readString(metadataMap['creator']).trim().isNotEmpty
          ? SourceSongFactory.readString(metadataMap['creator'])
          : SourceSongFactory.readString(rawDoc['creator']);

      final date = SourceSongFactory.readString(
        metadataMap['date'] ?? metadataMap['publicdate'],
      );
      final year = date.length >= 4 ? int.tryParse(date.substring(0, 4)) : null;
      final encodedPath = fileName
          .split('/')
          .map(Uri.encodeComponent)
          .join('/');

      return SourceSongFactory.create(
        sourceId: config.id,
        externalId: '$identifier/$fileName',
        title: title,
        artist: artist,
        album: SourceSongFactory.readString(metadataMap['album']),
        duration: _parseDuration(file['length']),
        streamUrl:
            'https://archive.org/download/${Uri.encodeComponent(identifier)}/$encodedPath',
        artworkUrl:
            'https://archive.org/services/img/${Uri.encodeComponent(identifier)}',
        genre: SourceSongFactory.readString(metadataMap['genre']),
        year: year,
      );
    } catch (_) {
      // One broken archive item should not fail the whole source.
      return null;
    }
  }

  Map? _pickAudioFile(Object? rawFiles) {
    if (rawFiles is! List) return null;

    Map? fallback;
    for (final raw in rawFiles) {
      if (raw is! Map) continue;

      final name = raw['name']?.toString().toLowerCase() ?? '';
      final format = raw['format']?.toString().toLowerCase() ?? '';
      if (format.contains('torrent') ||
          format.contains('metadata') ||
          format.contains('item tile')) {
        continue;
      }

      final isAudio = _audioExtensions.any(name.endsWith);
      if (!isAudio) continue;

      if (format.contains('vbr mp3') || format == 'mp3') {
        return raw;
      }
      fallback ??= raw;
    }

    return fallback;
  }

  int _parseDuration(Object? raw) {
    if (raw == null) return 0;

    final text = raw.toString().trim();
    if (text.isEmpty) return 0;

    if (text.contains(':')) {
      final parts = text.split(':').map(int.tryParse).toList(growable: false);
      if (parts.any((part) => part == null)) return 0;
      var seconds = 0;
      for (final part in parts) {
        seconds = seconds * 60 + part!;
      }
      return seconds * 1000;
    }

    final seconds = double.tryParse(text);
    if (seconds == null) return 0;
    return (seconds * 1000).round();
  }
}
