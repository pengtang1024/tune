import 'dart:typed_data';

import 'package:tune/data/services/artwork/artwork_cache.dart';

/// An artwork cache that answers with the same bytes, for the tests.
class FakeArtworkCache implements ArtworkCache {
  FakeArtworkCache({List<int>? bytes, this.cachedFiles = const {}})
      : bytes = Uint8List.fromList(bytes ?? defaultImageBytes);

  /// The bytes every cover is answered with.
  final Uint8List bytes;

  /// The files the covers are kept in, by address.
  final Map<String, String> cachedFiles;

  /// The addresses that were asked for, in order.
  final List<String> asked = [];

  /// The addresses whose cover file was asked of the disk, in order.
  final List<String> askedForFiles = [];

  @override
  Future<CoverImage> imageFor(String url) async {
    asked.add(url);
    return CoverImage(bytes, 'png');
  }

  @override
  String? coverFileFor(String url) {
    askedForFiles.add(url);
    return cachedFiles[url];
  }

  @override
  void dispose() {}

  /// A transparent picture of one pixel, small enough to keep in a test.
  static const List<int> defaultImageBytes = [
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    0,
    0,
    0,
    13,
    73,
    72,
    68,
    82,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    1,
    8,
    6,
    0,
    0,
    0,
    31,
    15,
    99,
    136,
    0,
    0,
    0,
    13,
    73,
    68,
    65,
    84,
    120,
    156,
    99,
    96,
    0,
    0,
    0,
    2,
    0,
    1,
    229,
    21,
    39,
    0,
    0,
    0,
    0,
    73,
    69,
    78,
    68,
    174,
    66,
    96,
    130,
  ];
}
