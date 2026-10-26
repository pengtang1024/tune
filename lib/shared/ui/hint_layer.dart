import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/shared/ui/tooltip_card.dart';

/// One hint that asks to be shown.
///
/// A trigger does not paint anything: it says the words, the rectangle it
/// stands on and how long it waits, and the [HintLayer] owns the card. The
/// anchor is a global rectangle taken when the hint opens, so the layer does
/// not need one [LayerLink] per trigger.
@immutable
class HintIntent {
  /// The trigger that asked for the hint.
  ///
  /// The owner is compared by identity: a new hint from the same trigger
  /// replaces the words, a hide only works for the trigger that owns the
  /// card.
  final Object owner;

  /// The words on the card.
  final String message;

  /// The words the screen reader says when the card opens.
  final String? semanticsLabel;

  /// The rectangle of the thing the hint belongs to, in global coordinates.
  final Rect anchor;

  /// How long the pointer rests before the card opens.
  final Duration waitDuration;

  /// How long a card opened by a touch stays after the finger leaves.
  final Duration visibleDuration;

  /// How long the card takes to leave.
  final Duration exitDuration;

  /// Whether the card prefers to stand below its anchor.
  final bool preferBelow;

  /// The room between the anchor and the card.
  final double verticalOffset;

  const HintIntent({
    required this.owner,
    required this.message,
    required this.anchor,
    this.semanticsLabel,
    this.waitDuration = const Duration(milliseconds: 400),
    this.visibleDuration = const Duration(seconds: 4),
    this.exitDuration = const Duration(milliseconds: 120),
    this.preferBelow = false,
    this.verticalOffset = 12,
  });
}

/// The one open hint of the app.
///
/// The controller is owned by [HintLayer]; triggers only call [show] and
/// [hide]. There is at most one active intent, so a viewport never paints
/// two cards and the idle tree holds no card at all.
class HintController extends ChangeNotifier {
  HintIntent? _active;
  bool _disposed = false;

  /// The hint that is on the screen, if any.
  HintIntent? get active => _active;

  /// Shows [intent], replacing the hint of another trigger.
  void show(HintIntent intent) {
    if (_disposed) return;
    final current = _active;
    if (current != null &&
        identical(current.owner, intent.owner) &&
        current.message == intent.message &&
        current.semanticsLabel == intent.semanticsLabel &&
        current.anchor == intent.anchor) {
      return;
    }
    _active = intent;
    notifyListeners();
  }

  /// Hides the hint of [owner] and leaves the hint of another trigger alone.
  void hide(Object owner) {
    if (_disposed) return;
    if (!identical(_active?.owner, owner)) return;
    _active = null;
    notifyListeners();
  }

  /// Hides whatever hint is open.
  void dismiss() {
    if (_disposed) return;
    if (_active == null) return;
    _active = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // A trigger that leaves the tree after the layer may still hold a
    // post-frame close. It is allowed to ask, and the answer is silence.
    _disposed = true;
    super.dispose();
  }
}

/// The scope that owns the one hint of an app.
///
/// The layer sits above the navigator, so a card is painted above every
/// route and every dialog and is clipped by none of them. A page that has no
/// layer falls back to the old tooltip of [TuneTooltip], which keeps a
/// standalone widget test working.
class HintLayer extends StatefulWidget {
  /// The app below the hint card.
  final Widget child;

  const HintLayer({super.key, required this.child});

  /// The controller of the closest layer, or null when there is none.
  static HintController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_HintScope>()?.controller;
  }

  @override
  State<HintLayer> createState() => _HintLayerState();
}

class _HintLayerState extends State<HintLayer> {
  final HintController _controller = HintController();
  late final ValueNotifier<Widget> _child;
  late final OverlayEntry _entry;

  @override
  void initState() {
    super.initState();
    _child = ValueNotifier(widget.child);
    _entry = OverlayEntry(
      builder: (context) => _HintHost(controller: _controller, child: _child),
    );
  }

  @override
  void didUpdateWidget(HintLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The navigator can be rebuilt by the app while the overlay stays. The
    // entry holds a notifier instead of the old widget, so the card follows
    // the app and never keeps a navigator from a previous frame.
    _child.value = widget.child;
  }

  @override
  void dispose() {
    _entry
      ..remove()
      ..dispose();
    _child.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _HintScope(
      controller: _controller,
      child: Overlay(initialEntries: [_entry]),
    );
  }
}

