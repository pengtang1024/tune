import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Everything an adapter needs for one scan.
class MusicSourceScanRequest {
  final MusicSourceConfig config;
  final List<String> localPaths;
  final void Function(double progress)? onProgress;

  const MusicSourceScanRequest({
    required this.config,
    this.localPaths = const [],
    this.onProgress,
  });
}

/// Contract implemented by every music source.
///
/// Adding a new built-in source (or a future plugin) only requires a new
/// adapter and one registry entry; library scanning and the UI stay unchanged.
abstract class MusicSourceAdapter {
  String get sourceId;

  bool isConfigured(MusicSourceConfig config);

  String get configurationHint;

  /// Fields the settings dialog should render for this source.
  List<MusicSourceField> get configurationFields => const [];

  /// Remote sources are not re-scanned on every launch; local files are.
  Duration get autoScanInterval => const Duration(hours: 6);

  Duration get scanTimeout => const Duration(seconds: 45);

  Future<SourceScanResult> scan(MusicSourceScanRequest request);

  /// Rebuilds the playable address of [song] when the stored one expired.
  ///
  /// Adapters whose addresses never expire return `null`, which tells the
  /// player that no retry is possible.
  Future<Song?> refreshStream(MusicSourceConfig config, Song song) async {
    return null;
  }
}

SourceScanResult failedResult(String sourceId, Object error) {
  return SourceScanResult(
    sourceId: sourceId,
    status: SourceScanStatus.failed,
    message: describeSourceError(error),
  );
}

String describeSourceError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status != null && (status == 401 || status == 403)) {
      return AppStrings.instance.sourceErrorForbidden(status);
    }
    if (status == 429) {
      return AppStrings.instance.sourceErrorRateLimited;
    }
    if (status != null) {
      return AppStrings.instance.sourceErrorHttpStatus(status);
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return AppStrings.instance.sourceErrorTimeout;
      case DioExceptionType.connectionError:
        return AppStrings.instance.sourceErrorConnection;
      case DioExceptionType.badCertificate:
        return AppStrings.instance.sourceErrorCertificate;
      case DioExceptionType.cancel:
        return AppStrings.instance.sourceErrorCancelled;
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return AppStrings.instance.sourceErrorNetwork(
          error.message ?? error.type.name,
        );
    }
  }
  return AppStrings.instance.sourceErrorNetwork(error.toString());
}
