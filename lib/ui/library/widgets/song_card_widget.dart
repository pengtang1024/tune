import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/library/widgets/song_card/album_cover_widget.dart';
import 'package:tune/ui/library/widgets/song_card/song_info_widget.dart';
import 'package:tune/ui/library/widgets/song_card/song_tags_widget.dart';

class SongCardWidget extends ConsumerWidget {
  final Song song;

  const SongCardWidget({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          // 点击歌曲卡片时的处理逻辑
          final notifier = ref.read(libraryStateNotifierProvider.notifier);
          notifier.playSong(song);
        },
        splashColor: Theme.of(context).primaryColor.withOpacity(0.3),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 专辑封面 - 添加了更优雅的边缘处理
              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: AlbumCoverWidget(),
              ),

              const SizedBox(width: 16),

              // 歌曲信息和标签 - 使用更灵活的布局方式
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 歌曲信息 - 添加了更清晰的视觉层次
                    SongInfoWidget(song: song),
                    
                    const SizedBox(height: 6),
                    
                    // 标签行 - 优化了高度和交互性
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 32),
                        child: SongTagsWidget(song: song),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}