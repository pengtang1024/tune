import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/shared/utils/short_description.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// ccMixter is an open catalogue of Creative Commons music and remixes.
///
/// The public API works without a key. The audio files are served with a
/// hotlink check, so every song carries the `Referer` header the site
/// expects; without it the download answers with HTTP 403.
class CcMixterSourceAdapter extends MusicSourceAdapter {
  /// How many tracks a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(15, 30);

  static const _endpoint = 'https://ccmixter.org/api/query';
  static const _referer = 'https://ccmixter.org/';

  final Dio _dio;

  CcMixterSourceAdapter({Dio? dio})
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
  String get sourceType => 'ccmixter';

  /// The source asks nothing of the reader, so it belongs to the top
  /// of the list.
  @override
  bool get featured => true;

  /// ccMixter serves its own newest uploads and its own charts, so the
  /// source is ready as it is: a keyword is a choice, not a requirement.
  @override
  List<String> get browseModes => const [BrowseMode.charts, BrowseMode.latest];

  @override
  bool isConfigured(MusicSourceConfig config) => true;

  @override
  String get configurationHint => AppStrings.instance.ccmixterHint;

  /// The licences the site narrows by, as the values of the field.
  ///
  /// The site files an upload under the licence it was published with and
  /// narrows by that word; the three values here were read back from it, and a
  /// word it does not know is answered with an error instead of the list.
  static const _licences = {'by', 'nc', 'pd'};

