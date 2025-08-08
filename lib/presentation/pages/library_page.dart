import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/core/utils/localization_delegate.dart';
import 'package:tune/domain/usecases/get_all_songs.dart';
import 'package:tune/presentation/widgets/song_list.dart';
import 'package:tune/core/di/dependency_injection.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/presentation/bloc/player/player_bloc.dart';
import 'package:tune/presentation/bloc/player/player_event.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load library: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.libraryTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSongs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SongList(
              songs: _songs,
              onSongTap: (song) {
                context.read<PlayerBloc>().add(PlaySongEvent(song.id));
              },
            ),
    );
  }
}