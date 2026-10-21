import 'dart:typed_data';

/// Keeps the covers of the tracks, so they do not have to be fetched again.
///
/// The cache owns the layout of its store. The interface only asks for the
/// cover and never learns where it is kept, so the place of the store can
/// change without touching the interface that shows the covers.
abstract class ArtworkCache {
  /// The cover at [url].
  ///
  /// The cover is taken from the local store when it was fetched before, so
  /// a restart does not fetch the same covers again. The call throws when
  /// the cover cannot be fetched.
  Future<CoverImage> imageFor(String url);

  /// The file the cover at [url] is kept in, when it was fetched before.
  ///
  /// The answer is the path of the file on this machine, or nothing when the
  /// cover was never fetched. The caller that shows the cover to somebody
  /// else needs a place it can point at, and a file is the one thing the
  /// desktop can open without asking the network.
  String? coverFileFor(String url);

  /// Releases the resources of the cache.
  void dispose();
}

/// The bytes of a cover and the name its file gets.
class CoverImage {
  const CoverImage(this.bytes, this.extension);

  /// The bytes of the picture.
  final Uint8List bytes;

  /// The extension of the file the bytes are written to, without the dot.
  ///
  /// It follows the kind of picture the server answered with, so a player
  /// that opens the file knows what it holds.
  final String extension;
}

/// The kind of the picture in [bytes], as the extension of its file.
///
/// The bytes tell what the picture is, even when the server says nothing
/// about it, so a file that is written next to a track is named after the
/// picture it holds.
String imageExtension(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'jpg';
  }
  if (bytes.length >= 4 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'png';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'webp';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46) {
    return 'gif';
  }
  return 'img';
}