class _HintScope extends InheritedWidget {
  final HintController controller;

  const _HintScope({required this.controller, required super.child});

  @override
  bool updateShouldNotify(_HintScope oldWidget) =>
      controller != oldWidget.controller;
}

/// The entry of the layer: the app, and one card when a trigger asks for it.
class _HintHost extends StatefulWidget {
  final HintController controller;
  final ValueNotifier<Widget> child;

  const _HintHost({required this.controller, required this.child});

  @override
  State<_HintHost> createState() => _HintHostState();
}

class _HintHostState extends State<_HintHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: CompactTokens.fastMotion,
  );

  HintIntent? _intent;
  Size? _size;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChange);
    _handleChange();
  }

  @override
  void didUpdateWidget(_HintHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleChange);
      widget.controller.addListener(_handleChange);
      _handleChange();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A window that changes size moves the anchor away from its row. The
    // card is not tied to a layout of its own, so it closes instead of
    // pointing at a place that no longer exists.
    final size = MediaQuery.sizeOf(context);
    final previous = _size;
    _size = size;
    if (previous != null && previous != size && _intent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.controller.dismiss();
      });
    }
  }

  void _handleChange() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sync();
      });
      return;
    }
    _sync();
  }

  void _sync() {
    final active = widget.controller.active;
    if (active == null) {
      if (_intent == null) return;
      _fade.reverse().whenComplete(() {
        if (!mounted) return;
        if (widget.controller.active == null && _intent != null) {
          setState(() => _intent = null);
        }
      });
      return;
    }

    setState(() {
      _intent = active;
      _fade.duration = active.exitDuration;
    });
    _fade.forward();
    final label = active.semanticsLabel;
    if (label != null && label.isNotEmpty) {
      SemanticsService.tooltip(label);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intent = _intent;
    // The card takes the theme here, inside the overlay and not in the row.
    // A hint that is open while the theme changes therefore repaints with
    // the new card in the same frame.
    final theme = TooltipTheme.of(context);

    final app = _app();

    if (intent == null) return app;

    // The anchor was taken in global coordinates; the card is painted in
    // the coordinate space of this overlay. Converting through the overlay
    // keeps a nested layer (a test, a panel) honest.
    final box = Overlay.of(context).context.findRenderObject();
    final anchor = box is RenderBox && box.hasSize
        ? Rect.fromPoints(
            box.globalToLocal(intent.anchor.topLeft),
            box.globalToLocal(intent.anchor.bottomRight),
          )
        : intent.anchor;

    return Stack(
      fit: StackFit.expand,
      children: [
        app,
        Positioned.fill(
          bottom: MediaQuery.maybeViewInsetsOf(context)?.bottom ?? 0,
          child: CustomSingleChildLayout(
            delegate: _HintPositionDelegate(
              anchor: anchor.center,
              verticalOffset: intent.verticalOffset,
              preferBelow: intent.preferBelow,
            ),
            child: IgnorePointer(
              child: FadeTransition(
                opacity: _fade,
                child: buildTooltipCard(theme, intent.message),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The app below the card, closed by the gestures a hint goes away on.
  Widget _app() {
    return ValueListenableBuilder<Widget>(
      valueListenable: widget.child,
      builder: (context, child, _) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            if (widget.controller.active != null) {
              widget.controller.dismiss();
            }
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (_) {
              if (widget.controller.active != null) {
                widget.controller.dismiss();
              }
              return false;
            },
            child: NotificationListener<NavigationNotification>(
              onNotification: (_) {
                if (widget.controller.active != null) {
                  widget.controller.dismiss();
                }
                return false;
              },
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Places the card above its anchor, or below it when there is no room.
class _HintPositionDelegate extends SingleChildLayoutDelegate {
  final Offset anchor;
  final double verticalOffset;
  final bool preferBelow;

  const _HintPositionDelegate({
    required this.anchor,
    required this.verticalOffset,
    required this.preferBelow,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return positionDependentBox(
      size: size,
      childSize: childSize,
      target: anchor,
      verticalOffset: verticalOffset,
      preferBelow: preferBelow,
    );
  }

  @override
  bool shouldRelayout(_HintPositionDelegate oldDelegate) {
    return anchor != oldDelegate.anchor ||
        verticalOffset != oldDelegate.verticalOffset ||
        preferBelow != oldDelegate.preferBelow;
  }
}
