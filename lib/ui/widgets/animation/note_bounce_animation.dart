import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 音符弹跳动画组件
/// 显示弹跳音符效果
class NoteBounceAnimation extends ThemedAnimationBase {
  final int noteCount;
  final double size;

  const NoteBounceAnimation({super.key, this.noteCount = 5, this.size = 200.0});

  @override
  State<NoteBounceAnimation> createState() => _NoteBounceAnimationState();
}

class _NoteBounceAnimationState
    extends ThemedAnimationStateBase<NoteBounceAnimation> {
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 2000));
    repeatAnimation();

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.bounceOut));
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _NoteBouncePainter(
            _bounceAnimation.value,
            theme,
            widget.noteCount,
          ),
        );
      },
    );
  }
}

class _NoteBouncePainter extends CustomPainter {
  final double bounceProgress;
  final ThemeData theme;
  final int noteCount;

  _NoteBouncePainter(this.bounceProgress, this.theme, this.noteCount);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制弹跳音符
    for (int i = 0; i < noteCount; i++) {
      // 计算音符的弹跳进度
      final noteProgress = (bounceProgress * noteCount - i) / noteCount;
      final clampedProgress = noteProgress.clamp(0.0, 1.0);

      // 计算音符位置
      final x = size.width * (i + 1) / (noteCount + 1);
      final y =
          size.height -
          size.height * 0.3 * sin(clampedProgress * pi) -
          size.height * 0.1;

      // 设置颜色，使用主题色系
      // 根据索引选择不同的主题颜色
      if (i % 3 == 0) {
        paint.color = theme.colorScheme.primary;
      } else if (i % 3 == 1) {
        paint.color = theme.colorScheme.secondary;
      } else {
        paint.color = theme.colorScheme.tertiary;
      }

      // 添加透明度变化
      paint.color = paint.color.withValues(alpha: 0.8);

      // 绘制音符（简化为圆形）
      canvas.drawCircle(Offset(x, y), 10.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NoteBouncePainter oldDelegate) {
    return oldDelegate.bounceProgress != bounceProgress ||
        oldDelegate.theme != theme ||
        oldDelegate.noteCount != noteCount;
  }
}
