import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_request_headers.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Openverse aggregates openly licensed audio from Jamendo, Freesound,
/// Wikimedia Commons, ccMixter and other open catalogues.
///
/// The API works without a key. Anonymous requests are rate limited, so the
/// source is scanned at most once per [autoScanInterval].
class OpenverseSourceAdapter extends MusicSourceAdapter {
  final Dio _dio;

  OpenverseSourceAdapter({Dio? dio})
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
  String get sourceType => 'openverse';

  /// The source asks nothing of the reader, so it belongs to the top
  /// of the list.
  @override
  bool get featured => true;

  /// Openverse serves the audio it published last, so the source is ready as
  /// it is: a keyword is a choice, not a requirement.
  @override
  List<String> get browseModes => const [BrowseMode.latest];

  @override
  bool isConfigured(MusicSourceConfig config) => true;

  @override
  String get configurationHint => AppStrings.instance.openverseHint;

  /// The catalogues Openverse audio comes from, by the name the service knows
  /// them by.
  ///
  /// Wikimedia Commons is a catalogue of the service too, but its audio is
  /// mostly pronunciation samples rather than music, so it is not offered
  /// here: the music of the commons is read by the wikimedia source, which
  /// browses its own categories.
  static const _sources = ['jamendo', 'freesound'];

  /// The licences the service files its audio under, by the name it uses.
  ///
  /// Only the licences that were found to hold audio are offered: the public
  /// domain mark answers with nothing for audio.
  static const _licences = [
    'cc0',
    'by',
    'by-sa',
    'by-nc',
    'by-nd',
    'by-nc-sa',
    'by-nc-nd',
  ];

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQueryOptional,
      AppStrings.instance.openverseFieldQueryHint,
    ),
    MusicSourceField(
      'license',
      AppStrings.instance.openverseFieldLicense,
      AppStrings.instance.openverseFieldLicenseHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.openverseLicenseAll),
        for (final licence in _licences)
          MusicSourceChoice(licence, _licenceLabel(licence)),
      ],
    ),
    MusicSourceField(
      'source',
      AppStrings.instance.openverseFieldSource,
      AppStrings.instance.openverseFieldSourceHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.openverseSourceAll),
        MusicSourceChoice(_sources[0], AppStrings.instance.openverseSourceJamendo),
        MusicSourceChoice(
          _sources[1],
          AppStrings.instance.openverseSourceFreesound,
        ),
      ],
    ),
  ];

  @override
  bool get supportsPaging => true;

  @override
  Duration get autoScanInterval => const Duration(hours: 6);

  @override
  Duration get scanTimeout => const Duration(seconds: 35);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final query = request.config.setting('query');
    final source = request.config.setting('source')?.trim() ?? '';
    final licence = request.config.setting('license')?.trim() ?? '';

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.openverse.org/v1/audio/',
        // Without a keyword the service serves the audio it published last.
        // A source narrows the answer to one catalogue, which the service
        // filters on without a keyword.
        queryParameters: {
          'q': ?query,
          if (source.isNotEmpty && _sources.contains(source)) 'source': source,
          if (licence.isNotEmpty && _licences.contains(licence))
            'license': licence,
          'page_size': 20,
          'page': request.offset ~/ 20 + 1,
        },
      );
      final data = response.data;
      if (data == null) {
        return failedResult(
          request.config.id,
          AppStrings.instance.openverseEmptyResponse,
        );
      }

      final songs = parseResults(data, sourceId: request.config.id);
      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.openverseNoMatch : null,
      );
    } catch (error) {
      return failedResult(request.config.id, error);
    }
  }


  /// The name of a licence in the language of the reader.
  static String _licenceLabel(String licence) {
    final strings = AppStrings.instance;
    return switch (licence) {
      'cc0' => strings.openverseLicenceCc0,
      'by' => strings.openverseLicenceBy,
      'by-sa' => strings.openverseLicenceBySa,
      'by-nc' => strings.openverseLicenceByNc,
      'by-nd' => strings.openverseLicenceByNd,
      'by-nc-sa' => strings.openverseLicenceByNcSa,
      _ => strings.openverseLicenceByNcNd,
    };
  }

  /// The licence of a track, written the way the reader knows it.
  static String? _licenceText(Object? raw) {
    final code = raw?.toString().trim().toLowerCase() ?? '';
    if (code.isEmpty) return null;
    if (code == 'cc0') return 'CC0';
    if (code == 'pdm') return 'Public domain';
    return 'CC ${code.toUpperCase()}';
  }

  /// Kept static so JSON mapping can be tested without network access.
  static List<Song> parseResults(
    Map<String, dynamic> data, {
    required String sourceId,
  }) {
    final rawResults = data['results'];
    if (rawResults is! List) return const [];

    final songs = <Song>[];
    final seen = <String>{};

    for (final raw in rawResults) {
      if (raw is! Map) continue;

      final externalId = raw['id']?.toString() ?? '';
      final title = raw['title']?.toString().trim() ?? '';
      final streamUrl = SourceSongFactory.normalizeUrl(raw['url']?.toString());
      if (externalId.isEmpty ||
          title.isEmpty ||
          streamUrl == null ||
          !seen.add(externalId)) {
        continue;
      }

      final audioSet = raw['audio_set'];
      final album = audioSet is Map
          ? (audioSet['title']?.toString() ?? '')
          : (raw['provider']?.toString() ?? '');

      final rawGenres = raw['genres'];
      final genre = rawGenres is List && rawGenres.isNotEmpty
          ? rawGenres.first?.toString()
          : null;

      final thumbnail = SourceSongFactory.normalizeUrl(
        raw['thumbnail']?.toString(),
      );

      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: externalId,
          title: title,
          artist: raw['creator']?.toString() ?? '',
          album: album,
          duration: SourceSongFactory.parseInt(raw['duration']),
          streamUrl: streamUrl,
          artworkUrl:
              thumbnail ??
              'https://api.openverse.org/v1/audio/$externalId/thumb/',
          genre: genre,
          // The licence travels with the track: a reader who wants to reuse
          // what they hear sees it where the source tells it.
          license: _licenceText(raw['license']),
        ),
      );
    }

    return songs;
  }
}
