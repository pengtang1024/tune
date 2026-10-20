import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:tune/data/services/artwork/artwork_cache.dart';

/// The picture at [url], taken from the local store when it is there.
///
/// The bytes come from the artwork cache, so the same cover is fetched once
/// and then read from the disk after a restart. The key of the picture is the
/// address, so the picture the framework keeps in memory is reused when the
/// cover comes back on the screen.
class ArtworkImageProvider extends ImageProvider<ArtworkImageProvider> {
  const ArtworkImageProvider(this.url, {required this.cache, this.scale = 1.0});

  /// The address of the picture.
  final String url;

  /// Where the bytes of the picture come from.
  final ArtworkCache cache;

  /// The factor between the pixels of the picture and the points it is drawn
  /// in.
  final double scale;

  @override
  Future<ArtworkImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<ArtworkImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    ArtworkImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: key.url,
    );
  }

  Future<ui.Codec> _loadAsync(
    ArtworkImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await key.cache.bytesFor(key.url);
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is ArtworkImageProvider &&
        other.url == url &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);
}
