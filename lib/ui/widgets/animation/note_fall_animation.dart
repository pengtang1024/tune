import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 音符飘落动画组件
/// 显示音符从上到下飘落的效果
class NoteFallAnimation extends ThemedAnimationBase {
  final int noteCount;
  final double size;

  const NoteFallAnimation({super.key, this.noteCount = 10, this.size = 200.0});

  @override
  State<NoteFallAnimation> createState() => _NoteFallAnimationState();
}

class _NoteFallAnimationState
    extends ThemedAnimationStateBase<NoteFallAnimation> {
  late Animation<double> _fallAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 3000));
    repeatAnimation();

    _fallAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.linear));
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _fallAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _NoteFallPainter(
            _fallAnimation.value,
            theme,
            widget.noteCount,
          ),
        );
      },
    );
  }
}

class _NoteFallPainter extends CustomPainter {
  final double fallProgress;
  final ThemeData theme;
  final int noteCount;

  _NoteFallPainter(this.fallProgress, this.theme, this.noteCount);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制飘落的音符
    for (int i = 0; i < noteCount; i++) {
      // 计算音符初始位置（随机水平位置）
      final random = math.Random(i);
      final x = random.nextDouble() * size.width;

      // 计算音符垂直位置（基于进度和随机偏移）
      final y = (fallProgress * 1.5 - random.nextDouble() * 0.5) * size.height;

      // 计算音符旋转角度
      final rotation = fallProgress * 2 * math.pi + i;

      // 设置颜色
      Color baseColor;
      if (i % 3 == 0) {
        baseColor = theme.colorScheme.primary;
      } else if (i % 3 == 1) {
        baseColor = theme.colorScheme.secondary;
      } else {
        baseColor = theme.colorScheme.tertiary;
      }
      // ignore: deprecated_member_use
      paint.color = baseColor.withValues(alpha: 0.8);

      // 保存画布状态
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      // 绘制音符
      _drawNote(canvas, Offset.zero, 12.0, paint);

      // 恢复画布状态
      canvas.restore();
    }
  }

  /// 绘制音符
  void _drawNote(Canvas canvas, Offset center, double size, Paint paint) {
    // 音符椭圆部分
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size, height: size * 0.6),
      paint,
    );

    // 音符线部分
    final linePaint = Paint()
      ..color = paint.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      center + Offset(size * 0.4, -size * 0.2),
      center + Offset(size * 0.4, -size * 1.2),
      linePaint,
    );

    canvas.drawLine(
      center + Offset(size * 0.6, -size * 0.2),
      center + Offset(size * 0.6, -size * 1.0),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _NoteFallPainter oldDelegate) {
    return oldDelegate.fallProgress != fallProgress ||
        oldDelegate.theme != theme ||
        oldDelegate.noteCount != noteCount;
  }
}
