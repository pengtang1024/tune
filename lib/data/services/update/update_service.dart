import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:tune/data/services/update/update_check_exception.dart';
import 'package:tune/data/services/update/update_release.dart';
import 'package:tune/data/services/update/version_manifest.dart';
import 'package:tune/data/services/update/version_manifest_source.dart';
import 'package:tune/utils/logger.dart';

/// Finds, downloads and installs a newer release of the app.
///
/// The newest version comes from `version.json`, a static file of the project
/// served by a CDN: a check no longer spends the sixty anonymous requests an
/// hour the GitHub API allows. The release page is only read as the last
/// resort, when both static addresses are unreachable.
///
/// A download writes the archive of this machine, checks its size and digest
/// against the list, and an install replaces the bundle the app runs from.
/// The app then asks the reader to restart: the running process still holds
/// the files it started with.
class UpdateService {
  /// The repository the releases live in.
  static const _repo = 'pengtang1024/tune';

  static const _apiHost = 'https://api.github.com';

  final Dio _dio;
  final VersionManifestSource _source;
  final DateTime Function() _clock;

  /// The release read the last time, when, and with which token.
  UpdateRelease? _cached;
  DateTime? _cachedAt;
  String? _cachedToken;

  /// Whether an answer is held. A project without a release caches `null`,
  /// which is an answer; nothing cached is not the same thing.
  bool _hasCached = false;

  /// How long an automatic check may reuse the last answer.
  ///
  /// Ten minutes, far below the hourly round of the scheduler
  /// (docs/update-cdn.md §4.2): the reuse only covers a second ask inside the
  /// same round, never the next round itself.
  static const _cacheFor = Duration(minutes: 10);

  UpdateService({
    Dio? dio,
    VersionManifestSource? source,
    DateTime Function()? clock,
  }) : _dio = dio ?? _defaultDio(),
       _source =
           source ??
           VersionManifestSource(dio: dio ?? _defaultManifestDio()),
       _clock = clock ?? DateTime.now;

