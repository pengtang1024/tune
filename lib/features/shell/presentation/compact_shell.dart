import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/layout/layout_metrics.dart';
import 'package:tune/app/layout/window_form_controller.dart';
import 'package:tune/core/config/platform_constants.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/window_layout_store.dart';
import 'package:tune/features/player/presentation/player_dock.dart';
import 'package:tune/features/queue/presentation/queue_panel.dart';
import 'package:tune/features/shell/presentation/app_bottom_bar.dart';
import 'package:tune/features/shell/presentation/app_sidebar.dart';
import 'package:tune/features/shell/presentation/mini_player_bar.dart';
import 'package:tune/shared/ui/side_panel_host.dart';

/// The shell of the app: navigation on the left, a page in the middle and the
/// player dock at the bottom.
///
/// The queue is not a page. It is a panel that floats over the page and leaves
/// the navigation and the dock outside of its scrim, so the reader can keep
/// controlling playback while looking at the queue. The open state belongs to
/// the shell because the panel is a property of this layout, not a place in
/// the router.
class CompactShell extends ConsumerStatefulWidget {
  final String currentPath;
  final Widget child;

  /// Whether the shell is drawing for a touch platform.
  ///
  /// The app leaves it null and reads the build it runs in; a test passes
  /// true to draw the phone shell on a desktop host.
  final bool? mobile;

  const CompactShell({
    super.key,
    required this.currentPath,
    required this.child,
    this.mobile,
  });

  @override
  ConsumerState<CompactShell> createState() => _CompactShellState();
}

class _CompactShellState extends ConsumerState<CompactShell> {
  bool _queueOpen = false;

  void _toggleQueue() {
    setState(() => _queueOpen = !_queueOpen);
  }

  void _closeQueue() {
    if (!_queueOpen) return;
    setState(() => _queueOpen = false);
  }

  /// Shrinks the window to the bar.
  void _enterMini() {
    ref.read(windowFormProvider.notifier).setForm(WindowForm.mini);
  }

  /// Returns the window to the shell it came from.
  void _leaveMini() {
    ref.read(windowFormProvider.notifier).setForm(WindowForm.normal);
  }

  /// Opens the page that fills the screen with the current track.
  void _openNowPlaying() {
    context.push('/now-playing');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The form belongs to the window, but the shell is the place that draws
    // it. The branch happens in this State so the pages of the router stay
    // mounted: a page kept offstage keeps its scroll and its fields.
    final mini = ref.watch(windowFormProvider) == WindowForm.mini;

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
          // The shell stays mounted while the window is mini, so the pages of
          // the router keep their scroll and their fields. Offstage skips the
          // layout and the paint of the shell without disposing it.
          body: Stack(
            fit: StackFit.expand,
            children: [
              Offstage(
                offstage: mini,
                child: SafeArea(
                  top: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final metrics = LayoutMetrics.of(
                        Size(constraints.maxWidth, constraints.maxHeight),
                        mobile: widget.mobile ?? PlatformConstants.isMobile,
                      );
                      final page = SidePanelHost(
                        open: _queueOpen,
                        onClose: _closeQueue,
                        bottomSheet: metrics.usesBottomNavigation,
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
                          // The page is not switched here. The shell hands the
                          // navigator of the router to the page area, and the
                          // router moves between the pages with a motion of its
                          // own. A second switch in this place would keep two
                          // navigators alive at the same time, and the key of
                          // the router belongs to only one of them.
                          child: widget.child,
                        ),
                      );

                      if (metrics.usesBottomNavigation) {
                        // A phone has no pointer and no spare height: the rail
                        // becomes a bar under the thumb, and the dock becomes
                        // one row that opens the full page.
                        return Column(
                          children: [
                            Expanded(child: page),
                            MiniPlayerBar(
                              onRestore: _openNowPlaying,
                              onQueue: _toggleQueue,
                            ),
                            AppBottomBar(
                              currentPath: widget.currentPath,
                              onNavigate: _closeQueue,
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppSidebar(
                                  currentPath: widget.currentPath,
                                  compact: metrics.usesCompactNavigation,
                                  // The page below the scrim should not change
                                  // while the panel hides it. A navigation
                                  // closes the panel first and then goes to the
                                  // page the reader chose.
                                  onNavigate: _closeQueue,
                                ),
                                Expanded(child: page),
                              ],
                            ),
                          ),
                          PlayerDock(
                            onToggleQueue: _toggleQueue,
                            queueOpen: _queueOpen,
                            onMini: _enterMini,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (mini) SafeArea(child: MiniPlayerBar(onRestore: _leaveMini)),
            ],
          ),
        ),
      ),
    );
  }
}
