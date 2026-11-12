import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:tune/core/config/platform_constants.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/utils/logger.dart';

/// The shape the desktop window takes.
enum WindowForm {
  /// The window the reader moves and resizes.
  normal,

  /// The narrow bar that keeps the dock and nothing else.
  mini,

  /// The now playing view without the shell around it.
  immersive;

  static WindowForm fromName(String? name) {
    for (final form in values) {
      if (form.name == name) return form;
    }
    return WindowForm.normal;
  }
}

/// Where the window stood the last time it was in the normal form.
class WindowGeometry {
  const WindowGeometry({
    required this.width,
    required this.height,
    this.left,
    this.top,
    this.maximized = false,
  });

  final double width;
  final double height;

  /// The left edge of the window, when it is known.
  final double? left;

  /// The top edge of the window, when it is known.
  final double? top;

  /// Whether the window was maximized when it was last written.
  ///
  /// The size is the size of the normal form even while this is on: a start
  /// that reads it back restores the window maximized, and unmaximizing it
  /// returns to the size the reader left, not to the size of the screen.
  final bool maximized;

  Size get size => Size(width, height);

  Offset? get position {
    final left = this.left;
    final top = this.top;
    if (left == null || top == null) return null;
    return Offset(left, top);
  }

  WindowGeometry copyWith({bool? maximized}) {
    return WindowGeometry(
      width: width,
      height: height,
      left: left,
      top: top,
      maximized: maximized ?? this.maximized,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'width': width,
      'height': height,
      if (left != null) 'left': left,
      if (top != null) 'top': top,
      'maximized': maximized,
    };
  }

  /// Reads a geometry, or null when the document does not carry one.
  static WindowGeometry? fromJson(Map<String, Object?> json) {
    final width = json['width'];
    final height = json['height'];
    if (width is! num || height is! num) return null;
    if (!width.isFinite || !height.isFinite) return null;
    final left = json['left'];
    final top = json['top'];
    final maximized = json['maximized'];
    return WindowGeometry(
      width: width.toDouble(),
      height: height.toDouble(),
      left: left is num && left.isFinite ? left.toDouble() : null,
      top: top is num && top.isFinite ? top.toDouble() : null,
      maximized: maximized is bool ? maximized : false,
    );
  }
}

/// Keeps the size, the place and the form of the window between starts.
///
/// The geometry belongs to the window, not to the settings page: a resize
/// writes it several times a second while the reader drags the edge, and the
/// settings never show it. The store is the only writer of the two keys, so
/// the window service and the shell read the same document instead of keeping
/// a copy each.
class WindowLayoutStore {
  WindowLayoutStore(this._persistence);

  static const String geometryKey = 'window_geometry_v1';
  static const String formKey = 'window_form_v1';

  final PersistenceService _persistence;

  /// The geometry of the last normal form, or null when the app never saved
  /// one.
  WindowGeometry? readGeometry() {
    final raw = _persistence.getString(geometryKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final geometry = WindowGeometry.fromJson(
        Map<String, Object?>.from(decoded),
      );
      if (geometry == null) return null;
      return _clamp(geometry);
    } catch (error, stackTrace) {
      Log.error('读取窗口尺寸失败: $error\n$stackTrace');
      return null;
    }
  }

  Future<void> saveGeometry(WindowGeometry geometry) {
    return _persistence.setString(geometryKey, jsonEncode(geometry.toJson()));
  }

  WindowForm readForm() {
    return WindowForm.fromName(_persistence.getString(formKey));
  }

  Future<void> saveForm(WindowForm form) {
    return _persistence.setString(formKey, form.name);
  }

  /// Keeps a window that was saved on another screen usable on this one.
  ///
  /// The minimum of the desktop is the floor: a window smaller than that
  /// cannot draw the shell, so a document that carries one is treated as if
  /// the width or the height had been the minimum all along.
  static WindowGeometry _clamp(WindowGeometry geometry) {
    final width = math.max(
      geometry.width,
      PlatformConstants.desktopWindowMinWidth,
    );
    final height = math.max(
      geometry.height,
      PlatformConstants.desktopWindowMinHeight,
    );
    if (width == geometry.width && height == geometry.height) {
      return geometry;
    }
    return WindowGeometry(
      width: width,
      height: height,
      left: geometry.left,
      top: geometry.top,
      maximized: geometry.maximized,
    );
  }
}
