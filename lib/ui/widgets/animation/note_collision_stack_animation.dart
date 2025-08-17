import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class NoteCollisionStackAnimation extends ThemedAnimationBase {
  const NoteCollisionStackAnimation({super.key});

  @override
  State<NoteCollisionStackAnimation> createState() =>
      _NoteCollisionStackAnimationState();
}

class _NoteCollisionStackAnimationState
    extends ThemedAnimationStateBase<NoteCollisionStackAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 3));
    repeatAnimation();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.linear),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _NoteCollisionStackPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _NoteCollisionStackPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _NoteCollisionStackPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height);

    // 绘制地面
    paint.color = theme.colorScheme.onSurface.withValues(alpha: 0.3);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 10, size.width, 10),
      paint,
    );

    // 绘制3个下落和堆叠的音符
    final noteCount = 3;
    for (int i = 0; i < noteCount; i++) {
      // 音符下落进度
      final fallProgress = ((progress * noteCount + i) % noteCount) / noteCount;

      // 音符水平位置随机
      final random = Random(i);
      final x = 20 + random.nextDouble() * 40;

      // 音符垂直位置（下落+堆叠）
      double y;
      if (fallProgress < 0.7) {
        // 下落阶段
        y = center.dy - 60 * fallProgress;
      } else {
        // 堆叠阶段（在地面上）
        y = center.dy - 20 - i * 15;
      }

      // 碰撞时带轻微形变
      double scaleX = 1.0;
      double scaleY = 1.0;
      if (fallProgress > 0.65 && fallProgress < 0.75) {
        // 碰撞瞬间宽度增加10%
        scaleX = 1.1;
      }

      // 弹跳效果
      double bounce = 0;
      if (fallProgress > 0.7 && fallProgress < 0.8) {
        bounce = 5 * sin((fallProgress - 0.7) * 10 * pi);
      }

      // 使用主题色
      final colors = [
        theme.colorScheme.primary,
        theme.colorScheme.secondary,
        theme.colorScheme.tertiary,
      ];
      paint.color = colors[i % colors.length];

      canvas.save();
      canvas.translate(x, y + bounce);
      canvas.scale(scaleX, scaleY);

      // 绘制音符
      canvas.drawCircle(Offset(0, 0), 8, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _NoteCollisionStackPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}
