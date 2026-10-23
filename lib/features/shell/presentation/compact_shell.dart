import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/features/player/presentation/player_dock.dart';
import 'package:tune/features/queue/presentation/queue_panel.dart';
import 'package:tune/features/shell/presentation/app_sidebar.dart';
import 'package:tune/shared/ui/side_panel_host.dart';

/// The shell of the app: navigation on the left, a page in the middle and the
/// player dock at the bottom.
///
/// The queue is not a page. It is a panel that floats over the page and leaves
/// the navigation and the dock outside of its scrim, so the reader can keep
/// controlling playback while looking at the queue. The open state belongs to
/// the shell because the panel is a property of this layout, not a place in
/// the router.
class CompactShell extends StatefulWidget {
  final String currentPath;
  final Widget child;

  const CompactShell({
    super.key,
    required this.currentPath,
    required this.child,
  });

  @override
  State<CompactShell> createState() => _CompactShellState();
}

class _CompactShellState extends State<CompactShell> {
  bool _queueOpen = false;

  void _toggleQueue() {
    setState(() => _queueOpen = !_queueOpen);
  }

  void _closeQueue() {
    if (!_queueOpen) return;
    setState(() => _queueOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _closeQueue},
      child: PopScope(
        // The panel is not a route, so the system back action has to close it
        // before it leaves the shell. The listener only fires when the pop was
        // stopped, which is exactly the case where the panel was open.
        canPop: !_queueOpen,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _closeQueue();
        },
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact =
                          constraints.maxWidth <
                          CompactTokens.sidebarCompactBreakpoint;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppSidebar(
                            currentPath: widget.currentPath,
                            compact: compact,
                            // The page below the scrim should not change while
                            // the panel hides it. A navigation closes the panel
                            // first and then goes to the page the reader chose.
                            onNavigate: _closeQueue,
                          ),
                          Expanded(
                            child: SidePanelHost(
                              open: _queueOpen,
                              onClose: _closeQueue,
                              barrierLabel: context.loc.close,
                              panelBuilder: (context) =>
                                  QueuePanel(onClose: _closeQueue),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: const Alignment(0.9, -1.0),
                                    radius: 1.2,
                                    colors: [
                                      theme.colorScheme.primary.withValues(
                                        alpha: 0.05,
                                      ),
                                      Colors.transparent,
                                    ],
                                    stops: const [0, 0.7],
                                  ),
                                ),
                                // The page is not switched here. The shell
                                // hands the navigator of the router to the page
                                // area, and the router moves between the pages
                                // with a motion of its own. A second switch in
                                // this place would keep two navigators alive at
                                // the same time, and the key of the router
                                // belongs to only one of them.
                                child: widget.child,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                PlayerDock(onToggleQueue: _toggleQueue, queueOpen: _queueOpen),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
