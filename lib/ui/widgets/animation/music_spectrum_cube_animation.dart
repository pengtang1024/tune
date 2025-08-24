import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 音乐频谱立方体动画组件
/// 显示3D频谱立方体效果
class MusicSpectrumCubeAnimation extends ThemedAnimationBase {
  final int cubeRows;
  final int cubeCols;
  final double size;

  const MusicSpectrumCubeAnimation({
    super.key,
    this.cubeRows = 6,
    this.cubeCols = 10,
    this.size = 200.0,
  });

  @override
  State<MusicSpectrumCubeAnimation> createState() =>
      _MusicSpectrumCubeAnimationState();
}

class _MusicSpectrumCubeAnimationState
    extends ThemedAnimationStateBase<MusicSpectrumCubeAnimation> {
  late Animation<double> _spectrumAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 3000));
    repeatAnimation();

    _spectrumAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(controller);
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _MusicSpectrumCubePainter(
            _spectrumAnimation.value,
            _rotationAnimation.value,
            theme,
            widget.cubeRows,
            widget.cubeCols,
          ),
        );
      },
    );
  }
}

class _MusicSpectrumCubePainter extends CustomPainter {
  final double spectrumProgress;
  final double rotation;
  final ThemeData theme;
  final int cubeRows;
  final int cubeCols;

  _MusicSpectrumCubePainter(
    this.spectrumProgress,
    this.rotation,
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

    // 保存画布状态
    canvas.save();
    // 移动画布中心到画布中心
    canvas.translate(size.width / 2, size.height / 2);
    // 应用旋转
    canvas.rotate(rotation);
    // 移回原点
    canvas.translate(-size.width / 2, -size.height / 2);

    // 绘制频谱立方体
    for (int row = 0; row < cubeRows; row++) {
      for (int col = 0; col < cubeCols; col++) {
        // 计算频谱高度因子
        final frequency = sin(spectrumProgress * 2 * pi + (row + col) * 0.4);
        final heightFactor = (frequency + 1) / 2; // 范围 0-1

        // 计算实际高度
        final actualHeight = cellHeight * 0.8 * heightFactor;

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
        topPath.lineTo(x + cellWidth * 1.1, y - cellHeight * 0.1);
        topPath.lineTo(x + cellWidth * 0.1, y - cellHeight * 0.1);
        topPath.close();
        canvas.drawPath(topPath, paint);

        // 绘制立方体左侧面
        final leftPath = Path();
        leftPath.moveTo(x, y);
        leftPath.lineTo(x + cellWidth * 0.1, y - cellHeight * 0.1);
        leftPath.lineTo(
          x + cellWidth * 0.1,
          y + actualHeight - cellHeight * 0.1,
        );
        leftPath.lineTo(x, y + actualHeight);
        leftPath.close();
        // 左侧面使用稍暗的颜色
        paint.color = paint.color.withValues(alpha: 0.6 * heightFactor);
        canvas.drawPath(leftPath, paint);

        // 绘制立方体右侧面
        final rightPath = Path();
        rightPath.moveTo(x + cellWidth, y);
        rightPath.lineTo(x + cellWidth * 1.1, y - cellHeight * 0.1);
        rightPath.lineTo(
          x + cellWidth * 1.1,
          y + actualHeight - cellHeight * 0.1,
        );
        rightPath.lineTo(x + cellWidth, y + actualHeight);
        rightPath.close();
        // 右侧面使用稍亮的颜色
        paint.color = paint.color.withValues(alpha: 0.9 * heightFactor);
        canvas.drawPath(rightPath, paint);
      }
    }

    // 恢复画布状态
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MusicSpectrumCubePainter oldDelegate) {
    return oldDelegate.spectrumProgress != spectrumProgress ||
        oldDelegate.rotation != rotation ||
        oldDelegate.theme != theme ||
        oldDelegate.cubeRows != cubeRows ||
        oldDelegate.cubeCols != cubeCols;
  }
}
