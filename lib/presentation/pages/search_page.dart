import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/core/utils/localization_delegate.dart';
import 'package:tune/domain/usecases/search_songs.dart';
import 'package:tune/presentation/widgets/song_list.dart';
import 'package:tune/core/di/dependency_injection.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/presentation/bloc/player/player_bloc.dart';
import 'package:tune/presentation/bloc/player/player_event.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late SearchSongs _searchSongs;
  List<Song> _songs = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchSongs = DependencyInjection.get<SearchSongs>();
  }

  Future<void> _performSearch(String query) async {
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
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.searchTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search songs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
              onChanged: _performSearch,
            ),
          ),
          _isLoading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : Expanded(
                  child: SongList(
                    songs: _songs,
                    onSongTap: (song) {
                      context.read<PlayerBloc>().add(PlaySongEvent(song.id));
                    },
                  ),
                ),
        ],
      ),
    );
  }
}