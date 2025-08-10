import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/domain/usecases/search_songs.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/presentation/bloc/player/player_bloc.dart';
import 'package:tune/presentation/bloc/player/player_event.dart';
import 'package:tune/presentation/widgets/song_list.dart';
import 'package:tune/core/di/dependency_injection.dart';
import 'package:auto_route/auto_route.dart';
import 'package:tune/core/routes/app_router.dart';

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
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: localizations.search_page_hint,
            border: InputBorder.none,
            hintStyle: _SearchHintStyle(context: context),
          ),
          style: _SearchTextStyle(context: context),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _searchController.clear();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? Center(
                  child: Text(
                    _searchController.text.isEmpty
                        ? localizations.search_page_empty
                        : localizations.search_page_no_results,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : SongList(
                  songs: _songs,
                  onSongSelected: (song) {
                    context.read<PlayerBloc>().add(PlaySongEvent(song.id));
                    context.pushRoute(const PlayerRoute());
                  },
                ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _SearchHintStyle extends TextStyle {
  final BuildContext context;

  _SearchHintStyle({required this.context})
      : super(
          color: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.color
              ?.withValues(alpha: 0.7),
        );
}

class _SearchTextStyle extends TextStyle {
  final BuildContext context;

  _SearchTextStyle({required this.context})
      : super(
          color: Theme.of(context).textTheme.bodyLarge?.color,
        );
}