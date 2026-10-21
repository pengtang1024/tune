import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/meta_badge.dart';
import 'package:tune/shared/utils/readable_address.dart';

/// The addresses of a track, one chip each.
///
/// A track can be reached in four ways: through the file it lives in on this
/// machine, through the address of the source it comes from, through the
/// address of its cover and through the name the app knows it by.
///
/// An address is longer than a line, so it is not written out: the chip
/// names the address on its wide half and carries the whole address on its
/// small half. The reader reads the whole address where the pointer rests on
/// the chip, and takes it away with a click.
///
/// The address is written the way a reader writes it: the scheme of a file
/// and the escapes of a link are dropped, so the words of the path stay
/// readable.
class TrackAddresses extends StatelessWidget {
  final Song song;

  const TrackAddresses({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final file = song.localFile;
    final online = song.onlineAddress;
    final cover = song.coverAddress;
    final identity = song.identity;

    final chips = <Widget>[
      if (file != null)
        CopyChipGroup(
          icon: Icons.folder_rounded,
          label: context.loc.trackFactPath,
          address: readableAddress(file),
          hint: context.loc.trackDetailsCopyPath,
        ),
      if (online != null)
        CopyChipGroup(
          icon: Icons.link_rounded,
          label: context.loc.trackFactAddress,
          address: readableAddress(online),
          hint: context.loc.trackDetailsCopyAddress,
        ),
      if (cover != null)
        CopyChipGroup(
          icon: Icons.image_rounded,
          label: context.loc.trackFactCover,
          address: readableAddress(cover),
          hint: context.loc.trackDetailsCopyCover,
        ),
      if (identity != null)
        CopyChipGroup(
          icon: Icons.fingerprint_rounded,
          label: context.loc.trackFactIdentity,
          address: readableAddress(identity),
          hint: context.loc.trackDetailsCopyIdentity,
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: CompactTokens.space8,
      runSpacing: CompactTokens.space8,
      children: chips,
    );
  }
}