  static Dio _defaultDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/vnd.github+json'},
    ),
  );

  /// The list is a few kilobytes; a slow CDN must not stall the check.
  static Dio _defaultManifestDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 5),
      headers: const {'Accept': 'application/json'},
    ),
  );

  /// The newest release, or `null` when the project published none.
  ///
  /// [manualToken] is the token typed in the settings; it wins over the
  /// environment. It is only sent to the GitHub API: the static addresses
  /// never see it.
  ///
  /// [forceRefresh] skips the short reuse of an answer, which is what the
  /// reader asking in the settings expects.
  ///
  /// Only an answer is cached; a failed check is not, so the next attempt
  /// reaches the sources again instead of repeating a failure for ten
  /// minutes.
  Future<UpdateRelease?> latest({
    String? manualToken,
    Map<String, String>? environment,
    bool forceRefresh = false,
  }) async {
    final token = resolveToken(
      manualToken: manualToken,
      environment: environment,
    );
    if (!forceRefresh && _hasCached && _cacheHolds(token)) return _cached;

    VersionManifest? manifest;
    try {
      manifest = await _source.read();
    } on UpdateCheckException catch (error) {
      if (error.failure == UpdateCheckFailure.manifestMismatch) {
        _forgetCache();
        rethrow;
      }
      manifest = null;
    }

    if (manifest != null) {
      final release = releaseFromManifest(manifest);
      _remember(release, token);
      return release;
    }

    // No static list: a release that predates it, or a network that reaches
    // neither address. The release page is read with the token when there is
    // one, and anonymously otherwise.
    return _fromApi(token);
  }

  /// The release page of the project, the source before the static list.
  Future<UpdateRelease?> _fromApi(String? token) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_apiHost/repos/$_repo/releases/latest',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
          // A project without a release answers with 404; that is an answer,
          // not a failure of the network.
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      final status = response.statusCode ?? 0;
      if (status == 404) {
        _remember(null, token);
        return null;
      }
      if (status == 403) {
        _forgetCache();
        throw const UpdateCheckException(
          UpdateCheckFailure.rateLimited,
          statusCode: 403,
        );
      }
      if (status == 401) {
        _forgetCache();
        throw const UpdateCheckException(
          UpdateCheckFailure.unauthorized,
          statusCode: 401,
        );
      }
      if (status < 200 || status >= 300) {
        _forgetCache();
        throw UpdateCheckException(
          UpdateCheckFailure.server,
          statusCode: status,
        );
      }
      final release = parseRelease(response.data);
      if (release == null) {
        _forgetCache();
        throw UpdateCheckException(
          UpdateCheckFailure.server,
          statusCode: status,
        );
      }
      _remember(release, token);
      return release;
    } on UpdateCheckException {
      rethrow;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 404) {
        _remember(null, token);
        return null;
      }
      _forgetCache();
      if (status == 403) {
        throw const UpdateCheckException(
          UpdateCheckFailure.rateLimited,
          statusCode: 403,
        );
      }
      if (status == 401) {
        throw const UpdateCheckException(
          UpdateCheckFailure.unauthorized,
          statusCode: 401,
        );
      }
      if (status != null) {
        throw UpdateCheckException(
          UpdateCheckFailure.server,
          statusCode: status,
        );
      }
      throw const UpdateCheckException(UpdateCheckFailure.network);
    }
  }

  /// The token the check carries: the hand-typed one wins, then the
  /// environment.
  ///
  /// Blank values count as absent, so clearing the settings field falls back
  /// to `GITHUB_TOKEN` and then `GH_TOKEN`.
  static String? resolveToken({
    String? manualToken,
    Map<String, String>? environment,
  }) {
    final manual = manualToken?.trim() ?? '';
    if (manual.isNotEmpty) return manual;
    final env = environment ?? Platform.environment;
    for (final name in const ['GITHUB_TOKEN', 'GH_TOKEN']) {
      final value = env[name]?.trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  bool _cacheHolds(String? token) {
    final cachedAt = _cachedAt;
    if (cachedAt == null) return false;
    if (token != _cachedToken) return false;
    return _clock().difference(cachedAt) < _cacheFor;
  }

  void _remember(UpdateRelease? release, String? token) {
    _cached = release;
    _cachedAt = _clock();
    _cachedToken = token;
    _hasCached = true;
  }

  void _forgetCache() {
    _cached = null;
    _cachedAt = null;
    _cachedToken = null;
    _hasCached = false;
  }

  /// The release of a list, with the archive this machine downloads.
  static UpdateRelease releaseFromManifest(
    VersionManifest manifest, {
    String? platform,
  }) {
    final asset = manifest.assetFor(platform ?? Platform.operatingSystem);
    return UpdateRelease(
      version: manifest.version,
      build: manifest.build,
      notes: manifest.notes,
      asset: asset == null
          ? null
          : UpdateAsset(
              name: _nameOf(asset.url),
              url: asset.url,
              size: asset.size,
              sha256: asset.sha256,
            ),
    );
  }

  /// Reads one release of the answer of the release page.
  static UpdateRelease? parseRelease(Map<String, dynamic>? data) {
    if (data == null) return null;

    final tag = data['tag_name']?.toString().trim() ?? '';
    final version = tag.replaceFirst(RegExp(r'^v'), '');
    if (version.isEmpty) return null;

    final rawAssets = data['assets'];
    final assets = <UpdateAsset>[];
    if (rawAssets is List) {
      for (final raw in rawAssets) {
        if (raw is! Map) continue;
        final name = raw['name']?.toString().trim() ?? '';
        final url = raw['browser_download_url']?.toString().trim() ?? '';
        if (name.isEmpty || url.isEmpty) continue;
        assets.add(
          UpdateAsset(
            name: name,
            url: url,
            size: (raw['size'] is num) ? (raw['size'] as num).toInt() : 0,
          ),
        );
      }
    }

    return UpdateRelease(
      version: version,
      notes: data['body']?.toString() ?? '',
      asset: assetFor(assets, platform: Platform.operatingSystem),
    );
  }

  /// Whether [latest] is newer than [current].
  ///
  /// The versions are compared part by part, so `1.10.0` is newer than
  /// `1.9.0` while a plain string comparison would say the opposite. A build
  /// number (`+52`) only breaks a tie between equal versions, so a rebuilt
  /// archive of the same version reaches the machines that run the older
  /// build.
  static bool isNewer(String current, String latest) {
    final left = _versionOf(current);
    final right = _versionOf(latest);
    final length = left.parts.length > right.parts.length
        ? left.parts.length
        : right.parts.length;
    for (var index = 0; index < length; index++) {
      final a = index < left.parts.length ? left.parts[index] : 0;
      final b = index < right.parts.length ? right.parts[index] : 0;
      if (b > a) return true;
      if (b < a) return false;
    }
    return right.build > left.build;
  }

  /// The archive of a release that belongs to [platform].
  ///
  /// The release names its archives after the platform they run on, so the
  /// check never downloads a Windows build on a Linux machine. Maintainer
  /// offline archives end in `-offline` and are skipped: they are not update
  /// attachments.
  static UpdateAsset? assetFor(
    List<UpdateAsset> assets, {
    required String platform,
  }) {
    final needle = platform.toLowerCase();
    for (final asset in assets) {
      final name = asset.name.toLowerCase();
      if (name.contains(needle) && !name.contains('-offline')) {
        return asset;
      }
    }
    return null;
  }

  /// Writes the file of [asset] to [destination] and checks what it got.
  ///
  /// A file that does not match the size or the digest of the list is
  /// deleted before the failure reaches the caller: an archive that is not
  /// the one the list published never reaches the install step.
  Future<void> download(
    UpdateAsset asset,
    String destination, {
    void Function(double progress)? onProgress,
  }) async {
    await _dio.download(
      asset.url,
      destination,
      onReceiveProgress: (received, total) {
        if (total <= 0) return;
        onProgress?.call((received / total).clamp(0, 1));
      },
    );
    try {
      await verifyArchive(asset, destination);
    } on UpdateCheckException {
      await _deleteFile(destination);
      rethrow;
    }
  }

  /// Whether [path] is the archive the list published.
  static Future<void> verifyArchive(UpdateAsset asset, String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw const UpdateCheckException(UpdateCheckFailure.archiveMismatch);
    }
    if (asset.size > 0 && file.lengthSync() != asset.size) {
      throw const UpdateCheckException(UpdateCheckFailure.archiveMismatch);
    }
    if (asset.sha256.isEmpty) return;
    final digest = await sha256.bind(file.openRead()).first;
    if (digest.toString().toLowerCase() != asset.sha256.toLowerCase()) {
      throw const UpdateCheckException(UpdateCheckFailure.archiveMismatch);
    }
  }

  /// Replaces the bundle the app runs from with the archive.
  ///
  /// The archive is unpacked beside the running bundle and then swapped in;
  /// the running process keeps its own copy and asks for a restart.
  Future<void> installLinux(String archive, String targetDirectory) async {
    final parent = Directory(targetDirectory).parent;
    final staging = '${parent.path}/.tune-update';
    final backup = '${parent.path}/.tune-previous';

    await _delete(staging);
    await _delete(backup);
    await Directory(staging).create(recursive: true);

    final unpacked = await Process.run('tar', ['-xzf', archive, '-C', staging]);
    if (unpacked.exitCode != 0) {
      throw ProcessException(
        'tar',
        ['-xzf', archive, '-C', staging],
        '${unpacked.stderr}',
        unpacked.exitCode,
      );
    }

    final bundle = _bundleDirectory(staging);
    if (bundle == null) {
      throw const FormatException('the update archive holds no bundle');
    }

    await Directory(targetDirectory).rename(backup);
    try {
      await bundle.rename(targetDirectory);
    } catch (error) {
      // The old bundle comes back when the new one cannot take its place.
      await Directory(backup).rename(targetDirectory);
      rethrow;
    }
    // The previous bundle is kept: a build that starts and then fails can be
    // restored by hand. The next update removes the old copy first.
    await _delete(staging);
  }

  /// Starts the new build and lets the old process end.
  Future<void> restart() async {
    final executable = Platform.resolvedExecutable;
    await Process.start(executable, const [], mode: ProcessStartMode.detached);
    exit(0);
  }

  /// The bundle inside the unpacked archive.
  ///
  /// A release packs the bundle itself, but a folder has been added around
  /// it more than once; both shapes are read.
  static Directory? _bundleDirectory(String staging) {
    final root = Directory(staging);
    final direct = Directory('${root.path}/lib');
    if (direct.existsSync()) return root;

    for (final entity in root.listSync()) {
      if (entity is! Directory) continue;
      if (Directory('${entity.path}/lib').existsSync()) return entity;
    }
    return null;
  }

  static String _nameOf(String url) {
    final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    return segments.isEmpty ? '' : segments.last;
  }

  static Future<void> _deleteFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) return;
    try {
      await file.delete();
    } catch (error) {
      Log.error('删除校验失败的更新包失败: $error');
    }
  }

  static Future<void> _delete(String path) async {
    final directory = Directory(path);
    if (directory.existsSync()) {
      try {
        await directory.delete(recursive: true);
      } catch (error) {
        Log.error('清理更新目录失败: $error');
      }
    }
  }

  /// The numbers of a version and its build number.
  static ({List<int> parts, int build}) _versionOf(String version) {
    final segments = version
        .trim()
        .replaceFirst(RegExp(r'^v'), '')
        .split('+');
    final build = segments.length > 1
        ? int.tryParse(RegExp(r'^\d+').stringMatch(segments[1]) ?? '') ?? 0
        : 0;
    return (
      parts: [
        for (final part in segments.first.split('.'))
          int.tryParse(RegExp(r'^\d+').stringMatch(part) ?? '') ?? 0,
      ],
      build: build,
    );
  }
}
