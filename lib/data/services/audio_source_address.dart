import 'dart:io' show File;

import 'package:tune/domain/models/song.dart';

/// The address the audio backend loads for [song].
///
/// A stored copy is a file on the disk, and the address of the track itself
/// is a network address for a remote track and a path for a local one.
///
/// A path always becomes a `file` address. The path is made absolute first,
/// so a path that carries a colon of its own is still read from the disk
/// instead of turning into an address of a foreign scheme.
Uri audioSourceAddress(Song song, String address, {required bool fromStore}) {
  if (!fromStore && song.isRemote) {
    return Uri.parse(address);
  }
  // A MediaStore track is addressed by its content:// URI: the backend can
  // open it as it is, and turning it into a file path would lose the track.
  final parsed = Uri.tryParse(address);
  if (parsed != null && parsed.scheme == 'content') {
    return parsed;
  }
  return Uri.file(File(address).absolute.path);
}
