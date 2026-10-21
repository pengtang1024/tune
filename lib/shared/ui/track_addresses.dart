import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/meta_badge.dart';
import 'package:tune/shared/utils/readable_address.dart';

/// The addresses of a track, one row each.
///
/// A track can be reached in four ways: through the file it lives in on this
/// machine, through the address of the source it comes from, through the
/// address of its cover and through the name the app knows it by.
///
/// An address is longer than a line, so it is not written out: the row names
/// the address and a chip carries it. The reader reads the whole address
/// where the pointer rests on the chip, and takes it away with a click.
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

    final rows = <Widget>[
      if (file != null)
        _Address(
          icon: Icons.folder_rounded,
          label: context.loc.trackFactPath,
          address: readableAddress(file),
          copyHint: context.loc.trackDetailsCopyPath,
        ),
      if (online != null)
        _Address(
          icon: Icons.link_rounded,
          label: context.loc.trackFactAddress,
          address: readableAddress(online),
          copyHint: context.loc.trackDetailsCopyAddress,
        ),
      if (cover != null)
        _Address(
          icon: Icons.image_rounded,
          label: context.loc.trackFactCover,
          address: readableAddress(cover),
          copyHint: context.loc.trackDetailsCopyCover,
        ),
      if (identity != null)
        _Address(
          icon: Icons.fingerprint_rounded,
          label: context.loc.trackFactIdentity,
          address: readableAddress(identity),
          copyHint: context.loc.trackDetailsCopyIdentity,
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: CompactTokens.space12,
      runSpacing: CompactTokens.space8,
      children: rows,
    );
  }
}

/// One address: the name of it and the chip that carries it.
class _Address extends StatelessWidget {
  final IconData icon;
  final String label;
  final String address;
  final String copyHint;

  const _Address({
    required this.icon,
    required this.label,
    required this.address,
    required this.copyHint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: CompactTokens.icon14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: CompactTokens.space4),
        Text(
          label,
          style: CompactTypography.mono(
            theme.colorScheme.onSurfaceVariant,
            size: CompactTypeScale.mark,
            weight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: CompactTokens.space6),
        CopyChip(address: address, hint: copyHint),
      ],
    );
  }
}
