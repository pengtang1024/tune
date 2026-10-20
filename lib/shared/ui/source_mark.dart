import 'package:flutter/material.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/shared/ui/track_fact.dart';

/// The icon that stands for a source.
///
/// Every built-in source has an icon of its own, so a reader tells the
/// services apart without reading a word. A source the user brought along
/// has no icon of its own and falls back to the one of its kind.
///
/// The icon is a presentation detail, so it lives here and not in the
/// catalogue: the catalogue names the sources, this file draws them. The
/// colour of the mark belongs to the kind of the source, the shape belongs
/// to the source itself.
IconData sourceIconOf(String type, MusicSourceKind kind) {
  return switch (type) {
    'local' => Icons.library_music_rounded,
    'openverse' => Icons.public_rounded,
    'jamendo' => Icons.music_note_rounded,
    'internet_archive' => Icons.archive_rounded,
    'netease' => Icons.cloud_queue_rounded,
    'ccmixter' => Icons.graphic_eq_rounded,
    'itunes' => Icons.storefront_rounded,
    'podcast_rss' => Icons.rss_feed_rounded,
    'subsonic' => Icons.dns_rounded,
    'audius' => Icons.headset_mic_rounded,
    'radio' => Icons.radio_rounded,
    'wikimedia' => Icons.perm_media_rounded,
    'jellyfin' => Icons.tv_rounded,
    'direct_url' => Icons.link_rounded,
    _ => switch (kind) {
      MusicSourceKind.localDirectory => Icons.folder_rounded,
      MusicSourceKind.openCatalog => Icons.public_rounded,
      MusicSourceKind.openApi => Icons.api_rounded,
      MusicSourceKind.custom => Icons.extension_rounded,
    },
  };
}

/// The colour of a source.
///
/// The colour belongs to the kind of the source, not to the source itself:
/// every public catalogue is painted the same way, every service the user
/// brought along another way.
FactTone sourceToneOf(MusicSourceKind kind) {
  return switch (kind) {
    MusicSourceKind.localDirectory => FactTone.neutral,
    MusicSourceKind.openCatalog => FactTone.primary,
    MusicSourceKind.openApi => FactTone.secondary,
    MusicSourceKind.custom => FactTone.tertiary,
  };
}
