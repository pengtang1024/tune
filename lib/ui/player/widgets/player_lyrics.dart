import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class PlayerLyrics extends ConsumerStatefulWidget {
  const PlayerLyrics({super.key});

  @override
  ConsumerState<PlayerLyrics> createState() => _PlayerLyricsState();
}

class _PlayerLyricsState extends ConsumerState<PlayerLyrics> {
  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final lyrics = playerState.currentSong?.lyrics;

    if (lyrics == null || lyrics.isEmpty) {
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

    final lines = lyrics.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return ModernCard(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
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
          const SizedBox(height: AppDesignSystem.spacing12),
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: lines.map((line) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacing6),
                    child: Text(
                      line,
                      style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
