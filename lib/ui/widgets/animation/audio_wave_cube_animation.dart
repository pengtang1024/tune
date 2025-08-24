import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 音频波形立方体动画组件
/// 显示3D波形立方体效果
class AudioWaveCubeAnimation extends ThemedAnimationBase {
  final int cubeRows;
  final int cubeCols;
  final double size;

  const AudioWaveCubeAnimation({
    super.key,
    this.cubeRows = 8,
    this.cubeCols = 12,
    this.size = 200.0,
  });

  @override
  State<AudioWaveCubeAnimation> createState() => _AudioWaveCubeAnimationState();
}

class _AudioWaveCubeAnimationState
    extends ThemedAnimationStateBase<AudioWaveCubeAnimation> {
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
          painter: _AudioWaveCubePainter(
            _waveAnimation.value,
            theme,
            widget.cubeRows,
            widget.cubeCols,
          ),
        );
      },
    );
  }
}

class _AudioWaveCubePainter extends CustomPainter {
  final double waveProgress;
  final ThemeData theme;
  final int cubeRows;
  final int cubeCols;

  _AudioWaveCubePainter(
    this.waveProgress,
    this.theme,
    this.cubeRows,
    this.cubeCols,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 计算立方体单元大小
    final cellWidth = size.width / cubeCols;
    final cellHeight = size.height / cubeRows;

    // 绘制波形立方体
    for (int row = 0; row < cubeRows; row++) {
      for (int col = 0; col < cubeCols; col++) {
        // 计算波形高度因子
        final frequency = sin(waveProgress * 2 * pi + (row + col) * 0.3);
        final heightFactor = (frequency + 1) / 2; // 范围 0-1

        // 计算实际高度
        final actualHeight = cellHeight * heightFactor;

        // 计算位置
        final x = col * cellWidth;
        final y = row * cellHeight + (cellHeight - actualHeight);

        // 设置颜色，使用主题色系
        // 根据行列位置选择不同的主题颜色
        if (row < cubeRows ~/ 3) {
          paint.color = theme.colorScheme.primary;
        } else if (row < 2 * cubeRows ~/ 3) {
          paint.color = theme.colorScheme.secondary;
        } else {
          paint.color = theme.colorScheme.tertiary;
        }

        // 添加透明度变化
        paint.color = paint.color.withValues(alpha: 0.8 * heightFactor);

        // 绘制立方体顶部
        final topPath = Path();
        topPath.moveTo(x, y);
        topPath.lineTo(x + cellWidth, y);
        topPath.lineTo(x + cellWidth * 1.2, y - cellHeight * 0.2);
        topPath.lineTo(x + cellWidth * 0.2, y - cellHeight * 0.2);
        topPath.close();
        canvas.drawPath(topPath, paint);

        // 绘制立方体左侧面
        final leftPath = Path();
        leftPath.moveTo(x, y);
        leftPath.lineTo(x + cellWidth * 0.2, y - cellHeight * 0.2);
        leftPath.lineTo(
          x + cellWidth * 0.2,
          y + actualHeight - cellHeight * 0.2,
        );
        leftPath.lineTo(x, y + actualHeight);
        leftPath.close();
        // 左侧面使用稍暗的颜色
        paint.color = paint.color.withValues(alpha: 0.6 * heightFactor);
        canvas.drawPath(leftPath, paint);

        // 绘制立方体右侧面
        final rightPath = Path();
        rightPath.moveTo(x + cellWidth, y);
        rightPath.lineTo(x + cellWidth * 1.2, y - cellHeight * 0.2);
        rightPath.lineTo(
          x + cellWidth * 1.2,
          y + actualHeight - cellHeight * 0.2,
        );
        rightPath.lineTo(x + cellWidth, y + actualHeight);
        rightPath.close();
        // 右侧面使用稍亮的颜色
        paint.color = paint.color.withValues(alpha: 0.9 * heightFactor);
        canvas.drawPath(rightPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AudioWaveCubePainter oldDelegate) {
    return oldDelegate.waveProgress != waveProgress ||
        oldDelegate.theme != theme ||
        oldDelegate.cubeRows != cubeRows ||
        oldDelegate.cubeCols != cubeCols;
  }
}
