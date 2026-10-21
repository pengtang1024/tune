import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/json_values.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';

/// The mapping of a decoded answer onto tracks.
///
/// The JSON interface and the GraphQL interface share it: they differ in how
/// they ask the question, not in how they read the answer.
class JsonSourceMapping {
  /// Where the list of the tracks is; an empty path means the answer itself
  /// is the list.
  final String listPath;

  /// Where the id of a track is; an empty path means its place in the list.
  final String idPath;

  final String titlePath;
  final String artistPath;
  final String albumPath;
  final String coverPath;
  final String urlPath;
  final String durationPath;
  final String genrePath;

  /// The template of the playable address, such as `https://host/track/${id}`.
  final String urlTemplate;

  const JsonSourceMapping({
    this.listPath = '',
    this.idPath = '',
    this.titlePath = '',
    this.artistPath = '',
    this.albumPath = '',
    this.coverPath = '',
    this.urlPath = '',
    this.durationPath = '',
    this.genrePath = '',
    this.urlTemplate = '',
  });

  /// The mapping an instance declares.
  factory JsonSourceMapping.of(MusicSourceConfig config) {
    return JsonSourceMapping.fromSettings(config.settings);
  }

  /// The mapping written as the settings of an instance.
  ///
  /// The settings and the mapping say the same thing, so one is written from
  /// the other instead of both naming the fields on their own.
  factory JsonSourceMapping.fromSettings(Map<String, String> settings) {
    String read(String key) => settings[key]?.trim() ?? '';
    return JsonSourceMapping(
      listPath: read('listPath'),
      idPath: read('idPath'),
      titlePath: read('titlePath'),
      artistPath: read('artistPath'),
      albumPath: read('albumPath'),
      coverPath: read('coverPath'),
      urlPath: read('urlPath'),
      durationPath: read('durationPath'),
      genrePath: read('genrePath'),
      urlTemplate: read('urlTemplate'),
    );
  }

  /// The mapping as the settings of an instance.
  Map<String, String> toSettings() => {
    'listPath': listPath,
    'idPath': idPath,
    'titlePath': titlePath,
    'artistPath': artistPath,
    'albumPath': albumPath,
    'coverPath': coverPath,
    'urlPath': urlPath,
    'durationPath': durationPath,
    'genrePath': genrePath,
    'urlTemplate': urlTemplate,
  };

  /// The tracks of a decoded answer.
  ///
  /// A track without a playable address is not a track: the app has nothing
  /// to play, so it is left out.
  List<Song> songs(
    Object? root, {
    required String sourceId,
    int limit = 200,
  }) {
    final list = _list(root);
    if (list == null) return const [];

    final songs = <Song>[];
    for (var index = 0; index < list.length; index++) {
      if (songs.length >= limit) break;

      final item = list[index];
      final id = _idOf(item, index);
      final address = _addressOf(item, id);
      if (address == null) continue;

      final genre = jsonText(readJsonPath(item, genrePath));
      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: id,
          title: _titleOf(item, id),
          artist: jsonText(readJsonPath(item, artistPath)),
          album: jsonText(readJsonPath(item, albumPath)),
          duration: jsonSeconds(readJsonPath(item, durationPath)),
          streamUrl: address,
          artworkUrl: SourceSongFactory.normalizeUrl(
            jsonText(readJsonPath(item, coverPath)),
          ),
          genre: genre.isEmpty ? null : genre,
        ),
      );
    }
    return songs;
  }

  /// Whether the mapping says where the playable address is.
  bool get hasAddress => urlPath.isNotEmpty || urlTemplate.isNotEmpty;

  /// The list of the tracks in an answer, when there is one.
  List? _list(Object? root) {
    final value = readJsonPath(root, listPath);
    return value is List ? value : null;
  }

  /// The id of a track: the one the answer gives, or its place in the list.
  String _idOf(Object? item, int index) {
    final text = jsonText(readJsonPath(item, idPath));
    return text.isEmpty ? '$index' : text;
  }

  /// The title of a track: the one the answer gives, or its id.
  String _titleOf(Object? item, String id) {
    final text = jsonText(readJsonPath(item, titlePath));
    return text.isEmpty ? id : text;
  }

  /// The address a track plays from.
  ///
  /// The answer may name the address itself, or the reader writes a template
  /// that puts the id in it. The template wins: it is written for the answer
  /// the reader knows.
  String? _addressOf(Object? item, String id) {
    if (urlTemplate.isNotEmpty) {
      final address = urlTemplate.replaceAll('\${id}', id);
      return SourceSongFactory.normalizeUrl(address);
    }
    final address = jsonText(readJsonPath(item, urlPath));
    return SourceSongFactory.normalizeUrl(address);
  }
}

/// The fields the mapping of an answer is written in.
///
/// Both the JSON interface and the GraphQL interface read the answer the
/// same way, so they share these fields.
List<MusicSourceField> jsonMappingFields() {
  final strings = AppStrings.instance;
  final pathHint = strings.jsonFieldPathHint;

  return [
    MusicSourceField(
      'listPath',
      strings.jsonFieldListPath,
      pathHint,
    ),
    MusicSourceField('idPath', strings.jsonFieldIdPath, pathHint),
    MusicSourceField('titlePath', strings.jsonFieldTitlePath, pathHint),
    MusicSourceField('artistPath', strings.jsonFieldArtistPath, pathHint),
    MusicSourceField('albumPath', strings.jsonFieldAlbumPath, pathHint),
    MusicSourceField('coverPath', strings.jsonFieldCoverPath, pathHint),
    MusicSourceField('urlPath', strings.jsonFieldUrlPath, pathHint),
    MusicSourceField('durationPath', strings.jsonFieldDurationPath, pathHint),
    MusicSourceField('genrePath', strings.jsonFieldGenrePath, pathHint),
    MusicSourceField(
      'urlTemplate',
      strings.jsonFieldUrlTemplate,
      strings.jsonFieldUrlTemplateHint,
    ),
  ];
}
