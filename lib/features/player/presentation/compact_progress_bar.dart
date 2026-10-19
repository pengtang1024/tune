import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/shared/utils/duration_format.dart';

class CompactProgressBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final bool enabled;

  const CompactProgressBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.enabled = true,
  });

  @override
  State<CompactProgressBar> createState() => _CompactProgressBarState();
}

class _CompactProgressBarState extends State<CompactProgressBar> {
  double? _dragFraction;
  bool _hovering = false;

  int get _durationMs => widget.duration.inMilliseconds;

  bool get _canSeek => widget.enabled && _durationMs > 0;

  double get _fraction {
    if (_dragFraction != null) return _dragFraction!;
    if (_durationMs <= 0) return 0;
    return (widget.position.inMilliseconds / _durationMs)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  Duration get _displayedPosition {
    if (_dragFraction == null || _durationMs <= 0) return widget.position;
    return Duration(milliseconds: (_durationMs * _dragFraction!).round());
  }

  void _updateFromPosition(double dx, double width) {
    if (width <= 0) return;
    setState(() {
      _dragFraction = (dx / width).clamp(0.0, 1.0).toDouble();
    });
  }

  void _commit() {
    final fraction = _dragFraction;
    if (fraction == null || _durationMs <= 0) return;
    widget.onSeek(Duration(milliseconds: (_durationMs * fraction).round()));
    setState(() => _dragFraction = null);
  }

  void _cancelDrag() {
    if (_dragFraction == null) return;
    setState(() => _dragFraction = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = theme.colorScheme.primary;
    final inactive = theme.colorScheme.outlineVariant;

    return Semantics(
      label: '播放进度',
      value:
          '${formatDuration(_displayedPosition)} / '
          '${formatDuration(widget.duration)}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 18,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final thumbLeft = (width * _fraction - 5)
                    .clamp(0.0, (width - 10).clamp(0.0, width))
                    .toDouble();

                return MouseRegion(
                  cursor: _canSeek
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  onEnter: (_) => setState(() => _hovering = true),
                  onExit: (_) => setState(() => _hovering = false),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: _canSeek
                        ? (details) => _updateFromPosition(
                            details.localPosition.dx,
                            width,
                          )
                        : null,
                    onTapUp: _canSeek ? (_) => _commit() : null,
                    onTapCancel: _canSeek ? _cancelDrag : null,
                    onHorizontalDragStart: _canSeek
                        ? (details) => _updateFromPosition(
                            details.localPosition.dx,
                            width,
                          )
                        : null,
                    onHorizontalDragUpdate: _canSeek
                        ? (details) => _updateFromPosition(
                            details.localPosition.dx,
                            width,
                          )
                        : null,
                    onHorizontalDragEnd: _canSeek ? (_) => _commit() : null,
                    onHorizontalDragCancel: _canSeek ? _cancelDrag : null,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: inactive,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          width: width * _fraction,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: active,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Positioned(
                          left: thumbLeft,
                          top: 4,
                          child: AnimatedOpacity(
                            duration: CompactTokens.fastMotion,
                            opacity: _hovering || _dragFraction != null
                                ? 1
                                : 0.78,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: active,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(_displayedPosition),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                formatDuration(widget.duration),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
