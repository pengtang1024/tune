import 'dart:async';

import 'package:flutter/material.dart';

/// The clickable area of a track row.
///
/// A single click and a double click mean different things in the lists of
/// the app: a single click plays the track, a double click likes it. The
/// second click of a double click is only known when it arrives, so the area
/// waits a moment before it plays.
///
/// The buttons of a row sit outside the area, so they answer right away.
class TrackClickArea extends StatefulWidget {
  final Widget child;
  final VoidCallback onClick;
  final VoidCallback onDoubleClick;
  final Color? hoverColor;
  final BorderRadius? borderRadius;

  /// The time the area waits for a second click.
  final Duration window;

  const TrackClickArea({
    super.key,
    required this.child,
    required this.onClick,
    required this.onDoubleClick,
    this.hoverColor,
    this.borderRadius,
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
      // The second click of a double click: the track is liked, not played.
      _window!.cancel();
      _window = null;
      widget.onDoubleClick();
      return;
    }

    _window = Timer(widget.window, () {
      _window = null;
      widget.onClick();
    });
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
