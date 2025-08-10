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

/// 主标题组件
class HeadlineTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow overflow;
  final int? maxLines;

  const HeadlineTitle({
    super.key,
    required this.title,
    this.style,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: style ?? Theme.of(context).textTheme.headlineMedium,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

/// 歌曲标题组件
class SongTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow overflow;
  final int? maxLines;

  const SongTitle({
    super.key,
    required this.title,
    this.style,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: style ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

/// 歌曲艺术家组件
class SongArtist extends StatelessWidget {
  final String artist;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow overflow;
  final int? maxLines;

  const SongArtist({
    super.key,
    required this.artist,
    this.style,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      artist,
      style: style ?? Theme.of(context).textTheme.bodySmall,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}