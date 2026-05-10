import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/library/widgets/song_card/album_cover_widget.dart';
import 'package:tune/ui/library/widgets/song_card/song_info_widget.dart';
import 'package:tune/ui/library/widgets/song_card/song_tags_widget.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class SongCardWidget extends ConsumerWidget {
  final Song song;
  final int? index;
  const SongCardWidget({super.key, required this.song, this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing12, vertical: AppDesignSystem.spacing10),
      onTap: () {
        final notifier = ref.read(libraryStateNotifierProvider.notifier);
        notifier.playSong(song);
        context.push('/player');
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const AlbumCoverWidget(),
          const SizedBox(width: AppDesignSystem.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SongInfoWidget(song: song, index: index),
                const SizedBox(height: AppDesignSystem.spacing6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 36),
                  child: SongTagsWidget(song: song),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
