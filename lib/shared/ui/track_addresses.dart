import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/desktop/open_external.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/meta_badge.dart';
import 'package:tune/shared/ui/track_fact.dart';
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
/// the chip, and acts on it with a click.
///
/// The action follows the kind of address: a file on this machine is opened
/// by the desktop, an address of a source is taken away to the clipboard.
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

    // The address is written the way a reader writes it, and the reader takes
    // away the same words they read.
    final fileAddress = file == null ? null : readableAddress(file);
    final onlineAddress = online == null ? null : readableAddress(online);
    final coverAddress = cover == null ? null : readableAddress(cover);
    final identityAddress = identity == null ? null : readableAddress(identity);

    // The colour of a chip says which class it belongs to, so every address
    // wears the colour of the kind of thing it points at: the file on this
    // machine is as quiet as the local storage, the address of the source is
    // as green as the remote storage, and the name the app knows the track
    // by is a thing of its own, neither a file nor an address.
    final chips = <Widget>[
      if (fileAddress != null)
        ChipGroup(
          icon: Icons.folder_rounded,
          label: context.loc.trackFactPath,
          value: fileAddress,
          actionIcon: Icons.open_in_new_rounded,
          actionHint: context.loc.trackDetailsOpenPath,
          tone: FactTone.neutral,
          onAction: () => _open(context, fileAddress),
        ),
      if (onlineAddress != null)
        ChipGroup(
          icon: Icons.link_rounded,
          label: context.loc.trackFactAddress,
          value: onlineAddress,
          actionIcon: Icons.copy_rounded,
          actionHint: context.loc.trackDetailsCopyAddress,
          tone: FactTone.secondary,
          onAction: () => _copy(context, onlineAddress),
        ),
      if (coverAddress != null)
        ChipGroup(
          icon: Icons.image_rounded,
          label: context.loc.trackFactCover,
          value: coverAddress,
          actionIcon: Icons.copy_rounded,
          actionHint: context.loc.trackDetailsCopyCover,
          tone: FactTone.secondary,
          onAction: () => _copy(context, coverAddress),
        ),
      if (identityAddress != null)
        ChipGroup(
          icon: Icons.fingerprint_rounded,
          label: context.loc.trackFactIdentity,
          value: identityAddress,
          actionIcon: Icons.copy_rounded,
          actionHint: context.loc.trackDetailsCopyIdentity,
          tone: FactTone.tertiary,
          onAction: () => _copy(context, identityAddress),
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: CompactTokens.space8,
      runSpacing: CompactTokens.space8,
      children: chips,
    );
  }

  /// Takes the address away to the clipboard and says that it is there.
  Future<void> _copy(BuildContext context, String address) async {
    await Clipboard.setData(ClipboardData(text: address));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.loc.trackDetailsCopied),
          duration: const Duration(milliseconds: 1500),
        ),
      );
  }

  /// Hands the file to the desktop, which opens it the way the reader
  /// expects: with the program they chose for that kind of file.
  ///
  /// The desktop shows the file itself, so nothing is said here; only a
  /// failure is worth a word.
  Future<void> _open(BuildContext context, String path) async {
    final opened = await openExternal(path);
    if (opened || !context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.loc.trackDetailsOpenFailed),
          duration: const Duration(milliseconds: 1500),
        ),
      );
  }
}
