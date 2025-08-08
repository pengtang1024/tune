import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/core/routes/app_router.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/domain/usecases/search_songs.dart';
import 'package:tune/presentation/widgets/song_list.dart';
import 'package:tune/core/di/dependency_injection.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/presentation/bloc/player/player_bloc.dart';
import 'package:tune/presentation/bloc/player/player_event.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late SearchSongs _searchSongs;
  List<Song> _songs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchSongs = DependencyInjection.get<SearchSongs>();
  }

  Future<void> _searchSongsByQuery(String query) async {
    if (query.isEmpty) {
      setState(() {
        _songs = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final songs = await _searchSongs(query);
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to search songs: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.search_title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: localizations.search_hint_text, // 修复本地化字符串引用
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchSongsByQuery,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SongList(
              songs: _songs,
              onSongTap: (song) {
                context.read<PlayerBloc>().add(PlaySongEvent(song.id));
                context.pushRoute(PlayerRoute());
              },
            ),
    );
  }
}
