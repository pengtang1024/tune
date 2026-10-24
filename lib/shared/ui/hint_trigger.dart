import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tune/shared/ui/hint_layer.dart';

/// Says that a widget carries a hint, without painting the hint.
///
/// The trigger is three things and no overlay: a [MouseRegion] for the
/// pointer, a [Listener] for a long touch, and a semantic tooltip for the
/// screen reader. The card belongs to [HintLayer], so a row can carry eight
/// triggers and still hold no card until one of them asks for it.
class HintTrigger extends StatefulWidget {
  /// The words on the card.
  final String message;

  /// The words the screen reader says, when they differ from the card.
  final String? label;

  /// The thing the hint belongs to.
  final Widget child;

  /// How long the pointer rests before the card opens.
  final Duration waitDuration;

  /// How long the card stays after a long touch ends.
  final Duration visibleDuration;

  /// How long the card takes to leave.
  final Duration exitDuration;

  /// Whether the card prefers to stand below its anchor.
  final bool preferBelow;

  /// The room between the anchor and the card.
  final double verticalOffset;

  /// Whether a touch gives a little feedback when the hint opens.
  final bool enableFeedback;

  /// Whether the trigger listens at all.
  final bool enabled;

  const HintTrigger({
    super.key,
    required this.message,
    required this.child,
    this.label,
    this.waitDuration = const Duration(milliseconds: 400),
    this.visibleDuration = const Duration(seconds: 4),
    this.exitDuration = const Duration(milliseconds: 120),
    this.preferBelow = false,
    this.verticalOffset = 12,
    this.enableFeedback = true,
    this.enabled = true,
  });

  @override
  State<HintTrigger> createState() => _HintTriggerState();
}

class _HintTriggerState extends State<HintTrigger> {
  /// The device kinds that cannot hover, so a long press is their way in.
  static const Set<PointerDeviceKind> _touchKinds = <PointerDeviceKind>{
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.unknown,
  };

  HintController? _controller;
  Timer? _showTimer;
  Timer? _hideTimer;
  Timer? _touchTimer;
  LongPressGestureRecognizer? _longPress;
  int? _pointer;
  bool _hovering = false;
  bool _showing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = HintLayer.maybeOf(context);
    if (identical(controller, _controller)) return;
    _close();
    _controller = controller;
  }

  @override
  void didUpdateWidget(HintTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _close();
      return;
    }
    if (_showing &&
        (oldWidget.message != widget.message ||
            oldWidget.label != widget.label)) {
      _show();
    }
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _touchTimer?.cancel();
    _longPress
      ?..onLongPressCancel = null
      ..onLongPress = null
      ..onLongPressUp = null
      ..dispose();
    _showing = false;
    final controller = _controller;
    if (controller != null) {
      // A row can leave the tree while the list is building. Telling the
      // layer now would mark it dirty in the middle of that build, so the
      // close waits for the frame to end.
      if (SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => controller.hide(this),
        );
      } else {
        controller.hide(this);
      }
    }
    super.dispose();
  }

  void _handleEnter(PointerEnterEvent event) {
    if (!widget.enabled) return;
    _hovering = true;
    _hideTimer?.cancel();
    _showTimer?.cancel();
    _showTimer = Timer(widget.waitDuration, () {
      if (!mounted || !_hovering) return;
      _show();
    });
  }

  void _handleExit(PointerExitEvent event) {
    _hovering = false;
    _showTimer?.cancel();
    if (!_showing) return;
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.exitDuration, () {
      if (!mounted || _hovering) return;
      _hide();
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    if (!widget.enabled) return;
    if (!_touchKinds.contains(event.kind)) return;

    _pointer = event.pointer;
    final recognizer = _longPress ??=
        LongPressGestureRecognizer(
            debugOwner: this,
            supportedDevices: _touchKinds,
          )
          ..onLongPressCancel = _handleLongPressCancel
          ..onLongPress = _handleLongPress
          ..onLongPressUp = _handleLongPressUp;
    recognizer.addPointer(event);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_pointer == event.pointer) _pointer = null;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_pointer == event.pointer) _pointer = null;
  }

  void _handleLongPress() {
    if (!mounted || !widget.enabled) return;
    if (widget.enableFeedback) Feedback.forLongPress(context);
    _show();
  }

  void _handleLongPressUp() {
    if (!_showing) return;
    _touchTimer?.cancel();
    // The card stays long enough to be read after the finger leaves, the
    // way a long touch has always behaved.
    _touchTimer = Timer(widget.visibleDuration, () {
      if (!mounted) return;
      _hide();
    });
  }

  void _handleLongPressCancel() {
    _hide();
  }

  /// Puts the card of this trigger on the layer.
  void _show() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final anchor = _anchorOf(context);
    if (anchor == null || anchor.isEmpty) return;

    _hideTimer?.cancel();
    _showTimer?.cancel();
    _showing = true;
    controller.show(
      HintIntent(
        owner: this,
        message: widget.message,
        semanticsLabel: widget.label,
        anchor: anchor,
        waitDuration: widget.waitDuration,
        visibleDuration: widget.visibleDuration,
        exitDuration: widget.exitDuration,
        preferBelow: widget.preferBelow,
        verticalOffset: widget.verticalOffset,
      ),
    );
  }

  /// Takes the card of this trigger away, or leaves the card of another one.
  void _hide() {
    _showing = false;
    _hideTimer?.cancel();
    _touchTimer?.cancel();
    _controller?.hide(this);
  }

  /// Closes every timer of this trigger and the card it owns.
  void _close() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _touchTimer?.cancel();
    if (_showing) _hide();
  }

  static Rect? _anchorOf(BuildContext context) {
    final object = context.findRenderObject();
    if (object is! RenderBox || !object.attached || !object.hasSize) {
      return null;
    }
    return MatrixUtils.transformRect(
      object.getTransformTo(null),
      Offset.zero & object.size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    Widget child = label == null || label.isEmpty
        ? widget.child
        : Semantics(tooltip: label, child: widget.child);

    return MouseRegion(
      onEnter: widget.enabled ? _handleEnter : null,
      onExit: widget.enabled ? _handleExit : null,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _handlePointerDown,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        child: child,
      ),
    );
  }
}
