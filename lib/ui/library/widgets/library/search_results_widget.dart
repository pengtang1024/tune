import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/ui/player/providers/player_providers.dart';

class SearchResultsWidget extends ConsumerWidget {
  final LibraryState state;
  final AppLocalizations localizations;
  final Function(Song) onPlaySong;

  const SearchResultsWidget({
    super.key,
    required this.state,
    required this.localizations,
    required this.onPlaySong,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage?.isNotEmpty ?? false) {
      return Center(
        child: Text(
          '${localizations.search_error}: ${_getLocalizedErrorMessage(state.errorMessage)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      ),
    );
  }

  String _getLocalizedErrorMessage(String? errorMessage) {
    if (errorMessage == null || errorMessage.isEmpty) {
      return localizations.error;
    }

    // 常见错误消息的本地化映射
    if (errorMessage.contains('network')) {
      return localizations.network_error;
    } else if (errorMessage.contains('permission')) {
      return localizations.permission_denied;
    } else if (errorMessage.contains('invalid')) {
      return localizations.invalid_input;
    }

    // 默认返回原始错误消息
    return errorMessage;
    }

    final songs = state.searchResults;
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.search_no_results,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return _buildSongListItem(context, ref, song);
      },
    );
  }

  Widget _buildSongListItem(BuildContext context, WidgetRef ref, Song song) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.music_note, size: 30),
        ),
        title: Text(
          song.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${song.artist} - ${song.album}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatDuration(song.duration),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        onTap: () {
          onPlaySong(song);
        },
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}