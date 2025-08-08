import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/core/utils/localization_delegate.dart';
import 'package:tune/presentation/widgets/bottom_player_bar.dart';
import 'package:tune/presentation/widgets/song_list.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/domain/usecases/get_all_songs.dart';
import 'package:tune/core/di/dependency_injection.dart';
import 'package:tune/presentation/bloc/player/player_bloc.dart';
import 'package:tune/presentation/bloc/player/player_event.dart';
import 'package:auto_route/auto_route.dart';
import 'package:tune/core/routes/app_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late GetAllSongs _getAllSongs;
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getAllSongs = DependencyInjection.get<GetAllSongs>();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await _getAllSongs();
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // 处理错误
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load songs: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              context.pushRoute(const SearchRoute());
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.pushRoute(const SettingsRoute());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SongList(
              songs: _songs,
              onSongTap: (song) {
                context.read<PlayerBloc>().add(PlaySongEvent(song.id));
                context.pushRoute(const PlayerRoute());
              },
            ),
      bottomNavigationBar: const BottomPlayerBar(),
    );
  }
}