import 'package:tune/data/services/impl/saf_method_channel.dart';
import 'package:tune/data/services/library/saf_tree_store.dart';
import 'package:tune/domain/models/song.dart';

/// Decides where a sheet (lyrics, contrasts) of a track belongs.
///
/// A desktop writes beside the audio file with [LibraryPaths]. A track that
/// was read out of a SAF tree has no path the app may write to: the only
/// place is a document under the same tree, and only while the system still
/// holds the write permission of that tree (`docs/android.md` §5.3).
///
/// The writer answers the landing question only. Writing the sheet through
/// `DocumentsContract` is the next step (S2); until then the lyrics pipeline
/// stays off on Android.
class SafDocumentWriter {
  SafDocumentWriter({
    required SafTreeStore tree,
    SafMethodChannel channel = const SafMethodChannel(),
  }) : _tree = tree,
       _channel = channel;

  final SafTreeStore _tree;
  final SafMethodChannel _channel;

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
}
