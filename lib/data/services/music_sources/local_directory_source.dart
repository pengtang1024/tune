import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Wraps the existing recursive file scanner as the built-in local source.
class LocalDirectorySourceAdapter extends MusicSourceAdapter {
  final CrossPlatformMusicScanner _scanner;

  LocalDirectorySourceAdapter(this._scanner);

  @override
  String get sourceId => 'local';

  @override
  bool isConfigured(MusicSourceConfig config) => true;

  @override
  String get configurationHint => AppStrings.instance.localSourceHint;

  @override
  List<MusicSourceField> get configurationFields => const [];

  @override
  Duration get autoScanInterval => Duration.zero;

  @override
  Duration get scanTimeout => const Duration(minutes: 15);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final paths = request.localPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (paths.isEmpty) {
      return SourceScanResult(
        sourceId: sourceId,
        status: SourceScanStatus.skipped,
        message: AppStrings.instance.localSourceNotConfigured,
      );
    }

    try {
      final songs = await _scanner.scanMusicInDirectoriesWithProgress(
        paths,
        (progress) => request.onProgress?.call(progress.clamp(0.0, 1.0)),
      );
      return SourceScanResult(
        sourceId: sourceId,
        status: SourceScanStatus.success,
        songs: songs,
      );
    } catch (error) {
      return failedResult(sourceId, error);
    }
  }
}
