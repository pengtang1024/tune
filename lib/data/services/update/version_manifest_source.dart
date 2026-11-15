import 'package:dio/dio.dart';
import 'package:tune/data/services/update/update_check_exception.dart';
import 'package:tune/data/services/update/version_manifest.dart';

/// Reads `version.json` from the addresses that publish it.
///
/// The repository is public, so the CDN and the raw host both serve the file
/// without a token and without the request limit of the GitHub API. Both are
/// read every time: when both answer they must agree, because the list
/// decides what the app downloads and installs (docs/update-cdn.md §7).
class VersionManifestSource {
  VersionManifestSource({required Dio dio, List<String>? urls})
    : _dio = dio,
      urls = urls ?? defaultUrls;

  /// CDN first; the raw host is the second address and the cross-check.
  ///
  /// The branch, not `@latest`: jsDelivr refuses a package of this repository
  /// (`Package size exceeded the configured limit of 50 MB`), while the
  /// branch address still serves single files.
  static const List<String> defaultUrls = [
    'https://cdn.jsdelivr.net/gh/pengtang1024/tune@master/version.json',
    'https://raw.githubusercontent.com/pengtang1024/tune/master/version.json',
  ];

  final Dio _dio;
  final List<String> urls;

  /// The validator of each address and the list it belongs to, so a repeated
  /// read costs one conditional request instead of the whole file.
  final Map<String, String> _etags = {};
  final Map<String, VersionManifest> _seen = {};

  /// The newest list, or `null` when no address publishes one.
  ///
  /// A failing address is skipped while another answers; two addresses that
  /// disagree are not trusted at all.
  Future<VersionManifest?> read() async {
    VersionManifest? chosen;
    UpdateCheckException? failure;

    for (final url in urls) {
      try {
        final manifest = await _read(url);
        if (manifest == null) continue;
        if (chosen == null) {
          chosen = manifest;
          continue;
        }
        if (!chosen.sameAs(manifest)) {
          throw const UpdateCheckException(UpdateCheckFailure.manifestMismatch);
        }
      } on UpdateCheckException catch (error) {
        if (error.failure == UpdateCheckFailure.manifestMismatch) rethrow;
        failure ??= error;
      }
    }

    if (chosen != null) return chosen;
    if (failure != null) throw failure;
    return null;
  }

  Future<VersionManifest?> _read(String url) async {
    final etag = _seen[url] == null ? null : _etags[url];
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'If-None-Match': ?etag},
          validateStatus: (status) =>
              status == 304 || (status != null && status < 500),
        ),
      );
      final status = response.statusCode ?? 0;
      // The list did not change since the last read; the parsed copy stands.
      if (status == 304) return _seen[url];
      // The address does not publish a list yet, or never did.
      if (status == 404) return null;
      if (status < 200 || status >= 300) {
        throw UpdateCheckException(
          UpdateCheckFailure.server,
          statusCode: status,
        );
      }
      final manifest = VersionManifest.parse(response.data ?? '');
      if (manifest == null) {
        throw UpdateCheckException(
          UpdateCheckFailure.server,
          statusCode: status,
        );
      }
      final validator = response.headers.value('etag');
      if (validator != null) _etags[url] = validator;
      _seen[url] = manifest;
      return manifest;
    } on UpdateCheckException {
      rethrow;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status != null) {
        throw UpdateCheckException(
          UpdateCheckFailure.server,
          statusCode: status,
        );
      }
      throw const UpdateCheckException(UpdateCheckFailure.network);
    }
  }
}
