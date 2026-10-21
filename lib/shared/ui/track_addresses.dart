import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/track_detail_row.dart';
import 'package:tune/shared/utils/readable_address.dart';

/// The addresses of a track, one row each.
///
/// A track can be reached in four ways: through the file it lives in on this
/// machine, through the address of the source it comes from, through the
/// address of its cover and through the name the app knows it by. Each of
/// them gets a row of its own.
///
/// An address is longer than a line, so it is not written out in the line:
/// the row names the address and a chip carries it, and the reader reads the
/// whole address when the pointer rests on the chip.
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
        value: readableAddress(file),
        machine: true,
        copyHint: context.loc.trackDetailsCopyPath,
        inChip: true,
      ),
    if (online != null)
      TrackDetailRow(
        label: context.loc.trackFactAddress,
        icon: Icons.link_rounded,
        value: readableAddress(online),
        machine: true,
        copyHint: context.loc.trackDetailsCopyAddress,
        inChip: true,
      ),
    if (cover != null)
      TrackDetailRow(
        label: context.loc.trackFactCover,
        icon: Icons.image_rounded,
        value: readableAddress(cover),
        machine: true,
        copyHint: context.loc.trackDetailsCopyCover,
        inChip: true,
      ),
    if (identity != null)
      TrackDetailRow(
        label: context.loc.trackFactIdentity,
        icon: Icons.fingerprint_rounded,
        value: readableAddress(identity),
        machine: true,
        copyHint: context.loc.trackDetailsCopyIdentity,
        inChip: true,
      ),
  ];
}
