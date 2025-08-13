import 'package:flutter/material.dart';

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final bool isDesktop;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    // 根据是否是桌面端使用不同的设计
    final iconSize = isDesktop ? 18.0 : 22.0; // 统一并减小图标尺寸
    final textSize = isDesktop 
        ? Theme.of(context).textTheme.labelLarge // 使用更小的字体
        : Theme.of(context).textTheme.titleMedium;
    final padding = isDesktop ? 5.0 : 12.0; // 减小桌面端内边距
    final borderRadius = isDesktop ? 6.0 : 12.0; // 统一圆角
    final cardHeight = isDesktop ? 40.0 : 60.0; // 固定卡片高度

    return SizedBox(
      height: cardHeight,
      child: Card(
        elevation: isDesktop ? 1 : 4, // 统一桌面端阴影
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(borderRadius),
                    bottomLeft: Radius.circular(borderRadius),
                  ),
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Text(
                  title,
                  style: textSize?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
