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
/// Adding a new type of source only requires a new adapter and one registry
/// entry; library scanning and the UI stay unchanged.
abstract class MusicSourceAdapter {
  /// The type of the source: the key the registry looks the adapter up by.
  ///
  /// The type says how the tracks are fetched. It is not the id of an
  /// instance: several instances may share one type.
  String get sourceType;

  bool isConfigured(MusicSourceConfig config);

  String get configurationHint;

  /// The browse streams this type offers.
  ///
  /// A browse stream is a list the platform serves by itself: the tracks that
  /// were published last, the charts, the daily picks. A type that offers
  /// one is ready as it is — the app does not pick a taste for the reader.
  ///
  /// A type that offers none needs a keyword to search with. The first
  /// stream of the list is the one the type prefers.
  List<String> get browseModes => const [];

  /// The browse stream an instance of this type pulls.
  ///
  /// The instance names one of [browseModes]; a name the type does not offer
  /// falls back to the stream the type prefers.
  String browseModeOf(MusicSourceConfig config) {
    final chosen = config.setting('browse');
    if (chosen != null && browseModes.contains(chosen)) return chosen;
    return browseModes.first;
  }

  /// Whether the source belongs to the top of the list.
  ///
  /// The sources that ask nothing of the reader are the ones met first; the
  /// ones that need a key or a decision wait in a folded section below them.
  /// The type says where it belongs, so the interface never names a source.
  bool get featured => false;

  /// Fields the settings dialog should render for this source.
  List<MusicSourceField> get configurationFields => const [];

  /// How many tracks one scan of this source fetches.
  ///
  /// Sources that do not count their tracks return `null`. The setting the
  /// user sees and the scan that runs read this one number, so the two never
  /// drift apart.
  MusicSourceLimit? get scanLimit => null;

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

  /// Fetches the lyrics of [song] on demand.
  ///
  /// Sources without lyrics return `null`; the player then shows that the
  /// track has no lyrics.
  Future<String?> fetchLyrics(MusicSourceConfig config, Song song) async {
    return null;
  }
}

/// Whether the address is one the app may ask.
///
/// Only http(s) is asked: a file address or another protocol is not a
/// request the app makes. The reader writes the address, so the check is
/// here, in one place, for every type that asks an address of its own.
bool isHttpAddress(String address) {
  final lower = address.trim().toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

/// A failure a source reports in the language of the interface.
///
/// The message is already written for the reader, so the failure is shown as
/// it is instead of being wrapped in a frame of another language.
class MusicSourceFailure implements Exception {
  const MusicSourceFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A failure of one source instance.
///
/// The id is the id of the instance the failure belongs to, not the type.
SourceScanResult failedResult(String sourceId, Object error) {
  return SourceScanResult(
    sourceId: sourceId,
    status: SourceScanStatus.failed,
    message: describeSourceError(error),
  );
}

String describeSourceError(Object error) {
  if (error is MusicSourceFailure) return error.message;
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
