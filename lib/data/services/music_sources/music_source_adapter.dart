import 'package:dio/dio.dart';
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
    if (status == 401 || status == 403) {
      return '访问被拒绝（HTTP $status）';
    }
    if (status == 429) {
      return '请求过于频繁（HTTP 429），请稍后再试';
    }
    if (status != null) {
      return '接口返回 HTTP $status';
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return '网络连接超时';
      case DioExceptionType.connectionError:
        return '无法连接音源服务';
      case DioExceptionType.badCertificate:
        return '证书校验失败';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return '网络请求失败：${error.message ?? error.type.name}';
    }
  }
  return error.toString();
}
