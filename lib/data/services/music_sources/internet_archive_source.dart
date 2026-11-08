import 'package:dio/dio.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/recent_window.dart';
import 'package:tune/data/services/music_sources/source_retry.dart';
import 'package:tune/shared/utils/short_description.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Internet Archive exposes a large collection of freely downloadable audio.
///
/// The advanced search returns item identifiers, and a second metadata request
/// resolves the playable audio files inside each item. An item is often more
/// than one track — a 78 rpm disc holds two sides and a netlabel release holds
/// an album — so the files of an item are read as its track list instead of
/// keeping only the first one.
class InternetArchiveSourceAdapter extends MusicSourceAdapter {
  /// How many items a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(8, 20);

  /// The tongues the archive files its audio under, by the name the reader
  /// picks. Only the tongues that were found to hold audio are offered.
  static Map<String, String> get _languages {
    final strings = AppStrings.instance;
    return {
      'English': strings.languageNameEnglish,
      'German': strings.languageNameGerman,
      'French': strings.languageNameFrench,
      'Spanish': strings.languageNameSpanish,
      'Japanese': strings.languageNameJapanese,
      'Arabic': strings.languageNameArabic,
      'Korean': strings.languageNameKorean,
      'Russian': strings.languageNameRussian,
      'Portuguese': strings.languageNamePortuguese,
      'Chinese': strings.languageNameChinese,
      'Hindi': strings.languageNameHindi,
    };
  }

  /// The most tracks one item contributes, unless the reader asks for more.
  ///
  /// A few items carry a whole archive of their own (a radio series of a
  /// hundred files, an audiobook of several hundred chapters); the cap keeps
  /// one such item from filling the library, and the reader who wants the
  /// whole of a long book raises it.
  static const _tracksPerItem = MusicSourceLimit(30, 200);

  static const _audioExtensions = ['.mp3', '.ogg', '.m4a', '.flac'];

  /// The suffixes the archive adds to name the quality of a copy.
  static const _qualitySuffixes = ['_64kb', '_128kb', '_192kb', '_vbr'];

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

  /// The source asks nothing of the reader, so it belongs to the top
  /// of the list.
  @override
  bool get featured => true;

