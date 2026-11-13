import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The keyboard focus of the search field of the library.
///
/// The shortcut that focuses it lives above every route, and the field itself
/// lives in the library page. The node is the one thing the two share: the
/// page attaches it to the field, and the shortcut asks it for the focus
/// without holding a reference to a page.
///
/// The node belongs to the application, not to the page: navigating away and
/// back has to keep the shortcut working, and a node owned by the page would
/// die with it.
final librarySearchFocusProvider = Provider<FocusNode>((ref) {
  final node = FocusNode(debugLabel: 'library-search');
  ref.onDispose(node.dispose);
  return node;
});