  static String? _licenceFilterOf(String? raw) {
    final value = raw?.trim() ?? '';
    return _licences.contains(value) ? value : null;
  }

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQueryOptional,
      AppStrings.instance.ccmixterFieldQueryHint,
    ),
    MusicSourceField(
      'licence',
      AppStrings.instance.ccmixterFieldLicence,
      AppStrings.instance.ccmixterFieldLicenceHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.ccmixterLicenceAll),
        MusicSourceChoice('by', AppStrings.instance.ccmixterLicenceBy),
        MusicSourceChoice('nc', AppStrings.instance.ccmixterLicenceNc),
        MusicSourceChoice('pd', AppStrings.instance.ccmixterLicencePd),
      ],
    ),
    MusicSourceField(
      'tag',
      AppStrings.instance.ccmixterFieldTag,
      AppStrings.instance.ccmixterFieldTagHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.ccmixterTagAll),
        for (final entry in _tags.entries)
          MusicSourceChoice(entry.key, entry.value),
      ],
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.fieldLimit,
      AppStrings.instance.fieldLimitHint(scanLimit.count, scanLimit.max),
      numeric: true,
    ),
  ];


  /// The tags the site files its uploads under, by the name the reader picks.
  ///
  /// Only the tags that were found to hold uploads are offered; a tag the
  /// site does not know answers with nothing at all.
  static Map<String, String> get _tags {
    final strings = AppStrings.instance;
    return {
      'jazz': strings.genreJazz,
      'rock': strings.genreRock,
      'pop': strings.genrePop,
      'classical': strings.genreClassical,
      'folk': strings.genreFolk,
      'electronic': strings.audiusGenreElectronic,
      'reggae': strings.genreReggae,
      'funk': strings.ccmixterTagFunk,
      'hip_hop': strings.audiusGenreHipHop,
      'ambient': strings.ccmixterTagAmbient,
      'chill': strings.ccmixterTagChill,
      'instrumental': strings.ccmixterTagInstrumental,
      'piano': strings.wikimediaCategoryPiano,
    };
  }

  @override
  bool get supportsPaging => true;

  @override
  Duration get autoScanInterval => const Duration(hours: 6);

  @override
  Duration get scanTimeout => const Duration(seconds: 40);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final query = request.config.setting('query');

    try {
      final limit = scanLimit.read(request.config.setting('limit'));
      final parameters = <String, dynamic>{
        'f': 'json',
        'limit': limit,
        if (request.offset > 0) 'offset': request.offset,
      };
      final tag = request.config.setting('tag')?.trim() ?? '';
      final tags = [
        ?query,
        if (tag.isNotEmpty) tag,
      ].join(',');
      if (tags.isNotEmpty) {
        // The site reads the tags of an upload: several tags narrow together,
        // so the keyword and the genre are asked for as one word.
        parameters['tags'] = tags;
      } else if (browseModeOf(request.config) == BrowseMode.charts) {
        // The charts of the site: the uploads everybody downloaded most.
        parameters['sort'] = 'rank';
      }

      // The site narrows by licence through the same word it files the upload
      // under; the values are read back from it, and a word it does not know
      // is answered with no upload at all.
      final licence = _licenceFilterOf(request.config.setting('licence'));
      if (licence != null) parameters['lic'] = licence;

      final response = await _dio.get<String>(
        _endpoint,
        queryParameters: parameters,
        // The API answers with `text/plain`, so the body is decoded here
        // instead of by the transformer.
        options: Options(responseType: ResponseType.plain),
      );
      final body = response.data;
      if (body == null || body.trim().isEmpty) {
        return failedResult(
          request.config.id,
          AppStrings.instance.ccmixterEmptyResponse,
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! List) {
        return failedResult(
          request.config.id,
          AppStrings.instance.ccmixterEmptyResponse,
        );
      }

      final songs = parseResults(decoded, sourceId: request.config.id);
      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.ccmixterNoMatch : null,
      );
    } catch (error) {
      return failedResult(request.config.id, error);
    }
  }


  /// The description of an upload, as plain text.
  ///
  /// The site offers both the plain text and the HTML of an upload; the plain
  /// text is used as it is, and the HTML when there is no plain text.
  static String? _descriptionOf(Map raw) {
    final plain = raw['upload_description_plain']?.toString() ?? '';
    return plain.trim().isEmpty
        ? shortDescription(raw['upload_description_html'])
        : shorten(plain);
  }

  /// The licence of an upload, read back from the address of its deed.
  static String? _licenceOf(String? raw) {
    final value = raw?.trim().toLowerCase() ?? '';
    if (value.isEmpty || !value.contains('creativecommons.org')) return null;
    final segments = Uri.tryParse(value)?.pathSegments ?? const <String>[];
    final index = segments.indexOf('licenses');
    if (index < 0 || index + 1 >= segments.length) return null;
    final code = segments[index + 1].toUpperCase();
    final version = index + 2 < segments.length ? segments[index + 2] : '';
    return version.isEmpty ? 'CC $code' : 'CC $code $version';
  }

  /// Kept static so JSON mapping can be tested without network access.
  static List<Song> parseResults(
    List<dynamic> data, {
    required String sourceId,
  }) {
    final songs = <Song>[];
    final seen = <String>{};

    for (final raw in data) {
      if (raw is! Map) continue;

      final uploadId = raw['upload_id']?.toString() ?? '';
      final title = raw['upload_name']?.toString().trim() ?? '';
      if (uploadId.isEmpty || title.isEmpty || !seen.add(uploadId)) continue;

      final file = _pickAudioFile(raw['files']);
      if (file == null) continue;

      final streamUrl = SourceSongFactory.normalizeUrl(
        file['download_url']?.toString(),
      );
      if (streamUrl == null) continue;

      final extra = raw['upload_extra'];
      final extraMap = extra is Map ? extra : const <dynamic, dynamic>{};
      final tags = extraMap['usertags']?.toString() ?? '';
      final genre = _firstTag(tags);
      final license = raw['license_name']?.toString().trim() ?? '';
      final description = _descriptionOf(raw);

      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: uploadId,
          title: title,
          artist: raw['user_name']?.toString() ?? '',
          duration: _parseDuration(file),
          streamUrl: streamUrl,
          genre: genre,
          httpHeaders: const {'Referer': _referer},
          // The site names the licence of every upload; the name it gives is
          // the one the reader sees, and the deed address is the fallback.
          license: license.isNotEmpty
              ? license
              : _licenceOf(raw['license_url']?.toString()),
          description: description,
          sourceData: {
            'uploadId': uploadId,
            if (license.isNotEmpty) 'license': license,
          },
        ),
      );
    }

    return songs;
  }

  /// Picks the best audio file of an upload.
  ///
  /// An upload also carries the stems of the track and its archive, so only
  /// files that the API marks as audio are usable. MP3 comes first because it
  /// plays everywhere, the other formats stay as a fallback.
  static Map? _pickAudioFile(Object? rawFiles) {
    if (rawFiles is! List) return null;

    Map? fallback;
    for (final raw in rawFiles) {
      if (raw is! Map) continue;
      final format = raw['file_format_info'];
      final formatMap = format is Map ? format : const <dynamic, dynamic>{};
      if (formatMap['media-type']?.toString() != 'audio') continue;
      if (raw['download_url'] == null) continue;

      if (formatMap['mime_type']?.toString() == 'audio/mpeg') return raw;
      fallback ??= raw;
    }

    return fallback;
  }

  static String? _firstTag(String tags) {
    for (final tag in tags.split(',')) {
      final trimmed = tag.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  /// Reads the playback length the API reports as `m:ss`.
  static int _parseDuration(Map file) {
    final format = file['file_format_info'];
    final formatMap = format is Map ? format : const <dynamic, dynamic>{};
    final text = formatMap['ps']?.toString().trim() ?? '';
    if (text.isEmpty) return 0;

    final parts = text.split(':').map(int.tryParse).toList(growable: false);
    if (parts.isEmpty || parts.any((part) => part == null)) return 0;

    var seconds = 0;
    for (final part in parts) {
      seconds = seconds * 60 + part!;
    }
    return seconds * 1000;
  }
}