  /// The archive serves the audio everybody downloaded most, or the audio
  /// that was uploaded last, so the source is ready as it is: a keyword is a
  /// choice, not a requirement.
  @override
  List<String> get browseModes => const [BrowseMode.charts, BrowseMode.latest];

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
      'language',
      AppStrings.instance.internetArchiveFieldLanguage,
      AppStrings.instance.internetArchiveFieldLanguageHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.languageNameAll),
        for (final entry in _languages.entries)
          MusicSourceChoice(entry.key, entry.value),
      ],
    ),
    MusicSourceField(
      'sort',
      AppStrings.instance.internetArchiveFieldSort,
      AppStrings.instance.internetArchiveFieldSortHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.internetArchiveSortBrowse),
        for (final entry in _sorts.entries)
          MusicSourceChoice(entry.key, _sortLabel(entry.key)),
      ],
    ),
    MusicSourceField(
      'decade',
      AppStrings.instance.internetArchiveFieldDecade,
      AppStrings.instance.internetArchiveFieldDecadeHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.internetArchiveDecadeAll),
        for (final decade in _decades)
          MusicSourceChoice('$decade', _decadeLabel(decade)),
      ],
    ),
    MusicSourceField(
      'perItem',
      AppStrings.instance.internetArchiveFieldPerItem,
      AppStrings.instance.internetArchiveFieldPerItemHint(
        _tracksPerItem.count,
        _tracksPerItem.max,
      ),
      numeric: true,
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.fieldLimit,
      AppStrings.instance.fieldLimitHint(scanLimit.count, scanLimit.max),
      numeric: true,
    ),
    MusicSourceField(
      'since',
      AppStrings.instance.recentWindowField,
      AppStrings.instance.recentWindowFieldHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.recentWindowAll),
        for (final days in RecentWindow.days)
          MusicSourceChoice(
            '$days',
            AppStrings.instance.recentWindowDays('$days'),
          ),
      ],
    ),
  ];

  @override
  bool get supportsPaging => true;

  @override
  Duration get autoScanInterval => const Duration(hours: 12);

  @override
  Duration get scanTimeout => const Duration(minutes: 2);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final query = request.config.setting('query');

    try {
      final limit = scanLimit.read(request.config.setting('limit'));
      final perItem = _tracksPerItem.read(request.config.setting('perItem'));
      final language = request.config.setting('language')?.trim() ?? '';
      final decade = _decadeOf(request.config.setting('decade'));
      final sort = _sortOf(request.config.setting('sort'));
      final base = query ?? 'mediatype:audio';
      // The archive stamps every item with the moment it took it in; a window
      // is a clause of the query, so the archive does the leaving out.
      final since = RecentWindow.cutoff(request.config.setting('since'));
      final now = DateTime.now().toUtc();
      final docs = await _search({
        // Without a keyword the archive serves the stream the instance
        // named: what everybody downloaded most, or what was uploaded last.
        // A tongue narrows the stream, and the archive files it as a clause
        // of the query.
        'q': [
          base,
          if (language.isNotEmpty) 'language:($language)',
          if (decade != null) 'year:[$decade TO ${decade + 9}]',
          if (since != null) 'addeddate:[${_day(since)} TO ${_day(now)}]',
        ].join(' AND '),
        'fl[]': ['identifier', 'title', 'creator', 'date'],
        'rows': limit,
        'page': request.offset ~/ limit + 1,
        'output': 'json',
        // A sort the reader picked takes precedence over the one a browsing
        // mode would ask for.
        'sort[]':
            sort ??
            (browseModeOf(request.config) == BrowseMode.latest
                ? 'publicdate desc'
                : 'downloads desc'),
      });

      if (docs.docs == null) {
        return failedResult(
          request.config.id,
          docs.busy
              ? AppStrings.instance.internetArchiveBackendBusy
              : AppStrings.instance.internetArchiveInvalidResponse,
        );
      }
      final documents = docs.docs!;

      final songs = <Song>[];
      const batchSize = 4;
      for (var start = 0; start < documents.length; start += batchSize) {
        final batch = documents
            .skip(start)
            .take(batchSize)
            .toList(growable: false);
        final items = await Future.wait(
          batch.map((doc) => _fetchTracks(doc, request.config, perItem)),
        );
        for (final tracks in items) {
          songs.addAll(tracks);
        }
        request.onProgress?.call(
          documents.isEmpty
              ? 1
              : ((start + batch.length) / documents.length).clamp(0, 1),
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

  /// The items the search answered with, tried three times.
  ///
  /// The archive answers a scan with an HTML page instead of JSON, or with a
  /// JSON body that carries no items, when it is busy — which a scan of many
  /// instances of the archive runs into. A moment later it answers properly,
  /// so the tries keep a scan from failing on a busy moment.
  Future<({List<dynamic>? docs, bool busy})> _search(
    Map<String, Object> query,
  ) {
    return retrySourceRead(
      () async {
        final response = await _dio.get<Map<String, dynamic>>(
          'https://archive.org/advancedsearch.php',
          queryParameters: query,
        );
        final data = response.data;
        final answer = data?['response'];
        final docs = answer is Map ? answer['docs'] : null;
        // The archive answers with an error of its own when its search
        // backend is down, which is a busy moment rather than a wrong query.
        final busy = data?['error'] != null;
        return (docs: docs is List ? docs : null, busy: busy);
      },
      answered: (answer) => answer.docs != null,
      delays: const [Duration(milliseconds: 600), Duration(milliseconds: 1500)],
    );
  }



  /// The day of an instant, written the way the archive writes a date.
  static String _day(DateTime at) =>
      '${at.year.toString().padLeft(4, '0')}-'
      '${at.month.toString().padLeft(2, '0')}-'
      '${at.day.toString().padLeft(2, '0')}';

  /// The description of an item, as plain text.
  ///
  /// The archive writes the description as HTML of whatever length the
  /// uploader left; a track keeps the readable beginning of it.
  static String? _descriptionOf(Object? raw) =>
      shortDescription(SourceSongFactory.readString(raw));

  /// The licence of an item, written the way the reader knows it.
  ///
  /// The archive files a licence as the address of its deed, so the address is
  /// read back into a name: a creative commons deed becomes "CC BY-SA 3.0",
  /// and anything else is left out rather than shown as a raw link.
  static String? _licenceOf(Object? raw) {
    final value = SourceSongFactory.readString(raw).trim().toLowerCase();
    if (value.isEmpty || !value.contains('creativecommons.org')) return null;

    final segments = Uri.tryParse(value)?.pathSegments ?? const <String>[];
    if (segments.contains('zero')) return 'CC0';
    if (segments.contains('mark')) return 'Public domain';

    final index = segments.indexOf('licenses');
    if (index < 0 || index + 1 >= segments.length) return null;
    final code = segments[index + 1].toUpperCase();
    final version = index + 2 < segments.length ? segments[index + 2] : '';
    return version.isEmpty ? 'CC $code' : 'CC $code $version';
  }



  /// The sorts the archive reads, by the name the reader picks.
  ///
  /// The archive answers an unknown sort with an error rather than with an
  /// order of its own, so only the sorts that were read from it are offered.
  static const _sorts = <String, String>{
    'title': 'titleSorter asc',
    'added': 'addeddate desc',
  };

  /// The order the archive sorts by, or null when the browsing mode decides.
  static String? _sortOf(String? raw) {
    final value = raw?.trim() ?? '';
    return value.isEmpty ? null : _sorts[value];
  }

  /// The name of a sort in the language of the reader.
  static String _sortLabel(String sort) {
    final strings = AppStrings.instance;
    return switch (sort) {
      'title' => strings.internetArchiveSortTitle,
      _ => strings.internetArchiveSortAdded,
    };
  }

  /// The decades the archive holds audio of, by the year they start.
  static const _decades = <int>[
    1930, 1940, 1950, 1960, 1970, 1980, 1990, 2000, 2010, 2020,
  ];

  /// The year a chosen decade starts, or null when every year is wanted.
  ///
  /// The archive files a year as a number rather than a range, so a decade is
  /// asked for as a range of its own; anything that is not one of the decades
  /// offered is read as no decade at all.
  static int? _decadeOf(String? raw) {
    final value = int.tryParse(raw?.trim() ?? '');
    if (value == null || !_decades.contains(value)) return null;
    return value;
  }

  /// The name of a decade in the language of the reader.
  static String _decadeLabel(int decade) =>
      AppStrings.instance.internetArchiveDecade('$decade');

  /// The tracks of one archive item.
  Future<List<Song>> _fetchTracks(
    Object? rawDoc,
    MusicSourceConfig config,
    int perItem,
  ) async {
    if (rawDoc is! Map) return const [];

    final identifier = rawDoc['identifier']?.toString() ?? '';
    if (identifier.isEmpty) return const [];

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://archive.org/metadata/${Uri.encodeComponent(identifier)}',
        options: Options(receiveTimeout: const Duration(seconds: 15)),
      );
      final data = response.data;
      if (data == null) return const [];

      final files = _audioFiles(data['files']);
      if (files.isEmpty) return const [];

      final metadata = data['metadata'] is Map
          ? data['metadata'] as Map
          : const <dynamic, dynamic>{};
      final itemTitle = _firstText([metadata['title'], rawDoc['title']]);
      final creator = _firstText([metadata['creator'], rawDoc['creator']]);
      final itemAlbum = SourceSongFactory.readString(metadata['album']).trim();
      // The item tells the reader what it is about and under which licence it
      // travels; both belong to every track of it.
      final itemDescription = _descriptionOf(metadata['description']);
      final itemLicense = _licenceOf(metadata['licenseurl']);
      final itemGenre = SourceSongFactory.readString(metadata['genre']).trim();
      final year = _parseYear(
        SourceSongFactory.readString(metadata['date'] ?? metadata['publicdate']),
      );
      final artworkUrl =
          'https://archive.org/services/img/${Uri.encodeComponent(identifier)}';
      final trackField = _trackField(files);
      final multiTrack = files.length > 1;

      final songs = <Song>[];
      for (
        var index = 0;
        index < files.length && index < perItem;
        index++
      ) {
        final file = files[index];
        final fileName = file['name']?.toString() ?? '';
        if (fileName.isEmpty) continue;

        final fileTitle = SourceSongFactory.readString(file['title']).trim();
        // A one-track item is named after the item: its title is written for
        // the reader, while the name of the file is written for the machine.
        final title = multiTrack
            ? (fileTitle.isEmpty ? _titleFromFileName(fileName) : fileTitle)
            : (itemTitle.isNotEmpty
                  ? itemTitle
                  : fileTitle.isEmpty
                  ? _titleFromFileName(fileName)
                  : fileTitle);
        if (title.isEmpty) continue;

        var artist = _firstText([file['artist'], creator]);
        var cleanTitle = title;
        // Some discs write the performer into the title and leave the artist
        // empty: "My Boy Lollypop - Barbie Gaye". The item names the artist,
        // so the suffix is the same fact written twice.
        if (SourceSongFactory.readString(file['artist']).trim().isEmpty &&
            creator.isNotEmpty &&
            title.toLowerCase().endsWith(' - ${creator.toLowerCase()}')) {
          cleanTitle = title
              .substring(0, title.length - creator.length - 3)
              .trim();
          artist = creator;
        }

        final track = trackField?[index];
        final encodedPath = fileName
            .split('/')
            .map(Uri.encodeComponent)
            .join('/');

        songs.add(
          SourceSongFactory.create(
            sourceId: config.id,
            externalId: '$identifier/$fileName',
            title: cleanTitle,
            artist: artist,
            // An item is a record of its own: when neither the file nor the
            // item names an album, the name of the item is the name of the
            // record its tracks belong to, so nothing lands under no record.
            album: _firstText([file['album'], itemAlbum, itemTitle]),
            duration: _parseDuration(file['length']),
            streamUrl:
                'https://archive.org/download/${Uri.encodeComponent(identifier)}/$encodedPath',
            artworkUrl: artworkUrl,
            genre: _firstText([file['genre'], itemGenre]),
            year: year,
            // An item that states no usable order keeps the order the
            // archive lists its files in.
            trackNumber: track?.number ?? index + 1,
            trackTotal: track?.total ?? files.length,
            description: itemDescription,
            license: itemLicense,
          ),
        );
      }

      return songs;
    } catch (_) {
      // One broken archive item should not fail the whole source.
      return const [];
    }
  }

  /// The audio files of an item, one per track.
  ///
  /// The archive stores one track in several formats and qualities. The files
  /// are grouped by their name without the extension and the quality suffix,
  /// and the most playable copy of each group is kept in the order the item
  /// lists them.
  List<Map> _audioFiles(Object? rawFiles) {
    if (rawFiles is! List) return const [];

    final chosen = <String, Map>{};
    final scores = <String, int>{};

    for (final raw in rawFiles) {
      if (raw is! Map) continue;

      final name = raw['name']?.toString() ?? '';
      final lowerName = name.toLowerCase();
      if (lowerName.isEmpty) continue;
      if (!_audioExtensions.any(lowerName.endsWith)) continue;

      final format = raw['format']?.toString().toLowerCase() ?? '';
      if (format.contains('torrent') ||
          format.contains('metadata') ||
          format.contains('item tile')) {
        continue;
      }

      final stem = _stemOf(lowerName);
      final score = _formatScore(format);
      final current = scores[stem];
      if (current != null && current <= score) continue;
      chosen[stem] = raw;
      scores[stem] = score;
    }

    return chosen.values.toList(growable: false);
  }

  /// The name of a file without its folder, its extension and its quality.
  static String _stemOf(String name) {
    final base = name.split('/').last;
    final dot = base.lastIndexOf('.');
    var stem = dot > 0 ? base.substring(0, dot) : base;
    for (final suffix in _qualitySuffixes) {
      if (stem.endsWith(suffix)) {
        stem = stem.substring(0, stem.length - suffix.length);
        break;
      }
    }
    return stem;
  }

  /// Which copy of a track to stream, the smaller number the better.
  static int _formatScore(String format) {
    if (format.contains('vbr mp3')) return 0;
    if (format.contains('mp3')) return 1;
    if (format.contains('ogg')) return 2;
    if (format.contains('m4a')) return 3;
    if (format.contains('flac')) return 4;
    return 5;
  }

  /// The track numbers the item states, when they can be trusted.
  ///
  /// The field is written as "3" or "3/12". Some items put the number of the
  /// disc there instead, so the same number repeats across the file list; such
  /// a field orders nothing, and the position in the item takes its place.
  List<({int? number, int? total})>? _trackField(List<Map> files) {
    final numbers = <int?>[];
    final statedTotals = <int?>[];
    var statedTotal = 0;

    for (final file in files) {
      final raw = SourceSongFactory.readString(file['track']).trim();
      final parts = raw.split('/');
      final number = int.tryParse(parts.first.trim());
      final total = parts.length > 1 ? int.tryParse(parts[1].trim()) : null;
      numbers.add(number);
      statedTotals.add(total);
      if (total != null) statedTotal = total;
    }

    final seen = <int>{};
    for (final number in numbers) {
      if (number == null) continue;
      if (!seen.add(number)) return null;
    }

    return [
      for (var index = 0; index < files.length; index++)
        (
          number: numbers[index] ?? index + 1,
          total: statedTotals[index] ??
              (statedTotal > 0 ? statedTotal : files.length),
        ),
    ];
  }

  /// The name of the file, without its folder and its extension.
  static String _titleFromFileName(String name) {
    final base = name.split('/').last;
    final dot = base.lastIndexOf('.');
    final stem = dot > 0 ? base.substring(0, dot) : base;
    return stem.replaceAll('_', ' ').trim();
  }

  /// The year of an archive date, when the archive states a real one.
  ///
  /// A date the archive never filled in is written as 0000, which is not a
  /// year a track was made.
  static int? _parseYear(String date) {
    final text = date.trim();
    if (text.length < 4) return null;
    final year = int.tryParse(text.substring(0, 4));
    return year == null || year <= 0 ? null : year;
  }

  static String _firstText(List<Object?> values) {
    for (final value in values) {
      final text = SourceSongFactory.readString(value).trim();
      if (text.isNotEmpty) return text;
    }
    return '';
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
