import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';

/// A panel that floats over the content of a page without replacing it.
///
/// The host owns the parts a panel should not have to repeat: the scrim, the
/// width rule, the edge of the content area, the entrance and the focus
/// boundary. The panel itself is built by [panelBuilder] only while it is
/// open, so a closed panel costs nothing.
///
/// The child stays in the tree. A page behind the panel keeps its scroll
/// position, its search text and its controller subscriptions; closing the
/// panel returns to exactly that page.
class SidePanelHost extends StatelessWidget {
  /// Whether the panel is open.
  final bool open;

  /// Called by the scrim, the panel or a close action of the host.
  final VoidCallback onClose;

  /// The words a reader hears when the scrim is reachable by a screen reader.
  final String barrierLabel;

  /// The page the panel floats over.
  final Widget child;

  /// Builds the panel while it is open.
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final width = available < CompactTokens.sidePanelFullWidthBreakpoint
            ? math.max(0.0, available - CompactTokens.sidePanelGutter * 2)
            : math.min(
                CompactTokens.sidePanelWidthMax,
                math.max(
                  CompactTokens.sidePanelWidthMin,
                  available - CompactTokens.sidePanelContentReserve,
                ),
              );

        return Stack(
          fit: StackFit.expand,
          children: [
            // The page stays alive while the panel is open, but it may not
            // take the keyboard away from the panel.
            ExcludeFocus(excluding: open, child: child),
            if (open) ...[
              Positioned.fill(
                child: ModalBarrier(
                  dismissible: true,
                  onDismiss: onClose,
                  semanticsLabel: barrierLabel,
                  color: theme.colorScheme.scrim.withValues(alpha: 0.28),
                ),
              ),
              Positioned(
                top: CompactTokens.sidePanelGutter,
                right: CompactTokens.sidePanelGutter,
                bottom: CompactTokens.sidePanelGutter,
                width: width,
                child: Focus(
                  autofocus: true,
                  child: _PanelEntrance(
                    reduceMotion: reduceMotion,
                    child: panelBuilder(context),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Slides the panel in on the first frame of the open state.
class _PanelEntrance extends StatelessWidget {
  final bool reduceMotion;
  final Widget child;

  const _PanelEntrance({required this.reduceMotion, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: reduceMotion ? Duration.zero : CompactTokens.standardMotion,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(value * CompactTokens.space32, 0),
          child: Opacity(opacity: 1 - value, child: child),
        );
      },
      child: child,
    );
  }
}
