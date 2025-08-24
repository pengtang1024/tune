import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 粒子轨道动画组件
/// 显示轨道粒子效果
class ParticleOrbitAnimation extends ThemedAnimationBase {
  final int particleCount;
  final double size;

  const ParticleOrbitAnimation({
    super.key,
    this.particleCount = 20,
    this.size = 200.0,
  });

  @override
  State<ParticleOrbitAnimation> createState() => _ParticleOrbitAnimationState();
}

class _ParticleOrbitAnimationState
    extends ThemedAnimationStateBase<ParticleOrbitAnimation> {
  late Animation<double> _orbitAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 3000));
    repeatAnimation();

    _orbitAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.linear));
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _orbitAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ParticleOrbitPainter(
            _orbitAnimation.value,
            theme,
            widget.particleCount,
          ),
        );
      },
    );
  }
}

class _ParticleOrbitPainter extends CustomPainter {
  final double rotation;
  final ThemeData theme;
  final int particleCount;

  _ParticleOrbitPainter(this.rotation, this.theme, this.particleCount);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = min(size.width, size.height) * 0.4;
    final innerRadius = outerRadius * 0.3;

    // 绘制轨道粒子
    for (int i = 0; i < particleCount; i++) {
      // 计算粒子角度
      final angle = rotation + (2 * pi * i / particleCount);

      // 外层粒子
      final outerX = center.dx + outerRadius * cos(angle);
      final outerY = center.dy + outerRadius * sin(angle);

      // 内层粒子
      final innerAngle = rotation * 1.5 + (2 * pi * i / particleCount);
      final innerX = center.dx + innerRadius * cos(innerAngle);
      final innerY = center.dy + innerRadius * sin(innerAngle);

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

      // 绘制外层粒子
      canvas.drawCircle(Offset(outerX, outerY), 6.0, paint);

      // 绘制内层粒子
      canvas.drawCircle(Offset(innerX, innerY), 4.0, paint);
    }

    // 绘制中心点
    paint.color = theme.colorScheme.primary;
    canvas.drawCircle(center, 8.0, paint);
  }

  @override
  bool shouldRepaint(covariant _ParticleOrbitPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.theme != theme ||
        oldDelegate.particleCount != particleCount;
  }
}
