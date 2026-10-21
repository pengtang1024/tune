import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/track_detail_row.dart';

/// The addresses of a track, one row each.
///
/// A track can be reached in four ways: through the file it lives in on this
/// machine, through the address of the source it comes from, through the
/// address of its cover and through the name the app knows it by. No icon
/// can stand for any of them, so they are written out and can be copied.
///
/// The rows share the column of the names with the facts of the track, so the
/// addresses do not look like a table of their own.
List<TrackDetailRow> trackAddressRows(BuildContext context, Song song) {
  final file = song.localFile;
  final online = song.onlineAddress;
  final cover = song.coverAddress;
  final identity = song.identity;

  return [
    if (file != null)
      TrackDetailRow(
        label: context.loc.trackFactPath,
        icon: Icons.folder_rounded,
        value: file,
        machine: true,
        copyHint: context.loc.trackDetailsCopyPath,
      ),
    if (online != null)
      TrackDetailRow(
        label: context.loc.trackFactAddress,
        icon: Icons.link_rounded,
        value: online,
        machine: true,
        copyHint: context.loc.trackDetailsCopyAddress,
      ),
    if (cover != null)
      TrackDetailRow(
        label: context.loc.trackFactCover,
        icon: Icons.image_rounded,
        value: cover,
        machine: true,
        copyHint: context.loc.trackDetailsCopyCover,
      ),
    if (identity != null)
      TrackDetailRow(
        label: context.loc.trackFactIdentity,
        icon: Icons.fingerprint_rounded,
        value: identity,
        machine: true,
        copyHint: context.loc.trackDetailsCopyIdentity,
      ),
  ];
}
