import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 播放列表展开动画组件
/// 显示播放列表展开效果
class PlaylistExpandAnimation extends ThemedAnimationBase {
  final int itemCount;
  final double size;

  const PlaylistExpandAnimation({
    super.key,
    this.itemCount = 5,
    this.size = 200.0,
  });

  @override
  State<PlaylistExpandAnimation> createState() =>
      _PlaylistExpandAnimationState();
}

class _PlaylistExpandAnimationState
    extends ThemedAnimationStateBase<PlaylistExpandAnimation> {
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 1500));
    repeatAnimation();

    _expandAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _PlaylistExpandPainter(
            _expandAnimation.value,
            theme,
            widget.itemCount,
          ),
        );
      },
    );
  }
}

class _PlaylistExpandPainter extends CustomPainter {
  final double expandProgress;
  final ThemeData theme;
  final int itemCount;

  _PlaylistExpandPainter(this.expandProgress, this.theme, this.itemCount);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final itemHeight = size.height * 0.15;
    final itemSpacing = size.height * 0.02;
    final itemWidth = size.width * 0.8;
    final startX = (size.width - itemWidth) / 2;

    // 绘制播放列表项
    for (int i = 0; i < itemCount; i++) {
      // 计算项的展开进度
      final itemProgress = (expandProgress - i * 0.1).clamp(0.0, 1.0);

      // 计算项的位置和大小
      final itemY =
          i * (itemHeight + itemSpacing) +
          size.height * 0.1 * (1 - itemProgress);
      final currentWidth = itemWidth * itemProgress;
      final currentX = startX + (itemWidth - currentWidth) / 2;

      // 绘制背景
      paint.color = theme.colorScheme.surface;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(currentX, itemY, currentWidth, itemHeight),
          const Radius.circular(8.0),
        ),
        paint,
      );

      // 绘制边框
      paint
        ..color = theme.colorScheme.onSurface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(currentX, itemY, currentWidth, itemHeight),
          const Radius.circular(8.0),
        ),
        paint,
      );

      // 绘制音乐图标
      paint
        ..color = theme.colorScheme.primary
        ..style = PaintingStyle.fill;
      final iconSize = itemHeight * 0.6;
      final iconX = currentX + itemHeight * 0.5;
      final iconY = itemY + (itemHeight - iconSize) / 2;
      canvas.drawCircle(
        Offset(iconX, iconY + iconSize * 0.3),
        iconSize * 0.2,
        paint,
      );
      canvas.drawCircle(
        Offset(iconX, iconY + iconSize * 0.7),
        iconSize * 0.2,
        paint,
      );

      // 绘制文本占位符
      paint.color = theme.colorScheme.onSurface;
      final textY = itemY + itemHeight * 0.3;
      final textHeight = itemHeight * 0.2;
      canvas.drawRect(
        Rect.fromLTWH(
          iconX + iconSize * 0.8,
          textY,
          currentWidth * 0.5,
          textHeight,
        ),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          iconX + iconSize * 0.8,
          textY + textHeight * 1.5,
          currentWidth * 0.3,
          textHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlaylistExpandPainter oldDelegate) {
    return oldDelegate.expandProgress != expandProgress ||
        oldDelegate.theme != theme ||
        oldDelegate.itemCount != itemCount;
  }
}
