import 'package:flutter/material.dart';
import 'themed_animation_base.dart';

class VolumeRippleBarsAnimation extends ThemedAnimationBase {
  const VolumeRippleBarsAnimation({super.key});

  @override
  State<VolumeRippleBarsAnimation> createState() =>
      _VolumeRippleBarsAnimationState();
}

class _VolumeRippleBarsAnimationState
    extends ThemedAnimationStateBase<VolumeRippleBarsAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 1500));
    repeatAnimation();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return child!;
      },
      child: CustomPaint(
        size: const Size(80, 60),
        painter: _VolumeRippleBarsPainter(_animation.value, theme),
      ),
    );
  }
}

class _VolumeRippleBarsPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _VolumeRippleBarsPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final barCount = 20;
    final barWidth = size.width / barCount;

    // 绘制音量涟漪柱状图
    for (int i = 0; i < barCount; i++) {
      // 柱状条高度基于音量模拟值
      final barHeightFactor = (0.5 + 0.5 * 
        (((progress * barCount + i) % barCount) / barCount));
      
      // 柱状条颜色（使用主题色）
      // 创建渐变效果，从主题主色到次色
      HSLColor primaryHsl = HSLColor.fromColor(theme.colorScheme.primary);
      HSLColor secondaryHsl = HSLColor.fromColor(theme.colorScheme.secondary);
      
      // 根据位置插值颜色
      final lightness = primaryHsl.lightness + 
          (secondaryHsl.lightness - primaryHsl.lightness) * (i / barCount);
      final saturation = primaryHsl.saturation + 
          (secondaryHsl.saturation - primaryHsl.saturation) * (i / barCount);
      
      paint.color = HSLColor.fromAHSL(
        1.0,
        primaryHsl.hue,
        saturation,
        lightness * barHeightFactor,
      ).toColor();
      
      // 绘制柱状条
      canvas.drawRect(
        Rect.fromLTWH(
          i * barWidth,
          size.height - size.height * barHeightFactor,
          barWidth - 1,
          size.height * barHeightFactor,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}