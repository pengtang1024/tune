import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// The pixels of the tray icon.
///
/// The desktop wants the picture as raw pixels, not as a file, so the icon
/// travels with the player and does not have to be installed in the system.
class TrayIconImage {
  const TrayIconImage({
    required this.width,
    required this.height,
    required this.argb,
  });

  /// Width of the picture in pixels.
  final int width;

  /// Height of the picture in pixels.
  final int height;

  /// The pixels, four bytes each: alpha, red, green, blue.
  final Uint8List argb;

  /// The sizes the panel of the desktop draws the icon at.
  ///
  /// The desktop asks for the size it needs and takes the picture that fits
  /// best, so the icon is handed over in more than one size.
  static const panelSizes = <int>[22, 24, 32, 48];

  /// Reads the icon out of the assets of the app and scales it.
  ///
  /// Returns an empty list when the asset is missing or cannot be read; the
  /// tray then shows the icon of the desktop instead of a picture of its own.
  static Future<List<TrayIconImage>> loadAll(String assetKey) async {
    try {
      final data = await rootBundle.load(assetKey);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final images = <TrayIconImage>[];
      for (final size in panelSizes) {
        final image = await _scaled(frame.image, size);
        if (image != null) images.add(image);
      }
      return images;
    } catch (_) {
      return const [];
    }
  }

  /// Draws the picture at the wanted size.
  ///
  /// Returns null when the engine cannot draw the picture.
  static Future<TrayIconImage?> _scaled(ui.Image source, int size) async {
    if (source.width == size && source.height == size) {
      return _ofImage(source);
    }

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      source,
      ui.Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(size, size);
      return await _ofImage(image);
    } finally {
      picture.dispose();
    }
  }

  /// Turns a picture of the framework into pixels the desktop understands.
  ///
  /// The framework hands out red, green, blue, alpha; the desktop of the
  /// status notifier wants alpha first.
  static Future<TrayIconImage?> _ofImage(ui.Image image) async {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytes == null) return null;

    return TrayIconImage(
      width: image.width,
      height: image.height,
      argb: _toArgb(bytes.buffer.asUint8List()),
    );
  }

  /// Turns the pixels of the framework into the order the desktop wants.
  static Uint8List _toArgb(Uint8List rgba) {
    final argb = Uint8List(rgba.length);
    for (var i = 0; i + 3 < rgba.length; i += 4) {
      argb[i] = rgba[i + 3];
      argb[i + 1] = rgba[i];
      argb[i + 2] = rgba[i + 1];
      argb[i + 3] = rgba[i + 2];
    }
    return argb;
  }
}
