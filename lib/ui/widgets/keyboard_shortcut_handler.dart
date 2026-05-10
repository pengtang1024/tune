import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/providers/player_providers.dart';

class KeyboardShortcutHandler extends ConsumerStatefulWidget {
  final Widget child;
  const KeyboardShortcutHandler({super.key, required this.child});

  @override
  ConsumerState<KeyboardShortcutHandler> createState() => _KeyboardShortcutHandlerState();
}

class _KeyboardShortcutHandlerState extends ConsumerState<KeyboardShortcutHandler> {
  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _onSpace,
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): _onSeekBack,
        LogicalKeySet(LogicalKeyboardKey.arrowRight): _onSeekForward,
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft): _onPrevious,
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight): _onNext,
        LogicalKeySet(LogicalKeyboardKey.mediaTrackPrevious): _onPrevious,
        LogicalKeySet(LogicalKeyboardKey.mediaTrackNext): _onNext,
        LogicalKeySet(LogicalKeyboardKey.mediaPlayPause): _onSpace,
      },
      child: Focus(autofocus: true, child: widget.child),
    );
  }

  void _onSpace() {
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    final state = ref.read(playerStateNotifierProvider);
    HapticFeedback.lightImpact();
    if (state.isPlaying) {
      playerNotifier.pause();
    } else {
      playerNotifier.resume();
    }
  }

  void _onSeekBack() {
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    final state = ref.read(playerStateNotifierProvider);
    final newPos = state.position - const Duration(seconds: 5);
    playerNotifier.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
  }

  void _onSeekForward() {
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    final state = ref.read(playerStateNotifierProvider);
    final newPos = state.position + const Duration(seconds: 5);
    playerNotifier.seekTo(newPos > state.duration ? state.duration : newPos);
  }

  void _onPrevious() {
    HapticFeedback.lightImpact();
    ref.read(playerStateNotifierProvider.notifier).previous();
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    ref.read(playerStateNotifierProvider.notifier).next();
  }
}
