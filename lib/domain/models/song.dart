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

  /// The original payload the source answered with.
  ///
  /// A source that has to hand its own data back to resolve a playback URL
  /// or a lyric keeps it here. Built-in adapters leave it null.
  final Map<String, dynamic>? sourceData;

  /// Extra HTTP headers required by some remote stream URLs.
  final Map<String, String>? httpHeaders;

  /// Whether the track is a live stream instead of a fixed recording.
  ///
  /// A live stream never ends, so it is played straight from the network
  /// instead of being fetched to disk first, and the player does not offer a
  /// position inside it.
  final bool isLiveStream;

  /// The licence the track is published under, when the source states one.
  final String? license;

  /// A short description of the track, when the source provides one.
  final String? description;

  /// The file that holds the audio of this track, when the track has one.
  ///
  /// A local track is its own file and keeps that in [uri]. A remote track
  /// owns a file once it was fetched to the disk, and the file is remembered
  /// here: the track keeps the identity of its source and the path of its
  /// copy at the same time.
  final String? localPath;

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
    this.albumArtPath,
    this.sourceId,
    this.externalId,
    this.streamUrl,
    this.artworkUrl,
    this.sourceData,
    this.httpHeaders,
    this.isLiveStream = false,
    this.license,
    this.description,
    this.localPath,
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
      isLiveStream: data['isLiveStream'] == true,
      license: data['license'],
      description: data['description'],
      localPath: data['localPath'],
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
    String? albumArtPath,
    String? sourceId,
    String? externalId,
    String? streamUrl,
    String? artworkUrl,
    Map<String, dynamic>? sourceData,
    Map<String, String>? httpHeaders,
    bool? isLiveStream,
    String? license,
    String? description,
    String? localPath,
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
      albumArtPath: albumArtPath ?? this.albumArtPath,
      sourceId: sourceId ?? this.sourceId,
      externalId: externalId ?? this.externalId,
      streamUrl: streamUrl ?? this.streamUrl,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      sourceData: sourceData ?? this.sourceData,
      httpHeaders: httpHeaders ?? this.httpHeaders,
      isLiveStream: isLiveStream ?? this.isLiveStream,
      license: license ?? this.license,
      description: description ?? this.description,
      localPath: localPath ?? this.localPath,
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

  /// Whether the track has a file of its own on this machine.
  ///
  /// A remote source keeps a canonical `tune://` URI for the identity of the
  /// track. That URI names the track, it is not a path: the track owns a file
  /// only when it was fetched to the disk or when it always lived here.
  bool get isLocalFile {
    final target = uri;
    if (target.isEmpty) return false;
    final parsed = Uri.tryParse(target);
    // A path that cannot be read as an URI is a path all the same.
    if (parsed == null) return true;
    final scheme = parsed.scheme;
    // A single letter is the drive letter of a Windows path, not a scheme.
    if (scheme.isEmpty || scheme.length == 1) return true;
    return scheme == 'file';
  }

  /// The file that holds the audio of this track, when there is one.
  ///
  /// A local track is its own file. A remote track owns a file once it was
  /// fetched to the disk, and that file is remembered in [localPath].
  String? get localFile {
    final file = localPath;
    if (file != null && file.isNotEmpty) return file;
    return isLocalFile ? uri : null;
  }

  /// Whether the audio of this track is on this machine.
  bool get hasLocalFile => localFile != null;

  /// Whether the track comes from a remote source.
  ///
  /// A track that was fetched keeps the identity of its source, so it stays a
  /// remote track even when a copy of it is on this machine.
  bool get hasRemoteSource => uri.isNotEmpty && !isLocalFile;

  /// The address the track is played from over the network.
  ///
  /// A track that lives on this machine as its own file has no address: it is
  /// played from the file. A track from a source is played from the address
  /// that source gives it.
  String? get onlineAddress {
    if (isLocalFile) return null;
    final url = streamUrl;
    if (url != null && url.isNotEmpty) return url;
    return uri.isEmpty ? null : uri;
  }

  /// The address that names this track inside the app.
  ///
  /// A track of a source is named by its canonical URI; a local file is named
  /// by its path, and that path is the file path already.
  String? get identity => hasRemoteSource ? uri : null;

  /// The address of the cover of the track.
  ///
  /// A track of a source has the address of the cover; a local track has the
  /// file the cover was written to.
  String? get coverAddress {
    final url = artworkUrl;
    if (url != null && url.isNotEmpty) return url;
    final path = albumArtPath;
    if (path != null && path.isNotEmpty) return path;
    return null;
  }

  /// Combines two entries of the same track.
  ///
  /// The entry that owns a file knows the file: where it is, how big it is.
  /// The other entry knows the track: its name, its cover, its address. The
  /// result keeps both, so one row in the library says everything that is
  /// known about the track.
  Song mergeWith(Song other) {
    final file = hasLocalFile ? this : other;
    final track = identical(file, this) ? other : this;

    return track.copyWith(
      title: track.title.isEmpty ? file.title : track.title,
      artist: track.artist.isEmpty ? file.artist : track.artist,
      album: track.album.isEmpty ? file.album : track.album,
      duration: track.duration > 0 ? track.duration : file.duration,
      genre: track.genre ?? file.genre,
      year: track.year ?? file.year,
      bitrate: file.bitrate ?? track.bitrate,
      sampleRate: file.sampleRate ?? track.sampleRate,
      trackNumber: track.trackNumber ?? file.trackNumber,
      trackTotal: track.trackTotal ?? file.trackTotal,
      discNumber: track.discNumber ?? file.discNumber,
      totalDisc: track.totalDisc ?? file.totalDisc,
      lyrics: track.lyrics ?? file.lyrics,
      genres: track.genres ?? file.genres,
      performers: track.performers ?? file.performers,
      language: track.language ?? file.language,
      size: file.size ?? track.size,
      albumArtPath: track.albumArtPath ?? file.albumArtPath,
      localPath: file.localPath ?? (file.isLocalFile ? file.uri : null),
    );
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
    'albumArtPath': albumArtPath,
    'sourceId': sourceId,
    'externalId': externalId,
    'streamUrl': streamUrl,
    'artworkUrl': artworkUrl,
    'sourceData': sourceData,
    'httpHeaders': httpHeaders,
    'isLiveStream': isLiveStream,
    'license': license,
    'description': description,
    'localPath': localPath,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Song && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
