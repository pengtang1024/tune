import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tune/data/services/impl/saf_method_channel.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/library/saf_tree_store.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/file_name.dart';
import 'package:tune/utils/logger.dart';

/// Decides where a sheet (lyrics, contrasts) of a track belongs.
///
/// A desktop writes beside the audio file with [LibraryPaths]. A track that
/// was read out of a SAF tree has no path the app may write to: the only
/// place is a document under the same tree, and only while the system still
/// holds the write permission of that tree (`docs/android.md` §5.3).
///
/// The sheet is written through `DocumentsContract` on the native side; no
/// `File` is ever put under a tree, because a tree URI is not a path.
class SafDocumentWriter {
  SafDocumentWriter({
    required SafTreeStore tree,
    SafMethodChannel channel = const SafMethodChannel(),
  }) : _tree = tree,
       _channel = channel;

  final SafTreeStore _tree;
  final SafMethodChannel _channel;

  /// The name the machine sheet of [song] carries inside the tree.
  ///
  /// The track is named after its tags, not after a path: the tree has no
  /// path the app may read. `unknown` stands in for a track with no title,
  /// the same fallback the file system uses.
  static String smartSheetName(Song song) =>
      '${safeFileName(song.title)}.smart.lrc';

  /// Whether [song] is a document inside the tree the reader picked.
  bool owns(Song song) {
    final tree = _tree.treeUri;
    if (tree == null) return false;
    return song.uri.startsWith('$tree/document/');
  }

  /// Whether the sheet of [song] can be written next to it.
  ///
  /// False for a track of MediaStore (its `content://` address is not under
  /// the tree) and for a tree whose write permission was taken back.
  Future<bool> canWrite(Song song) async {
    final tree = _tree.treeUri;
    if (tree == null || !owns(song)) return false;
    return _channel.canWrite(tree);
  }

  /// Writes the machine sheet of [song] into the folder that holds it.
  ///
  /// The sheet replaces an older one of the same name, so a second run
  /// leaves a single sheet behind. A tree that lost its write permission is
  /// reported as [SheetWriteException.permissionLost]; nothing is written.
  Future<void> writeSmartLyrics(Song song, String lyrics) async {
    final tree = _tree.treeUri;
    if (tree == null || !owns(song)) {
      throw const SheetWriteException('the track is not inside the picked tree');
    }
    if (!await _channel.canWrite(tree)) {
      throw const SheetWriteException(
        'the write permission of the tree was taken back',
        permissionLost: true,
      );
    }
    try {
      await _channel.writeSheet(
        treeUri: tree,
        songUri: song.uri,
        name: smartSheetName(song),
        content: lyrics,
      );
    } on PlatformException catch (error) {
      throw SheetWriteException(
        'SAF sheet write failed: ${error.code} ${error.message}',
        permissionLost: error.code == 'permission_lost',
      );
    }
  }

  /// Reads the machine sheet of [song] back out of the tree.
  ///
  /// The panel shows the words the run wrote; a tree has no path the reader
  /// can open, so the sheet is found by its name under the track's folder.
  /// `null` when it is not there or the provider refuses the read — a track
  /// without words is not a failure of its own.
  Future<String?> readSmartLyrics(Song song) async {
    final tree = _tree.treeUri;
    if (tree == null || !owns(song)) return null;
    try {
      return await _channel.readSheet(
        treeUri: tree,
        songUri: song.uri,
        name: smartSheetName(song),
      );
    } on PlatformException catch (error, stackTrace) {
      Log.error('SAF 词稿读回失败: ${error.code} ${error.message}', stackTrace);
      return null;
    }
  }

  /// Copies the audio of [song] into a folder the app may read.
  ///
  /// The engines read a file, and a tree only speaks `content://`. The copy
  /// goes into the private cache; the caller owns its folder and deletes it
  /// when the run is done. `null` for a track outside the tree, or when the
  /// provider refuses the read — the run then reports `noAudio` as before.
  Future<File?> copyAudio(Song song) async {
    final tree = _tree.treeUri;
    if (tree == null || !owns(song)) return null;
    try {
      final copied = await _channel.copyAudio(song.uri);
      return copied == null ? null : File(copied);
    } on PlatformException catch (error, stackTrace) {
      Log.error('SAF 音频复制失败: ${error.code} ${error.message}', stackTrace);
      return null;
    }
  }
}
