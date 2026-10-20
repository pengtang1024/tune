import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';

/// The marker that says a file in the library is the copy of a remote track.
///
/// The app fetches a remote track into the music library, so the copy sits
/// next to the music the user brought along. A marker next to the copy
/// names the track it belongs to: the scanner reads it and knows that the
/// file is not a track of its own, but the copy of a track that also comes
/// from a source.
///
/// The marker is a plain file with the canonical URI of the track in it, so
/// it can be read without the app and it survives a move of the library.
class CopyMarker {
  const CopyMarker._();

  /// The extension of the marker file.
  static const String extension = '.tune';

  /// The marker that belongs to [audioFile].
  ///
  /// The marker sits next to the audio file and is named after it, so the
  /// files of one track stay together.
  static File fileFor(File audioFile) {
    final name = path.basenameWithoutExtension(audioFile.path);
    return File(path.join(audioFile.parent.path, '$name$extension'));
  }

  /// Writes the marker of [song] next to its copy.
  ///
  /// The marker names the track the copy belongs to, so the library can put
  /// the copy and the track of the source together.
  static Future<void> write(File audioFile, Song song) async {
    final marker = fileFor(audioFile);
    await marker.parent.create(recursive: true);
    await marker.writeAsString(song.uri, flush: true);
  }

  /// The canonical URI of the track [audioFile] is a copy of.
  ///
  /// Returns `null` when the file is not a copy of a remote track.
  static Future<String?> readUri(File audioFile) async {
    try {
      final marker = fileFor(audioFile);
      if (!await marker.exists()) return null;

      final uri = (await marker.readAsString()).trim();
      if (uri.isEmpty) return null;
      return uri;
    } catch (error, stackTrace) {
      // A marker that cannot be read is no marker: the file is then read as
      // a track of its own.
      Log.error('读取副本标记失败: ${audioFile.path}\n$stackTrace');
      return null;
    }
  }
}
