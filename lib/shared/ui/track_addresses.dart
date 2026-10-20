import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/track_address_row.dart';

/// The addresses of a track, one row each.
///
/// A track can be reached in four ways: through the file it lives in on this
/// machine, through the address of the source it comes from, through the
/// address of its cover and through the name the app knows it by. No icon
/// can stand for any of them, so they are written out and can be copied.
class TrackAddresses extends StatelessWidget {
  final Song song;

  const TrackAddresses({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final file = song.localFile;
    final online = song.onlineAddress;
    final cover = song.coverAddress;
    final identity = song.identity;

    final rows = <Widget>[
      if (file != null)
        TrackAddressRow(
          address: file,
          label: context.loc.trackFactPath,
          copyHint: context.loc.trackDetailsCopyPath,
        ),
      if (online != null)
        TrackAddressRow(
          address: online,
          label: context.loc.trackFactAddress,
          copyHint: context.loc.trackDetailsCopyAddress,
        ),
      if (cover != null)
        TrackAddressRow(
          address: cover,
          label: context.loc.trackFactCover,
          copyHint: context.loc.trackDetailsCopyCover,
        ),
      if (identity != null)
        TrackAddressRow(
          address: identity,
          label: context.loc.trackFactIdentity,
          copyHint: context.loc.trackDetailsCopyIdentity,
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0) const SizedBox(height: 14),
          rows[index],
        ],
      ],
    );
  }
}
