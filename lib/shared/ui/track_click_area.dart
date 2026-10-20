import 'dart:async';

import 'package:flutter/material.dart';

/// The clickable area of a track row.
///
/// A single click and a double click mean different things in the lists of
/// the app: a single click plays the track, a double click likes it. A
/// double click plays as well, because the first click of it plays the
/// track already.
///
/// When the double click may not play the track, the area has to wait for a
/// possible second click before it plays, so the click waits a moment.
///
/// The buttons of a row sit outside the area, so they answer right away.
class TrackClickArea extends StatefulWidget {
  final Widget child;
  final VoidCallback onClick;
  final VoidCallback onDoubleClick;
  final Color? hoverColor;
  final BorderRadius? borderRadius;

  /// Whether a click waits for a possible second click before it plays.
  ///
  /// A double click that only likes the track may not play it, so the click
  /// has to wait to see whether a second click follows.
  final bool waitsForDoubleClick;

  /// The time the area waits for a second click.
  final Duration window;

  const TrackClickArea({
    super.key,
    required this.child,
    required this.onClick,
    required this.onDoubleClick,
    this.hoverColor,
    this.borderRadius,
    this.waitsForDoubleClick = false,
    this.window = const Duration(milliseconds: 300),
  });

  @override
  State<TrackClickArea> createState() => _TrackClickAreaState();
}

class _TrackClickAreaState extends State<TrackClickArea> {
  Timer? _window;

  @override
  void dispose() {
    _window?.cancel();
    super.dispose();
  }

  void _handleClick() {
    if (_window?.isActive ?? false) {
      // The second click of a double click: the track is liked.
      _window!.cancel();
      _window = null;
      widget.onDoubleClick();
      return;
    }

    if (widget.waitsForDoubleClick) {
      // The double click may not play the track, so the click waits to see
      // whether a second click follows.
      _window = Timer(widget.window, () {
        _window = null;
        widget.onClick();
      });
      return;
    }

    // The double click plays the track as well, so the first click plays it
    // right away and the second one only adds the heart.
    _window = Timer(widget.window, () => _window = null);
    widget.onClick();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handleClick,
      hoverColor: widget.hoverColor,
      borderRadius: widget.borderRadius,
      child: widget.child,
    );
  }
}
