import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class Spectrum3DSphereAnimation extends ThemedAnimationBase {
  const Spectrum3DSphereAnimation({super.key});

  @override
  State<Spectrum3DSphereAnimation> createState() =>
      _Spectrum3DSphereAnimationState();
}

class _Spectrum3DSphereAnimationState
    extends ThemedAnimationStateBase<Spectrum3DSphereAnimation> {
  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 4));
    repeatAnimation();
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _Spectrum3DSpherePainter(controller.value, theme),
        );
      },
    );
  }
}

class _Spectrum3DSpherePainter extends CustomPainter {
  final double rotation;
  final ThemeData theme;

  _Spectrum3DSpherePainter(this.rotation, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // 球体半径
    final radius = 25.0;

    // 模拟球体表面的顶点（性能适配：这里使用100个顶点）
    final vertexCount = 100;

    for (int i = 0; i < vertexCount; i++) {
      // 使用经纬度方式分布顶点
      final lat = pi * (i / vertexCount) - pi / 2;
      final lon = 2 * pi * (i / vertexCount) + rotation;

      // 根据音频频谱计算凸起凹陷（简化处理）
      final frequencyFactor = (sin(lat) + 1) / 2; // 低频影响下半部，高频影响上半部
      final volume = 0.8 + 0.2 * sin(rotation + i * 0.1); // 音量变化
      final displacement = 5 * frequencyFactor * volume;

      // 计算顶点位置（带凸起效果）
      final x = center.dx + (radius + displacement) * cos(lat) * cos(lon);
      final y = center.dy + (radius + displacement) * sin(lat);

      // 模拟基础光照（高光位置固定）
      final lightDir = const Offset(1, -1); // 光照方向
      final dx = x - center.dx;
      final dy = y - center.dy;
      final length = sqrt(dx * dx + dy * dy);
      final normal = length > 0 ? Offset(dx / length, dy / length) : Offset.zero; // 手动归一化
      final lightIntensity = (lightDir.dx * normal.dx + lightDir.dy * normal.dy + 1) / 2;

      // 使用主题色并根据光照和频率调整亮度
      final hue = HSLColor.fromColor(theme.colorScheme.primary).hue;
      paint.color = HSLColor.fromAHSL(
        1.0,
        hue,
        0.5,
        0.3 + 0.5 * lightIntensity,
      ).toColor();

      // 绘制顶点（小圆点）
      canvas.drawCircle(Offset(x, y), 1.5, paint);
    }

    // 绘制球体轮廓
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _Spectrum3DSpherePainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.theme != theme;
  }
}
