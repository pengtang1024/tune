import 'package:tune/data/services/downloads/song_download_service.dart';
import 'package:tune/domain/models/song.dart';

/// In-memory stand-in for the download store.
///
/// Tests declare which tracks are already on disk through [storedFiles] and
/// can make the next transfer fail through [failDownloads].
class FakeSongDownloadService implements SongDownloadService {
  FakeSongDownloadService({Map<String, String>? storedFiles})
    : storedFiles = {...?storedFiles};

  /// Maps a track uri to the file that already exists in the store.
  final Map<String, String> storedFiles;

  /// Uris of the tracks that were fetched during the test run.
  final List<String> downloadedUris = [];

  /// When true every transfer throws instead of completing.
  bool failDownloads = false;

  /// When false the platform has no file system and the player streams the
  /// track instead of caching it.
  @override
  bool isSupported = true;

  /// Progress values reported during the last transfer.
  final List<double> reportedProgress = [];

  /// Called for every progress value so tests can inspect the app state while
  /// the transfer is still running.
  void Function(double progress)? progressObserver;

  @override
  Future<String?> storedFileFor(Song song) async => storedFiles[song.uri];

  @override
  Future<String> download(
    Song song, {
    void Function(double progress)? onProgress,
  }) async {
    downloadedUris.add(song.uri);
    _report(0.5, onProgress);
    if (failDownloads) {
      throw StateError('download failed');
    }
    _report(1, onProgress);
    final path = '/tmp/tune-test/${song.uri.hashCode}.mp3';
    storedFiles[song.uri] = path;
    return path;
  }

  void _report(double progress, void Function(double progress)? onProgress) {
    reportedProgress.add(progress);
    onProgress?.call(progress);
    progressObserver?.call(progress);
  }

  @override
  void dispose() {}
}
