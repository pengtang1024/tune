import 'package:tune/domain/models/song.dart';

/// Builds [Song] values for remote sources.
///
/// Remote songs keep a stable `tune://` URI for identity, while the playable
/// URL lives in [Song.streamUrl] because signed URLs can expire.
class SourceSongFactory {
  const SourceSongFactory._();

  static Song create({
    required String sourceId,
    required String externalId,
    required String title,
    String artist = '',
    String album = '',
    int duration = 0,
    String? streamUrl,
    String? artworkUrl,
    String? genre,
    int? year,
  }) {
    final uri = 'tune://$sourceId/${Uri.encodeComponent(externalId)}';

    return Song(
      id: stableId(uri),
      title: title.trim(),
      artist: artist.trim(),
      album: album.trim(),
      duration: duration < 0 ? 0 : duration,
      uri: uri,
      dateAdded: DateTime.now().millisecondsSinceEpoch,
      genre: genre,
      year: year,
      type: 'remote',
      sourceId: sourceId,
      externalId: externalId,
      streamUrl: normalizeUrl(streamUrl),
      artworkUrl: normalizeUrl(artworkUrl),
    );
  }

  /// Deterministic 31-bit hash so persisted ids survive restarts.
  static int stableId(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  static String? normalizeUrl(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    return trimmed;
  }

  static int parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String readString(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List) {
      return value
          .map((item) => item?.toString() ?? '')
          .where((item) => item.isNotEmpty)
          .join(' / ');
    }
    return value.toString();
  }
}
