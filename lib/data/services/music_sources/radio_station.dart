/// One station of the radio source.
///
/// A station is not a recording: it plays whatever the broadcaster sends at
/// that moment. The station therefore carries the broadcaster, the stream
/// address and the information a listener needs to recognise it.
class RadioStation {
  /// The directory the station was found in.
  final String provider;

  /// The identifier of the station inside its directory.
  final String id;

  /// The name the broadcaster uses.
  final String name;

  /// The address of the audio stream.
  final String streamUrl;

  /// The logo or the favicon of the station.
  final String? artworkUrl;

  /// The musical style of the station.
  final String? genre;

  /// The language the station broadcasts in.
  final String? language;

  /// The country the station comes from.
  final String? country;

  /// A sentence about the station.
  final String? description;

  /// The artist of the track that is playing right now.
  final String? nowPlayingArtist;

  /// The title of the track that is playing right now.
  final String? nowPlayingTitle;

  /// The year of the track that is playing right now.
  final int? nowPlayingYear;

  /// The bitrate of the stream in kbit/s.
  final int? bitrate;

  /// The codec of the stream, for example `MP3` or `AAC`.
  final String? codec;

  /// How many listeners the directory counted.
  final int? listeners;

  /// The address of the station page.
  final String? homepage;

  const RadioStation({
    required this.provider,
    required this.id,
    required this.name,
    required this.streamUrl,
    this.artworkUrl,
    this.genre,
    this.language,
    this.country,
    this.description,
    this.nowPlayingArtist,
    this.nowPlayingTitle,
    this.nowPlayingYear,
    this.bitrate,
    this.codec,
    this.listeners,
    this.homepage,
  });
}

/// A directory of stations the radio source can read.
///
/// Every provider answers with the same [RadioStation] shape, so the adapter
/// does not have to know where a station came from.
abstract class RadioStationProvider {
  /// The identifier stored in the configuration of the source.
  String get id;

  /// The name of the directory, shown in the interface.
  String get displayName;

  /// Reads the stations that match [query].
  ///
  /// An empty [query] returns the stations the directory considers its
  /// highlights. [limit] caps the number of stations.
  Future<List<RadioStation>> fetch({required String query, required int limit});
}
