import 'package:flutter/services.dart';

/// The folder the reader picked, as the system answered it.
class SafPickedDirectory {
  const SafPickedDirectory({
    required this.uri,
    required this.name,
    required this.writable,
  });

  /// The tree URI the permission was taken for.
  final String uri;

  /// The label of the folder, without the document id around it.
  final String name;

  /// Whether the system granted write access to the tree.
  final bool writable;
}

/// The sheet the native side wrote into a tree.
class SafWrittenSheet {
  const SafWrittenSheet({required this.uri, required this.replaced});

  /// The document URI of the sheet that now holds the words.
  final String uri;

  /// Whether an older sheet of the same name was overwritten.
  final bool replaced;
}

/// The SAF half of the Android platform channel (`cn.iouf.tune/saf`).
///
/// A tree is not a path: its documents are addressed by `content://` URIs
/// that only the native side can resolve. The channel is the only door to
/// them; the native half lives in `MainActivity`.
class SafMethodChannel {
  const SafMethodChannel();

  static const MethodChannel channel = MethodChannel('cn.iouf.tune/saf');

  /// Opens the system directory picker and keeps the answer for good.
  ///
  /// A reader who backs out gives `null`. The permission is taken as a
  /// persistable one by the native side, so the tree keeps answering after
  /// a restart.
  Future<SafPickedDirectory?> pickDirectory() async {
    final row = await channel.invokeMapMethod<Object?, Object?>(
      'pickDirectory',
    );
    if (row == null) return null;
    final uri = row['uri'] as String?;
    if (uri == null || uri.isEmpty) return null;
    return SafPickedDirectory(
      uri: uri,
      name: row['name'] as String? ?? '',
      writable: row['writable'] == true,
    );
  }

  /// One page of the audio files under [uri].
  ///
  /// The tree is walked again per call, so the reader pages through a large
  /// folder instead of holding the whole tree in memory at once.
  Future<List<Map<Object?, Object?>>> listTreePage(
    String uri, {
    required int offset,
    required int limit,
  }) async {
    final rows = await channel.invokeListMethod<Map<Object?, Object?>>(
      'listTree',
      {'uri': uri, 'offset': offset, 'limit': limit},
    );
    return rows ?? const [];
  }

  /// Whether the system still holds a write permission for [uri].
  Future<bool> canWrite(String uri) async {
    final value = await channel.invokeMethod<bool>('canWrite', {'uri': uri});
    return value ?? false;
  }

  /// Writes [content] as [name] into the folder of [songUri].
  ///
  /// The native side replaces a sheet of the same name, so a second run
  /// leaves one sheet in the folder. A tree that lost its permission answers
  /// with a `permission_lost` error, which the caller turns into a report.
  Future<SafWrittenSheet> writeSheet({
    required String treeUri,
    required String songUri,
    required String name,
    required String content,
  }) async {
    final row = await channel.invokeMapMethod<Object?, Object?>('writeSheet', {
      'treeUri': treeUri,
      'songUri': songUri,
      'name': name,
      'content': content,
    });
    return SafWrittenSheet(
      uri: row?['uri'] as String? ?? '',
      replaced: row?['replaced'] == true,
    );
  }

  /// Reads the sheet [name] out of the folder that holds [songUri].
  ///
  /// `null` when the folder has no such sheet: a track without words is not
  /// an error. The content is the UTF-8 text the native side read.
  Future<String?> readSheet({
    required String treeUri,
    required String songUri,
    required String name,
  }) => channel.invokeMethod<String>('readSheet', {
    'treeUri': treeUri,
    'songUri': songUri,
    'name': name,
  });

  /// Copies the audio of [songUri] into a private folder of the app.
  ///
  /// The engines read files, and a tree only speaks `content://`: the native
  /// side writes one copy and answers its path. The caller owns the folder
  /// that holds the copy and deletes it when the run is done
  /// (`docs/android.md` §5.3).
  Future<String?> copyAudio(String songUri) async {
    final row = await channel.invokeMapMethod<Object?, Object?>('copyAudio', {
      'songUri': songUri,
    });
    final copied = row?['path'] as String?;
    return copied == null || copied.isEmpty ? null : copied;
  }
}
