import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/utils/lrc_parser.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class PlayerLyrics extends ConsumerStatefulWidget {
  const PlayerLyrics({super.key});

  @override
  ConsumerState<PlayerLyrics> createState() => _PlayerLyricsState();
}

class _PlayerLyricsState extends ConsumerState<PlayerLyrics> {
  LrcParser? _parser;
  int _currentIndex = -1;
  final ScrollController _scrollController = ScrollController();
  static const double _lineHeight = 36.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parseLyrics();
  }

  void _parseLyrics() {
    final lyrics = ref.read(playerStateNotifierProvider).currentSong?.lyrics;
    if (lyrics != null && lyrics.trim().isNotEmpty) {
      _parser = LrcParser(lyrics);
      _currentIndex = -1;
    } else {
      _parser = null;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerStateNotifierProvider);

    if (_parser == null || _parser!.lines.isEmpty) {
      return ModernCard(
        padding: const EdgeInsets.all(AppDesignSystem.spacing16),
        child: Column(
          children: [
            Icon(Icons.lyrics_outlined, size: AppDesignSystem.iconSize32, color: AppDesignSystem.neutral400),
            const SizedBox(height: AppDesignSystem.spacing8),
            Text('暂无歌词', style: AppDesignSystem.textTheme.bodyMedium?.copyWith(color: AppDesignSystem.neutral400)),
          ],
        ),
      );
    }

    final newIndex = _parser!.findCurrentLineIndex(playerState.position);
    if (newIndex != _currentIndex && newIndex >= 0) {
      _currentIndex = newIndex;
      _scrollToCurrent();
    }

    final lines = _parser!.lines;

    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing8, vertical: AppDesignSystem.spacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lyrics_rounded, size: AppDesignSystem.iconSize24, color: AppDesignSystem.primary),
              const SizedBox(width: AppDesignSystem.spacing8),
              Text('歌词', style: AppDesignSystem.textTheme.titleSmall?.copyWith(fontWeight: AppDesignSystem.fontWeightSemiBold)),
            ],
          ),
          const SizedBox(height: AppDesignSystem.spacing8),
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(vertical: _lineHeight * 3),
                  itemCount: lines.length,
                  itemExtent: _lineHeight,
                  itemBuilder: (context, index) {
                    final isCurrent = index == _currentIndex;
                    return AnimatedDefaultTextStyle(
                      duration: AppDesignSystem.duration200,
                      style: TextStyle(
                        fontSize: isCurrent ? 16 : 13,
                        fontWeight: isCurrent ? AppDesignSystem.fontWeightBold : AppDesignSystem.fontWeightNormal,
                        color: isCurrent ? AppDesignSystem.primary : AppDesignSystem.neutral400,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                      child: Text(
                        lines[index].text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 0, left: 0, right: 0, height: _lineHeight * 3,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).brightness == Brightness.dark
                                ? AppDesignSystem.neutral900
                                : Colors.white,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0, height: _lineHeight * 3,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Theme.of(context).brightness == Brightness.dark
                                ? AppDesignSystem.neutral900
                                : Colors.white,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToCurrent() {
    if (_currentIndex < 0 || !_scrollController.hasClients) return;
    final offset = _currentIndex * _lineHeight - _lineHeight * 3 + _lineHeight / 2;
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: AppDesignSystem.duration300,
      curve: AppDesignSystem.curveEaseInOut,
    );
  }
}
