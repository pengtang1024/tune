import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/application/discovery_controller.dart';
import 'package:tune/features/discovery/domain/discovery_state.dart';
import 'package:tune/features/discovery/domain/discovery_section.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/player/application/list_playback.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/shared/ui/source_label.dart';
import 'package:tune/shared/ui/track_detail_sheet.dart';

/// What the buttons of the discover page do.
///
/// The actions read the controllers through the ref of the page, so the page
/// itself stays a layout: every rule of playing, queueing, dismissing and
/// clearing lives here.
class DiscoveryActions {
  final WidgetRef ref;

  const DiscoveryActions(this.ref);

  void playSong(Song song) {
    ref.read(listPlaybackProvider).play(song);
  }

  Future<void> doubleTap(Song song) async {
    // The first click already played the track; a double click only adds the
    // heart, exactly like a double click in the library. When the setting
    // makes the first click wait, the double click never plays at all.
    await ref.read(favoritesControllerProvider.notifier).mark(song.uri);
    await ref
        .read(discoveryControllerProvider.notifier)
        .forgetDismissal(song.uri);
  }

  Future<void> toggleFavorite(Song song) async {
    final wasFavorite = ref
        .read(favoritesControllerProvider)
        .contains(song.uri);
    await ref.read(favoritesControllerProvider.notifier).toggle(song.uri);
    if (!wasFavorite) {
      await ref
          .read(discoveryControllerProvider.notifier)
          .forgetDismissal(song.uri);
    }
  }

  Future<void> findMoreByArtist(BuildContext context, String artist) async {
    final result = await ref
        .read(discoveryControllerProvider.notifier)
        .findMoreByArtist(artist);
    if (!context.mounted) return;
    final message = switch (result) {
      DiscoveryOnlineResult.added => null,
      DiscoveryOnlineResult.noSources => context.loc.discoverNoOnlineSources,
      DiscoveryOnlineResult.noResults => context.loc.discoverOnlineNoResults(
        artist,
      ),
      DiscoveryOnlineResult.failed => context.loc.discoverOnlineFailed,
    };
    if (message != null) say(context, message);
  }

  void addToQueue(BuildContext context, Song song) {
    ref.read(playbackControllerProvider.notifier).addToQueue(song);
    say(context, context.loc.libraryAddedToQueue);
  }

  void playSection(DiscoverySection section) {
    final songs = [for (final track in section.tracks) track.song];
    if (songs.isEmpty) return;
    ref.read(playbackControllerProvider.notifier).playQueue(songs);
  }

  void addSection(BuildContext context, DiscoverySection section) {
    final songs = [for (final track in section.tracks) track.song];
    final added = ref
        .read(playbackControllerProvider.notifier)
        .addAllToQueue(songs);
    say(
      context,
      added == 0
          ? context.loc.discoverAlreadyQueued
          : context.loc.discoverAddedToQueue(added),
    );
  }

  Future<void> dismiss(BuildContext context, Song song) async {
    if (ref.read(favoritesControllerProvider).contains(song.uri)) return;
    await ref.read(discoveryControllerProvider.notifier).dismiss(song.uri);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.loc.discoverDismissed(song.title)),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: context.loc.discoverUndo,
            onPressed: () {
              ref
                  .read(discoveryControllerProvider.notifier)
                  .forgetDismissal(song.uri);
            },
          ),
        ),
      );
  }

  Future<void> dismissArtist(BuildContext context, Song song) async {
    final artist = song.artist.trim();
    if (artist.isEmpty) return;
    await ref.read(discoveryControllerProvider.notifier).dismissArtist(artist);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.loc.discoverDismissedArtist(artist)),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: context.loc.discoverUndo,
            onPressed: () {
              ref
                  .read(discoveryControllerProvider.notifier)
                  .forgetArtistDismissal(artist);
            },
          ),
        ),
      );
  }

  void details(
    BuildContext context,
    Song song,
    Map<String, SourceLabel> sourceLabels,
  ) {
    showTrackDetailSheet(
      context,
      song,
      source: sourceLabel(song, sourceLabels),
    );
  }

  Future<void> confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.discoverClearTitle),
        content: Text(context.loc.discoverClearMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.loc.clear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(discoveryControllerProvider.notifier).clearFeedback();
    if (!context.mounted) return;
    say(context, context.loc.discoverCleared);
  }

  void say(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}
