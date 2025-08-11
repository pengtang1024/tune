import 'package:flutter/material.dart';

/// 部分标题组件
/// 
/// 用于显示页面中各部分的标题，如"最近播放"等
class SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow overflow;
  final int? maxLines;

  const SectionTitle({
    super.key,
    required this.title,
    this.onSeeAll,
    this.style,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: style ??
              Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
          textAlign: textAlign,
          overflow: overflow,
          maxLines: maxLines,
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See all',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
      ],
    );
  }
}