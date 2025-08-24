import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 音符旋转动画组件
/// 显示旋转音符效果
class NoteRotateAnimation extends ThemedAnimationBase {
  final int noteCount;
  final double size;

  const NoteRotateAnimation({super.key, this.noteCount = 8, this.size = 200.0});

  @override
  State<NoteRotateAnimation> createState() => _NoteRotateAnimationState();
}

class _NoteRotateAnimationState
    extends ThemedAnimationStateBase<NoteRotateAnimation> {
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 4000));
    repeatAnimation();

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.linear));
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _rotateAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _NoteRotatePainter(
            _rotateAnimation.value,
            theme,
            widget.noteCount,
          ),
        );
      },
    );
  }
}

class _NoteRotatePainter extends CustomPainter {
  final double rotation;
  final ThemeData theme;
  final int noteCount;

  _NoteRotatePainter(this.rotation, this.theme, this.noteCount);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.4;

    // 绘制旋转音符
    for (int i = 0; i < noteCount; i++) {
      // 计算音符角度
      final angle = rotation + (2 * pi * i / noteCount);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

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
  bool shouldRepaint(covariant _NoteRotatePainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.theme != theme ||
        oldDelegate.noteCount != noteCount;
  }
}
