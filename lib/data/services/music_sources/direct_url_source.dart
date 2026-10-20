import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// A source of tracks the reader brings along by their address.
///
/// The reader writes one address per line; every line becomes a track, and
/// the title is the name of the file. There is no service behind it: the app
/// only plays what the address points at.
class DirectUrlSourceAdapter extends MusicSourceAdapter {
  @override
  String get sourceType => 'direct_url';

  @override
  bool isConfigured(MusicSourceConfig config) {
    return parseAddresses(config.setting('urls')).isNotEmpty;
  }

  @override
  String get configurationHint => AppStrings.instance.directUrlHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'urls',
      AppStrings.instance.directUrlFieldUrls,
      AppStrings.instance.directUrlFieldUrlsHint,
      required: true,
      multiline: true,
    ),
  ];

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final addresses = parseAddresses(request.config.setting('urls'));
    if (addresses.isEmpty) {
      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    return SourceScanResult(
      sourceId: request.config.id,
      status: SourceScanStatus.success,
      songs: parseTracks(addresses, sourceId: request.config.id),
    );
  }

  /// The addresses the reader wrote, one per line.
  ///
  /// Only http(s) addresses are kept: the app plays what it can reach, and a
  /// line that is not an address is a typo, not a track.
  static List<String> parseAddresses(String? raw) {
    if (raw == null) return const [];

    final addresses = <String>[];
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (SourceSongFactory.normalizeUrl(trimmed) == null) continue;
      addresses.add(trimmed);
    }
    return addresses;
  }

  /// The tracks of the addresses.
  static List<Song> parseTracks(
    List<String> addresses, {
    required String sourceId,
  }) {
    return [
      for (final address in addresses)
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: address,
          title: titleOf(address),
          streamUrl: address,
        ),
    ];
  }

  /// The name of the track an address points at.
  ///
  /// The name of the file without its extension: a track list reads better
  /// with "Song" than with "Song.mp3".
  static String titleOf(String address) {
    final parsed = Uri.tryParse(address);
    if (parsed == null) return address;

    final segments = parsed.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (segments.isEmpty) {
      return parsed.host.isEmpty ? address : parsed.host;
    }

    final name = segments.last;
    final dot = name.lastIndexOf('.');
    if (dot <= 0) return name;
    return name.substring(0, dot);
  }
}
