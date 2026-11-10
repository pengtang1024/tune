import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/router/app_router.dart';
import 'package:tune/features/library/application/library_search_focus_provider.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/playback_state.dart';
import 'package:tune/shared/ui/shortcut_capture_scope.dart';

/// The keys that play the player from anywhere in the app.
///
/// The shortcuts sit above the router, in the builder of the app, because the
/// now playing page is a route of its own: a shortcut bound inside the shell
/// would stop working there.
///
/// The keys are only taken when the reader is not doing something else with
/// them:
///
/// - a text field that has the focus keeps every key it needs, so a space
///   typed into the search box does not pause the track;
/// - a slider keeps the arrows, because the arrows are how it is moved;
/// - a popup route (a dialog, a sheet, a menu) owns the keyboard while it is
///   open, so nothing reaches the player behind it;
/// - a panel that floated over the page keeps the keyboard as well, through
///   [ShortcutCaptureScope].
///
/// Escape is not bound here: the shell and the now playing page already close
/// their own panels with it.
class AppShortcuts extends ConsumerWidget {
  final Widget child;

  const AppShortcuts({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The node of the shortcuts does not take a focus stop of its own: it
    // hears the keys on their way up from whatever holds the focus. The route
    // below always holds it, so a key pressed before the reader clicks
    // anything still passes through here. A node that took the focus instead
    // would also keep the panels from taking theirs.
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space): () =>
            _togglePlayPause(ref),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _previous(ref),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _next(ref),
        const SingleActivator(LogicalKeyboardKey.keyM): () => _toggleMute(ref),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
            _focusSearch(ref),
      },
      child: child,
    );
  }

  void _togglePlayPause(WidgetRef ref) {
    if (_yieldsToText() || _yieldsToOverlay()) return;

    final state = ref.read(playbackControllerProvider);
    if (state.currentUri == null || state.status == PlaybackStatus.loading) {
      return;
    }
    ref.read(playbackControllerProvider.notifier).togglePlayPause();
  }

  void _previous(WidgetRef ref) {
    if (_yieldsToText() || _yieldsToOverlay() || _yieldsToSlider()) return;

    final state = ref.read(playbackControllerProvider);
    if (state.currentUri == null) return;
    ref.read(playbackControllerProvider.notifier).previous();
  }

  void _next(WidgetRef ref) {
    if (_yieldsToText() || _yieldsToOverlay() || _yieldsToSlider()) return;

    final state = ref.read(playbackControllerProvider);
    if (state.currentUri == null) return;
    ref.read(playbackControllerProvider.notifier).next();
  }

  void _toggleMute(WidgetRef ref) {
    if (_yieldsToText() || _yieldsToOverlay()) return;

    final state = ref.read(playbackControllerProvider);
    ref
        .read(playbackControllerProvider.notifier)
        .setVolume(state.volume > 0 ? 0 : 1);
  }

  void _focusSearch(WidgetRef ref) {
    if (_yieldsToOverlay()) return;

    final node = ref.read(librarySearchFocusProvider);
    if (node.context != null) {
      node.requestFocus();
      return;
    }

    // The library is not on the screen, so the field has nothing to take yet.
    // The page is built on the next frame, and the node is attached by then.
    ref.read(appRouterProvider).go('/library');
    WidgetsBinding.instance.addPostFrameCallback((_) => node.requestFocus());
  }

  /// Whether the focus is in a text field that needs the key itself.
  static bool _yieldsToText() {
    final context = FocusManager.instance.primaryFocus?.context;
    return context != null &&
        context.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  /// Whether the focus is on a slider, which owns the arrows.
  static bool _yieldsToSlider() {
    final context = FocusManager.instance.primaryFocus?.context;
    return context != null &&
        context.findAncestorWidgetOfExactType<Slider>() != null;
  }

  /// Whether a dialog, a sheet, a menu or a panel owns the keyboard.
  static bool _yieldsToOverlay() {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return false;
    if (context.findAncestorWidgetOfExactType<ShortcutCaptureScope>() != null) {
      return true;
    }
    return ModalRoute.of(context) is PopupRoute;
  }
}
