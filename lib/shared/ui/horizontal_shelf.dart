import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/shared/ui/dense_icon_action.dart';

/// A row of cards that scrolls sideways.
///
/// A desktop pointer cannot reach the end of a horizontal list on its own:
/// the wheel carries only a vertical delta, Material gives a horizontal list
/// no bar, and a mouse does not drag a scroll view. The row therefore carries
/// its own arrow and bar. Touch keeps its own gesture.
class HorizontalShelf extends StatefulWidget {
  /// How many items the row holds.
  final int itemCount;

  /// Builds one item of the row.
  final IndexedWidgetBuilder itemBuilder;

  /// The space between two items.
  final double spacing;

  /// The key of the scroll view, for the page and its tests.
  final Key? listKey;

  /// The words the previous arrow says.
  final String previousLabel;

  /// The words the next arrow says.
  final String nextLabel;

  /// How far from the top of the row the arrows are centred.
  ///
  /// The arrows sit on the midline of a cover, where the card keeps no
  /// control of its own; null centres them in the row.
  final double? arrowCenter;

  const HorizontalShelf({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.spacing,
    required this.previousLabel,
    required this.nextLabel,
    this.listKey,
    this.arrowCenter,
  });

  @override
  State<HorizontalShelf> createState() => _HorizontalShelfState();
}

class _HorizontalShelfState extends State<HorizontalShelf> {
  final ScrollController _scroll = ScrollController();

  /// Whether the row has something before the first visible item.
  bool _back = false;

  /// Whether the row has something after the last visible item.
  bool _forward = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateSides);
    // The extents exist only after the first layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateSides());
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_updateSides)
      ..dispose();
    super.dispose();
  }

  /// Repaints the arrows when one side of the row appears or disappears.
  void _updateSides() {
    if (!mounted || !_scroll.hasClients) return;
    final position = _scroll.position;
    final back = position.pixels > position.minScrollExtent + 0.5;
    final forward = position.pixels < position.maxScrollExtent - 0.5;
    if (back == _back && forward == _forward) return;
    setState(() {
      _back = back;
      _forward = forward;
    });
  }

  /// Moves the row one page, without overshooting the last one.
  void _move(int direction) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final target =
        (position.pixels + position.viewportDimension * 0.8 * direction)
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
    if (target == position.pixels) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      position.jumpTo(target);
      return;
    }
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NotificationListener<ScrollMetricsNotification>(
          // A resized window changes how much of the row fits, and the
          // arrows have to follow without waiting for a scroll.
          onNotification: (_) {
            _updateSides();
            return false;
          },
          child: Scrollbar(
            controller: _scroll,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: ListView.separated(
              key: widget.listKey,
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              itemCount: widget.itemCount,
              separatorBuilder: (context, index) =>
                  SizedBox(width: widget.spacing),
              itemBuilder: widget.itemBuilder,
            ),
          ),
        ),
        if (_back) _edge(back: true),
        if (_forward) _edge(back: false),
      ],
    );
  }

  Widget _edge({required bool back}) {
    final arrow = _arrow(
      key: ValueKey(
        back ? 'horizontal-shelf-back' : 'horizontal-shelf-forward',
      ),
      icon: back ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
      label: back ? widget.previousLabel : widget.nextLabel,
      onPressed: () => _move(back ? -1 : 1),
    );
    final center = widget.arrowCenter;
    if (center == null) {
      return Align(
        alignment: back ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(
            left: back ? CompactTokens.space4 : 0,
            right: back ? 0 : CompactTokens.space4,
          ),
          child: arrow,
        ),
      );
    }
    return Positioned(
      top: center - CompactTokens.controlCompact / 2,
      left: back ? CompactTokens.space4 : null,
      right: back ? null : CompactTokens.space4,
      child: arrow,
    );
  }

  /// The mark that says "there is more on this side".
  ///
  /// It sits on top of the cards, so it carries its own surface instead of
  /// borrowing the one behind it: a cover can be any colour.
  Widget _arrow({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return Material(
      key: key,
      color: theme.colorScheme.surfaceContainerHighest,
      elevation: 2,
      shadowColor: theme.shadowColor.withValues(alpha: 0.32),
      shape: CircleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: DenseIconAction(
        icon: icon,
        tooltip: label,
        onPressed: onPressed,
        size: CompactTokens.controlCompact,
        iconSize: CompactTokens.icon18,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}
