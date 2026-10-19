class Song {
  final int id;
  final String title;
  final String artist;
  final String album;
  final int duration;
  final String uri;
  final int dateAdded;
  final String? genre;
  final int? year;
  final int? bitrate;
  final int? sampleRate;
  final int? trackNumber;
  final int? trackTotal;
  final int? discNumber;
  final int? totalDisc;
  final String? lyrics;
  final List<String>? genres;
  final List<String>? performers;
  final String? language;
  final int? size;
  final String? type;
  final bool isFavorite;
  final String? albumArtPath;

  /// Identifies the music source that produced this song.
  ///
  /// Local files keep this null for backward compatibility with libraries
  /// persisted before sources were introduced.
  final String? sourceId;

  /// Provider-specific identifier used to rebuild the canonical [uri].
  final String? externalId;

  /// Direct playable URL for remote sources. [uri] stays canonical and stable.
  final String? streamUrl;

  /// Cover image URL for remote sources. Local files use [albumArtPath].
  final String? artworkUrl;

  /// Original provider payload for plugin-backed sources.
  ///
  /// It is passed back to the plugin when resolving playback URLs, lyrics or
  /// extra metadata. Built-in adapters leave it null.
  final Map<String, dynamic>? sourceData;

  /// Extra HTTP headers required by some plugin-provided stream URLs.
  final Map<String, String>? httpHeaders;

  const Song({
    required this.id,
    this.title = '',
    this.artist = '',
    this.album = '',
    this.duration = 0,
    this.uri = '',
    this.dateAdded = 0,
    this.genre,
    this.year,
    this.bitrate,
    this.sampleRate,
    this.trackNumber,
    this.trackTotal,
    this.discNumber,
    this.totalDisc,
    this.lyrics,
    this.genres,
    this.performers,
    this.language,
    this.size,
    this.type,
    this.isFavorite = false,
    this.albumArtPath,
    this.sourceId,
    this.externalId,
    this.streamUrl,
    this.artworkUrl,
    this.sourceData,
    this.httpHeaders,
  });

  factory Song.fromMap(Map<String, dynamic> data) {
    return Song(
      id: data['id'] ?? 0,
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      album: data['album'] ?? '',
      duration: data['duration'] ?? 0,
      uri: data['uri'] ?? '',
      dateAdded: data['dateAdded'] ?? 0,
      genre: data['genre'],
      year: data['year'],
      bitrate: data['bitrate'],
      sampleRate: data['sampleRate'],
      trackNumber: data['trackNumber'],
      trackTotal: data['trackTotal'],
      discNumber: data['discNumber'],
      totalDisc: data['totalDisc'],
      lyrics: data['lyrics'],
      genres: data['genres'] is List ? List<String>.from(data['genres']) : null,
      performers: data['performers'] is List
          ? List<String>.from(data['performers'])
          : null,
      language: data['language'],
      size: data['size'],
      type: data['type'],
      isFavorite: data['isFavorite'] ?? false,
      albumArtPath: data['albumArtPath'],
      sourceId: data['sourceId'],
      externalId: data['externalId'],
      streamUrl: data['streamUrl'],
      artworkUrl: data['artworkUrl'],
      sourceData: data['sourceData'] is Map
          ? Map<String, dynamic>.from(data['sourceData'] as Map)
          : null,
      httpHeaders: data['httpHeaders'] is Map
          ? (data['httpHeaders'] as Map).map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : null,
    );
  }

  Song copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    int? duration,
    String? uri,
    int? dateAdded,
    String? genre,
    int? year,
    int? bitrate,
    int? sampleRate,
    int? trackNumber,
    int? trackTotal,
    int? discNumber,
    int? totalDisc,
    String? lyrics,
    List<String>? genres,
    List<String>? performers,
    String? language,
    int? size,
    String? type,
    bool? isFavorite,
    String? albumArtPath,
    String? sourceId,
    String? externalId,
    String? streamUrl,
    String? artworkUrl,
    Map<String, dynamic>? sourceData,
    Map<String, String>? httpHeaders,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      uri: uri ?? this.uri,
      dateAdded: dateAdded ?? this.dateAdded,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      bitrate: bitrate ?? this.bitrate,
      sampleRate: sampleRate ?? this.sampleRate,
      trackNumber: trackNumber ?? this.trackNumber,
      trackTotal: trackTotal ?? this.trackTotal,
      discNumber: discNumber ?? this.discNumber,
      totalDisc: totalDisc ?? this.totalDisc,
      lyrics: lyrics ?? this.lyrics,
      genres: genres ?? this.genres,
      performers: performers ?? this.performers,
      language: language ?? this.language,
      size: size ?? this.size,
      type: type ?? this.type,
      isFavorite: isFavorite ?? this.isFavorite,
      albumArtPath: albumArtPath ?? this.albumArtPath,
      sourceId: sourceId ?? this.sourceId,
      externalId: externalId ?? this.externalId,
      streamUrl: streamUrl ?? this.streamUrl,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      sourceData: sourceData ?? this.sourceData,
      httpHeaders: httpHeaders ?? this.httpHeaders,
    );
  }

  String get displayName => title;
  int get durationInMillis => duration;
  String get data => uri;

  /// The URI the audio backend should load.
  ///
  /// Remote sources keep a canonical `tune://` URI for identity and store the
  /// playable URL separately because it can expire between scans.
  String get playbackUri =>
      streamUrl != null && streamUrl!.isNotEmpty ? streamUrl! : uri;

  /// Whether the audio has to be fetched from the network.
  ///
  /// Local tracks carry a file path, remote sources carry an HTTP URL.
  bool get isRemote {
    final target = playbackUri;
    return target.startsWith('http://') || target.startsWith('https://');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'duration': duration,
    'uri': uri,
    'dateAdded': dateAdded,
    'genre': genre,
    'year': year,
    'bitrate': bitrate,
    'sampleRate': sampleRate,
    'trackNumber': trackNumber,
    'trackTotal': trackTotal,
    'discNumber': discNumber,
    'totalDisc': totalDisc,
    'lyrics': lyrics,
    'genres': genres,
    'performers': performers,
    'language': language,
    'size': size,
    'type': type,
    'isFavorite': isFavorite,
    'albumArtPath': albumArtPath,
    'sourceId': sourceId,
    'externalId': externalId,
    'streamUrl': streamUrl,
    'artworkUrl': artworkUrl,
    'sourceData': sourceData,
    'httpHeaders': httpHeaders,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Song && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
