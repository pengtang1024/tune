import 'package:flutter/widgets.dart';

/// Marks a subtree that owns the keyboard while it is open.
///
/// The shortcuts of the app sit above every route, so a key pressed while a
/// panel floats over the page would reach them as well. A panel wraps its
/// content in this scope, and the shortcuts leave the keys alone while the
/// focus is inside: the panel is the surface the reader is working with.
///
/// The marker is a plain widget on purpose. It carries no state of its own,
/// and the panels do not have to know about the shortcuts above them: the
/// existence of the marker in the focus ancestry is the whole contract.
class ShortcutCaptureScope extends StatelessWidget {
  final Widget child;

  const ShortcutCaptureScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
