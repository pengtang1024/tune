import 'package:tune/domain/models/song.dart';

/// The language the filters and the category cards group by.
///
/// `zh-CN` and `zh_TW` are the same language for a reader; an unknown or
/// empty tag stays out of the facet rather than inventing a bucket.
String? languageKeyOf(Song song) {
  final raw = song.language?.trim().toLowerCase();
  if (raw == null || raw.isEmpty) return null;
  final head = raw.split(RegExp(r'[-_]')).first;
  return head.isEmpty ? null : head;
}

/// The normalized format of a track: `mp3`, `flac`, `ogg`, `m4a`, `wav`,
/// or `other`. The MIME type wins when it is known; the path is the fallback.
String formatOfSong(Song song) {
  final mime = song.type?.trim().toLowerCase();
  final byMime = _formatOfMime(mime);
  if (byMime != null) return byMime;
  return formatOfPath(song.localPath ?? song.uri);
}

String formatOfPath(String path) {
  final clean = Uri.tryParse(path)?.path ?? path;
  final dot = clean.lastIndexOf('.');
  if (dot < 0 || dot == clean.length - 1) return 'other';
  final extension = clean.substring(dot + 1).toLowerCase();
  return switch (extension) {
    'mp3' || 'mpga' => 'mp3',
    'flac' => 'flac',
    'ogg' || 'oga' || 'opus' => 'ogg',
    'm4a' || 'mp4' || 'aac' || 'm4b' => 'm4a',
    'wav' || 'wave' => 'wav',
    _ => 'other',
  };
}

String? _formatOfMime(String? mime) {
  if (mime == null || mime.isEmpty) return null;
  if (mime.contains('mpeg') || mime.contains('mp3')) return 'mp3';
  if (mime.contains('flac')) return 'flac';
  if (mime.contains('ogg') || mime.contains('opus')) return 'ogg';
  if (mime.contains('mp4') || mime.contains('m4a') || mime.contains('aac')) {
    return 'm4a';
  }
  if (mime.contains('wav') || mime.contains('wave')) return 'wav';
  return null;
}
