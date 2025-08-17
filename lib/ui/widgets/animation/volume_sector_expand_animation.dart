import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class VolumeSectorExpandAnimation extends ThemedAnimationBase {
  const VolumeSectorExpandAnimation({super.key});

  @override
  State<VolumeSectorExpandAnimation> createState() =>
      _VolumeSectorExpandAnimationState();
}

class _VolumeSectorExpandAnimationState
    extends ThemedAnimationStateBase<VolumeSectorExpandAnimation> {
  late Animation<double> _expandAnimation;
  late Animation<double> _retractAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 2));
    repeatAnimation();

    _expandAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _retractAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _VolumeSectorExpandPainter(
            _expandAnimation.value,
            _retractAnimation.value,
            theme,
          ),
        );
      },
    );
  }
}

class _VolumeSectorExpandPainter extends CustomPainter {
  final double expandProgress;
  final double retractProgress;
  final ThemeData theme;

  _VolumeSectorExpandPainter(this.expandProgress, this.retractProgress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // 音量值模拟（0-100%）
    final volume = (50.0 + 50.0 * sin(expandProgress * 2 * pi)).clamp(0.0, 100.0);

    // 扇形声波角度 = 音量 × 3.6°
    final sectorAngle = volume * 3.6 * pi / 180;

    // 实际绘制角度（考虑展开和收起）
    final currentAngle = sectorAngle * (expandProgress > retractProgress ? expandProgress : retractProgress);

    // 扇形内有3条平行线，随角度同步展开
    final lineCount = 3;
    for (int i = 0; i < lineCount; i++) {
      // 线条距离中心的距离
      final radius = 15.0 + i * 8.0;

      // 使用主题色并根据音量调整亮度
      final brightness = 0.3 + 0.7 * (volume / 100);
      paint.color = HSLColor.fromColor(theme.colorScheme.primary)
          .withLightness(brightness)
          .toColor();

      // 绘制扇形弧线
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -currentAngle / 2, // 起始角度
        currentAngle, // 扫描角度
        true, // 闭合
        paint,
      );
    }

    // 绘制中心点
    paint.color = theme.colorScheme.primary;
    canvas.drawCircle(center, 5, paint);
  }

  @override
  bool shouldRepaint(covariant _VolumeSectorExpandPainter oldDelegate) {
    return oldDelegate.expandProgress != expandProgress ||
           oldDelegate.retractProgress != retractProgress ||
           oldDelegate.theme != theme;
  }
}
