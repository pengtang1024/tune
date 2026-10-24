import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';

/// A panel that floats over the content of a page without replacing it.
///
/// The host owns the parts a panel should not have to repeat: the width rule,
/// the edge of the content area and the entrance. The panel itself is built by
/// [panelBuilder] only while it is visible.
///
/// The panel covers the content of the page, not the whole shell. The child
/// stays in the tree, so its scroll position and filters survive, but it is
/// dimmed, out of focus and blocked by a scrim while the panel is open. The
/// sidebar and the player dock live outside this host and stay usable.
class SidePanelHost extends StatefulWidget {
  /// Whether the panel is open.
  final bool open;

  /// Closes the panel when the scrim is clicked.
  final VoidCallback onClose;

  /// The words a reader hears for the scrim.
  final String barrierLabel;

  /// The page the panel floats over.
  final Widget child;

  /// Builds the panel while it is visible.
  final WidgetBuilder panelBuilder;

  const SidePanelHost({
    super.key,
    required this.open,
    required this.onClose,
    required this.barrierLabel,
    required this.child,
    required this.panelBuilder,
  });

  @override
  State<SidePanelHost> createState() => _SidePanelHostState();
}

class _SidePanelHostState extends State<SidePanelHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _entrance;
  late final Animation<Offset> _slide;

  /// Whether the panel is in the tree, including the closing animation.
  bool _visible = false;

  /// Whether the platform asks for reduced motion.
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CompactTokens.standardMotion,
    );
    _entrance = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(_entrance);

    _visible = widget.open;
    if (widget.open) _controller.value = 1;
    _controller.addStatusListener(_handleStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce == _reduceMotion) return;
    _reduceMotion = reduce;
    _controller.duration = reduce
        ? Duration.zero
        : CompactTokens.standardMotion;
  }

  @override
  void didUpdateWidget(covariant SidePanelHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open == oldWidget.open) return;

    if (widget.open) {
      if (!_visible) setState(() => _visible = true);
      // Forward from the current value, so opening while the panel is still
      // closing picks the panel up instead of restarting it from nothing.
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleStatus);
    _entrance.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.dismissed || !_visible) return;
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _width(constraints.maxWidth);

        return Stack(
          fit: StackFit.expand,
          children: [
            // The page is dimmed and out of focus, but it stays in the tree:
            // its scroll position, search text and controllers survive.
            ExcludeFocus(excluding: _visible, child: widget.child),
            if (_visible) ...<Widget>[
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !widget.open,
                  child: FadeTransition(
                    opacity: _entrance,
                    child: ModalBarrier(
                      dismissible: true,
                      onDismiss: widget.onClose,
                      semanticsLabel: widget.barrierLabel,
                      color: theme.colorScheme.scrim.withValues(alpha: 0.28),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: CompactTokens.sidePanelGutter,
                right: CompactTokens.sidePanelGutter,
                bottom: CompactTokens.sidePanelGutter,
                width: width,
                child: IgnorePointer(
                  ignoring: !widget.open,
                  child: ExcludeFocus(
                    excluding: !widget.open,
                    child: FadeTransition(
                      opacity: _entrance,
                      child: SlideTransition(
                        position: _slide,
                        child: Focus(
                          autofocus: true,
                          child: widget.panelBuilder(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  double _width(double available) {
    final room = math.max(0.0, available - CompactTokens.sidePanelGutter * 2);
    final preferred = math.min(
      CompactTokens.sidePanelWidthMax,
      math.max(
        CompactTokens.sidePanelWidthMin,
        available - CompactTokens.sidePanelContentReserve,
      ),
    );
    return math.min(room, preferred);
  }
}
