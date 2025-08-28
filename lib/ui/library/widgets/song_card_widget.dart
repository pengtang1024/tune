import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/library/widgets/song_card/album_cover_widget.dart';
import 'package:tune/ui/library/widgets/song_card/song_info_widget.dart';
import 'package:tune/ui/library/widgets/song_card/song_tags_widget.dart';

class SongCardWidget extends ConsumerWidget {
  final Song song;
  final int? index; // 添加序号参数

  const SongCardWidget({super.key, required this.song, this.index});

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
          
          // 跳转到播放器页面
          context.push('/player');
        },
        splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // 调整内边距
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 专辑封面
              const AlbumCoverWidget(),

              const SizedBox(width: 12), // 调整间距

              // 歌曲信息和标签
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 歌曲信息
                    SongInfoWidget(song: song, index: index), // 传递序号参数
                    
                    const SizedBox(height: 6), // 调整间距

                    // 标签行
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 36), // 调整最大高度
                      child: SongTagsWidget(song: song),
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