import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 音频波形失真动画组件
/// 显示波形失真效果
class AudioWaveDistortionAnimation extends ThemedAnimationBase {
  final int waveSegmentCount;
  final double size;

  const AudioWaveDistortionAnimation({
    super.key,
    this.waveSegmentCount = 50,
    this.size = 200.0,
  });

  @override
  State<AudioWaveDistortionAnimation> createState() =>
      _AudioWaveDistortionAnimationState();
}

class _AudioWaveDistortionAnimationState
    extends ThemedAnimationStateBase<AudioWaveDistortionAnimation> {
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 2000));
    repeatAnimation();

    _waveAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _AudioWaveDistortionPainter(
            _waveAnimation.value,
            theme,
            widget.waveSegmentCount,
          ),
        );
      },
    );
  }
}

class _AudioWaveDistortionPainter extends CustomPainter {
  final double waveProgress;
  final ThemeData theme;
  final int waveSegmentCount;

  _AudioWaveDistortionPainter(
    this.waveProgress,
    this.theme,
    this.waveSegmentCount,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();

    // 计算波形参数
    final amplitude = size.height * 0.3;
    final centerY = size.height / 2;
    final segmentWidth = size.width / (waveSegmentCount - 1);

    // 绘制失真波形
    for (int i = 0; i < waveSegmentCount; i++) {
      // 计算x坐标
      final x = i * segmentWidth;

      // 计算基础波形值
      final baseWave = sin(
        2 * pi * i / waveSegmentCount + waveProgress * 4 * pi,
      );

      // 计算失真因子
      final distortion = sin(waveProgress * 6 * pi + i * 0.5) * 0.5;

      // 计算y坐标
      final y = centerY + amplitude * baseWave * (1 + distortion);

      // 移动到起始点或绘制线段
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // 绘制反向波形
    paint.color = theme.colorScheme.secondary;
    final reversePath = Path();

    for (int i = 0; i < waveSegmentCount; i++) {
      final x = i * segmentWidth;
      final baseWave = sin(
        2 * pi * i / waveSegmentCount + waveProgress * 4 * pi,
      );
      final distortion = sin(waveProgress * 6 * pi + i * 0.5 + pi) * 0.5;
      final y = centerY - amplitude * baseWave * (1 + distortion);

      if (i == 0) {
        reversePath.moveTo(x, y);
      } else {
        reversePath.lineTo(x, y);
      }
    }

    canvas.drawPath(reversePath, paint);
  }

  @override
  bool shouldRepaint(covariant _AudioWaveDistortionPainter oldDelegate) {
    return oldDelegate.waveProgress != waveProgress ||
        oldDelegate.theme != theme ||
        oldDelegate.waveSegmentCount != waveSegmentCount;
  }
}
