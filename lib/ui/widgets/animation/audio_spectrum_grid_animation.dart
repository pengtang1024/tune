import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 音频频谱网格动画组件
/// 显示网格状频谱效果
class AudioSpectrumGridAnimation extends ThemedAnimationBase {
  final int gridRows;
  final int gridCols;
  final double size;

  const AudioSpectrumGridAnimation({
    super.key,
    this.gridRows = 8,
    this.gridCols = 12,
    this.size = 200.0,
  });

  @override
  State<AudioSpectrumGridAnimation> createState() =>
      _AudioSpectrumGridAnimationState();
}

class _AudioSpectrumGridAnimationState
    extends ThemedAnimationStateBase<AudioSpectrumGridAnimation> {
  late Animation<double> _spectrumAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 2000));
    repeatAnimation();

    _spectrumAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _spectrumAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _AudioSpectrumGridPainter(
            _spectrumAnimation.value,
            theme,
            widget.gridRows,
            widget.gridCols,
          ),
        );
      },
    );
  }
}

class _AudioSpectrumGridPainter extends CustomPainter {
  final double spectrumProgress;
  final ThemeData theme;
  final int gridRows;
  final int gridCols;

  _AudioSpectrumGridPainter(
    this.spectrumProgress,
    this.theme,
    this.gridRows,
    this.gridCols,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 计算网格单元大小
    final cellWidth = size.width / gridCols;
    final cellHeight = size.height / gridRows;

    // 绘制频谱网格
    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        // 计算频谱高度因子
        final frequency = sin(spectrumProgress * 2 * pi + (row + col) * 0.5);
        final heightFactor = (frequency + 1) / 2; // 范围 0-1

        // 计算实际高度
        final actualHeight = cellHeight * heightFactor;

        // 计算位置
        final x = col * cellWidth;
        final y = row * cellHeight + (cellHeight - actualHeight);

        // 设置颜色，使用主题色系
        // 根据行列位置选择不同的主题颜色
        if (row < gridRows ~/ 3) {
          paint.color = theme.colorScheme.primary;
        } else if (row < 2 * gridRows ~/ 3) {
          paint.color = theme.colorScheme.secondary;
        } else {
          paint.color = theme.colorScheme.tertiary;
        }

        // 添加透明度变化
        paint.color = paint.color.withValues(alpha: 0.8 * heightFactor);

        // 绘制频谱条
        canvas.drawRect(
          Rect.fromLTWH(x + 1, y, cellWidth - 2, actualHeight),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AudioSpectrumGridPainter oldDelegate) {
    return oldDelegate.spectrumProgress != spectrumProgress ||
        oldDelegate.theme != theme ||
        oldDelegate.gridRows != gridRows ||
        oldDelegate.gridCols != gridCols;
  }
}
