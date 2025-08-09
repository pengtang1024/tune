import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/core/routes/app_router.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/presentation/bloc/player/player_bloc.dart';
import 'package:tune/presentation/bloc/player/player_event.dart';
import 'package:tune/presentation/widgets/song_list.dart';

@RoutePage()
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Song> _songs = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  /// 搜索歌曲
  ///
  /// 根据输入的查询字符串搜索歌曲。
  /// 如果查询为空，则清空结果列表。
  Future<void> _searchSongs(String query) async {
    if (query.isEmpty) {
      setState(() {
        _songs = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 这里应该调用实际的搜索功能
      // 暂时使用简单的过滤方式
      final allSongs = await context.read<PlayerBloc>().getAllSongs();
      final filteredSongs = allSongs.where((song) {
        return song.title.toLowerCase().contains(query.toLowerCase()) ||
            song.artist.toLowerCase().contains(query.toLowerCase()) ||
            song.album.toLowerCase().contains(query.toLowerCase());
      }).toList();

      if (mounted) {
        setState(() {
          _songs = filteredSongs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .search_page_no_results)),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _searchSongs(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: localizations.search_page_hint,
            border: InputBorder.none,
            hintStyle: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withOpacity(0.7)),
          ),
          style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyLarge?.color),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // context.router.pop();
            _searchController.clear();
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SongList(
              songs: _songs,
              onSongSelected: (song) {
                context.read<PlayerBloc>().add(PlaySongEvent(song.id));
                context.pushRoute(const PlayerRoute());
              },
            ),
    );
  }
}
