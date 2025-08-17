import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 音符粒子动画组件
/// 显示漂浮的音符粒子效果
class NoteParticleAnimation extends ThemedAnimationBase {
  final int particleCount;
  final double size;

  const NoteParticleAnimation({
    super.key,
    this.particleCount = 15,
    this.size = 200.0,
  });

  @override
  State<NoteParticleAnimation> createState() => _NoteParticleAnimationState();
}

class _Particle {
  final double startX;
  final double startY;
  final double speedX;
  final double speedY;
  final double size;
  final double rotationSpeed;
  double rotation;

  _Particle({
    required this.startX,
    required this.startY,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.rotationSpeed,
    required this.rotation,
  });
}

class _NoteParticleAnimationState
    extends ThemedAnimationStateBase<NoteParticleAnimation> {
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 5));
    repeatAnimation();

    // 初始化粒子系统
    _particles = List.generate(widget.particleCount, (index) {
      final random = Random(index);
      return _Particle(
        startX: random.nextDouble() * widget.size,
        startY: random.nextDouble() * widget.size,
        speedX: (random.nextDouble() - 0.5) * 2,
        speedY: (random.nextDouble() - 0.5) * 2 - 1, // 主要向上移动
        size: 10 + random.nextDouble() * 20,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.2,
        rotation: random.nextDouble() * 2 * pi,
      );
    });
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _NoteParticlePainter(_particles, controller.value, theme),
        );
      },
    );
  }
}

class _NoteParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final ThemeData theme;

  _NoteParticlePainter(this.particles, this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      // 计算粒子位置
      final x = particle.startX + particle.speedX * progress * size.width;
      final y = particle.startY + particle.speedY * progress * size.height;

      // 循环处理边界
      final wrappedX = x % (size.width + particle.size) - particle.size;
      final wrappedY = y % (size.height + particle.size) - particle.size;

      // 更新旋转角度
      final rotation = particle.rotation + particle.rotationSpeed * progress * 100;

      // 设置颜色和透明度
      final opacity = 0.3 + 0.7 * (1 - (wrappedY / size.height).abs());
      paint.color = theme.colorScheme.primary.withValues(alpha: opacity);

      // 保存画布状态
      canvas.save();
      canvas.translate(wrappedX, wrappedY);
      canvas.rotate(rotation);

      // 绘制音符图标
      final path = Path();
      final noteSize = particle.size / 2;

      // 音符椭圆部分
      path.addOval(Rect.fromLTWH(-noteSize * 0.8, -noteSize * 0.5, noteSize * 1.6, noteSize));

      // 音符线部分
      path.moveTo(noteSize * 0.8, -noteSize * 0.3);
      path.lineTo(noteSize * 0.8, -noteSize * 1.5);
      path.moveTo(noteSize * 1.0, -noteSize * 0.3);
      path.lineTo(noteSize * 1.0, -noteSize * 1.3);

      canvas.drawPath(path, paint);

      // 恢复画布状态
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _NoteParticlePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}
